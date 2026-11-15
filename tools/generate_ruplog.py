#!/usr/bin/env python3
"""Export actual symbolic certificates and optionally cross-check native tools.

The MoonBit test adapter is numeric/JSON-only; it does not construct proofs.
All certificates come from ruplog's pure kernel and pass its checker first.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
from urllib.request import urlopen


ROOT = Path(__file__).resolve().parent.parent
LRAT_REV = "b30f400f4ee5c32b77ee566a7c006081b521534f"
DRAT_REV = "2e3b2dc0ecf938addbd779d42877b6ed69d9a985"


def run(command: list[str], *, cwd: Path = ROOT, env=None, cpu=None, timeout=120):
    if cpu is not None:
        command = ["taskset", "-c", str(cpu), *command]
    return subprocess.run(command, cwd=cwd, env=env, text=True,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          timeout=timeout)


def required(command: list[str], **kwargs):
    result = run(command, **kwargs)
    if result.returncode:
        raise RuntimeError(f"command failed: {command}\n{result.stdout}\n{result.stderr}")
    return result


def checker_tools(args):
    cache = ROOT / ".tools" / "ruplog-checkers"
    cache.mkdir(parents=True, exist_ok=True)
    if args.lrat_trim:
        lrat = args.lrat_trim.resolve()
    else:
        repo = cache / f"lrat-trim-{LRAT_REV[:12]}"
        if not repo.exists():
            repo.mkdir()
            required(["git", "init", "-q"], cwd=repo)
            required(["git", "remote", "add", "origin", "https://github.com/arminbiere/lrat-trim.git"], cwd=repo)
            required(["git", "fetch", "--quiet", "--depth", "1", "origin", LRAT_REV], cwd=repo)
            required(["git", "checkout", "--quiet", "--detach", "FETCH_HEAD"], cwd=repo)
        actual = required(["git", "rev-parse", "HEAD"], cwd=repo).stdout.strip()
        if actual != LRAT_REV:
            raise RuntimeError(f"checker cache has unexpected revision: {actual}")
        lrat = repo / "lrat-trim"
        if not lrat.exists():
            required(["./configure"], cwd=repo, cpu=args.cpu)
            required(["make", "-j1"], cwd=repo, cpu=args.cpu)
    if args.drat_trim:
        drat = args.drat_trim.resolve()
    else:
        folder = cache / f"drat-trim-{DRAT_REV[:12]}"
        folder.mkdir(exist_ok=True)
        source = folder / "drat-trim.c"
        if not source.exists():
            source.write_bytes(urlopen(f"https://raw.githubusercontent.com/marijnheule/drat-trim/{DRAT_REV}/drat-trim.c").read())
        drat = folder / "drat-trim"
        if not drat.exists():
            required(["cc", "-O2", str(source), "-o", str(drat)], cpu=args.cpu)
    return lrat, drat


def sha(data: str) -> str:
    return hashlib.sha256(data.encode()).hexdigest()


def dimacs(clauses: list[list[int]]) -> str:
    variables = max((abs(lit) for clause in clauses for lit in clause), default=0)
    return f"p cnf {variables} {len(clauses)}\n" + "".join(
        " ".join(map(str, [*clause, 0])) + "\n" for clause in clauses)


def lrat_text(steps: list[dict]) -> str:
    return "".join(" ".join(map(str, [step["id"], *step["clause"], 0,
                                      *step["hints"], 0])) + "\n" for step in steps)


def verified(result, lrat: bool, *, original_empty=False) -> bool:
    # The pinned DRAT-trim reports VERIFIED but exits 1 on its parse-time
    # trivial-UNSAT branch. Permit that only for a visibly empty input clause.
    codes = (20,) if lrat else ((0, 1, 20) if original_empty else (0, 20))
    return result.returncode in codes and any(
        line.strip() == "s VERIFIED" for line in result.stdout.splitlines())


def check_file(binary: Path, cnf: Path, proof: Path, *, lrat: bool, cpu=None):
    command = [str(binary)]
    if lrat:
        command += ["--forward", "--no-trim"]
    return run([*command, str(cnf), str(proof)], cpu=cpu)


def negative_controls(output: Path, lrat: Path, drat: Path, exports: dict, cpu):
    results = []
    sat = output / "negative_sat.cnf"
    sat.write_text("p cnf 1 1\n1 0\n")
    fake_lrat = output / "negative_empty.lrat"
    fake_lrat.write_text("2 0 0\n")
    fake_drup = output / "negative_empty.drup"
    fake_drup.write_text("0\n")
    controls = [("empty-on-SAT", sat, fake_lrat, True),
                ("empty-on-SAT-DRUP", sat, fake_drup, False)]
    chain = exports["chain_occurrence"]
    final = chain["steps"][0]
    for name, hints in [("wrong-hint-order", [2, 1, 3]),
                        ("missing-essential-hint", final["hints"][1:]),
                        ("self-reference", [final["id"]])]:
        proof = output / f"negative_{name}.lrat"
        proof.write_text(lrat_text([{**final, "hints": hints}]))
        controls.append((name, output / "chain_occurrence.cnf", proof, True))
    deleted = output / "negative_deleted_clause.lrat"
    deleted.write_text("3 d 1 0\n" + lrat_text(chain["steps"]))
    controls.append(("deleted-essential-clause", output / "chain_occurrence.cnf", deleted, True))
    truncated = output / "negative_truncated.lrat"
    truncated.write_text(lrat_text(exports["cube_occurrence"]["steps"][:-1]))
    controls.append(("missing-final-empty", output / "cube_occurrence.cnf", truncated, True))
    for name, cnf, proof, is_lrat in controls:
        result = check_file(lrat if is_lrat else drat, cnf, proof,
                            lrat=is_lrat, cpu=cpu)
        if verified(result, is_lrat):
            raise RuntimeError(f"external negative control unexpectedly verified: {name}")
        results.append({"name": name, "returncode": result.returncode,
                        "verified": False})
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / ".tools" / "ruplog-export")
    parser.add_argument("--miter64", action="store_true", help="also export both 64-bit miter certificates")
    parser.add_argument("--check", action="store_true", help="build pinned external checkers and validate all files")
    parser.add_argument("--lrat-trim", type=Path, help="use an existing LRAT-TRIM binary")
    parser.add_argument("--drat-trim", type=Path, help="use an existing DRAT-trim binary")
    parser.add_argument("--cpu", type=int, help="pin subprocesses to one CPU")
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ)
    env["MORPH_RUPLOG_EXPORT"] = "all" if args.miter64 else "small"
    exported = required([str(ROOT / "tools" / "moon"), "test",
                         "src/ruplog/export_wbtest.mbt", "--target", "native", "--release"],
                        env=env, cpu=args.cpu)
    exports = {}
    for line in exported.stdout.splitlines():
        if line.startswith("MORPH_RUPLOG:"):
            case = json.loads(line.removeprefix("MORPH_RUPLOG:"))
            name = case["name"]
            if not re.fullmatch(r"[A-Za-z0-9_]+", name) or name in exports:
                raise RuntimeError(f"invalid or duplicate export name: {name}")
            exports[name] = case
    expected = 16 if args.miter64 else 14
    if len(exports) != expected:
        raise RuntimeError(f"expected {expected} actual kernel exports, received {len(exports)}")
    checkers = checker_tools(args) if args.check else None
    manifest = {"lrat_trim_revision": None if args.lrat_trim else LRAT_REV,
                "drat_trim_revision": None if args.drat_trim else DRAT_REV,
                "cpu": args.cpu, "cases": [], "negative_controls": []}
    if checkers:
        manifest["lrat_trim_binary_sha256"] = hashlib.sha256(checkers[0].read_bytes()).hexdigest()
        manifest["drat_trim_binary_sha256"] = hashlib.sha256(checkers[1].read_bytes()).hexdigest()
    for name, case in exports.items():
        if any(literal == 0 for clause in case["cnf"] for literal in clause):
            raise RuntimeError("zero was exported as a DIMACS variable")
        raw = dimacs(case["cnf"])
        canonical = [list(dict.fromkeys(clause)) for clause in case["cnf"]]
        removed = sum(map(len, case["cnf"])) - sum(map(len, canonical))
        text = dimacs(canonical)
        lrat_proof = lrat_text(case["steps"])
        drup_proof = "".join(" ".join(map(str, [*step["clause"], 0])) + "\n"
                             for step in case["steps"])
        cnf_path = output / f"{name}.cnf"
        lrat_path = output / f"{name}.lrat"
        drup_path = output / f"{name}.drup"
        (output / f"{name}.raw.cnf").write_text(raw)
        cnf_path.write_text(text)
        lrat_path.write_text(lrat_proof)
        drup_path.write_text(drup_proof)
        info = {"name": name, "clauses": len(canonical), "additions": len(case["steps"]),
                "hints": sum(len(step["hints"]) for step in case["steps"]),
                "removed_duplicate_literals": removed, "cnf_sha256": sha(text),
                "lrat_sha256": sha(lrat_proof), "drup_sha256": sha(drup_proof)}
        if checkers:
            for binary, proof, is_lrat in [(checkers[0], lrat_path, True),
                                           (checkers[1], drup_path, False)]:
                checked = check_file(binary, cnf_path, proof, lrat=is_lrat, cpu=args.cpu)
                if not verified(checked, is_lrat, original_empty=any(not clause for clause in canonical)):
                    raise RuntimeError(f"external verification failed: {name}, exit {checked.returncode}\n{checked.stdout}\n{checked.stderr}")
            info.update(lrat_verified=True, drup_verified=True)
        manifest["cases"].append(info)
        print(f"{name}: {info['clauses']} clauses, {info['additions']} additions, {info['hints']} hints" +
              (", LRAT+DRUP verified" if checkers else ", exported"))
    if checkers:
        manifest["negative_controls"] = negative_controls(output, *checkers, exports, args.cpu)
        print(f"Rejected {len(manifest['negative_controls'])} external negative controls")
    for name, info in {case["name"]: case for case in manifest["cases"]}.items():
        if name.endswith("_scan"):
            other_name = name.removesuffix("_scan") + "_occurrence"
            other = next(case for case in manifest["cases"] if case["name"] == other_name)
            if (info["cnf_sha256"], info["drup_sha256"]) != (other["cnf_sha256"], other["drup_sha256"]):
                raise RuntimeError(f"builder outputs changed input or erased proof: {name}")
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Artifacts: {output}")


if __name__ == "__main__":
    main()
