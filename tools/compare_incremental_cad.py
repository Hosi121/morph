#!/usr/bin/env python3
"""Run one frozen executable in both CAD/SMT modes, including proof checking.

Build src/cmd/incrementalbench with the recorded SDK first. Invoke this script
under tools/measure to serialize CPU work across linked worktrees. Both modes
use the same artifact, exact inputs and Collins projection. The reported total
includes preparation, search and an external verification of the final result.
SMT search also performs its normal internal model/lemma/refutation checks.
"""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import platform
import statistics
import subprocess
import time

ROOT = Path(__file__).resolve().parent.parent
CASES = ["constant-sat4", "prefix-unsat2", "circle-sat2", "diagonal-sat3",
         "diagonal-unsat3", "diagonal-unsat4", "univariate-sat", "univariate-unsat",
         "constant-unsat4", "constant-unsat6", "squares-unsat3", "squares-unsat4",
         "alternatives-sat3", "alternatives-sat4"]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--artifact", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--target", choices=["native", "js", "wasm-gc"], default="native")
    parser.add_argument("--runner", nargs="+", default=[])
    parser.add_argument("--case", action="append", choices=CASES, dest="cases")
    parser.add_argument("--layer", action="append", choices=["cad", "smt"], dest="layers")
    parser.add_argument("--modes", nargs=2, choices=["full", "pruned", "retained"], default=["full", "pruned"])
    parser.add_argument("--timeout", type=float, default=60)
    args = parser.parse_args()
    if args.modes[0] == args.modes[1]:
        parser.error("comparison modes must differ")
    if "retained" in args.modes and args.layers != ["smt"]:
        parser.error("retained mode comparison requires --layer smt")
    first_mode, second_mode = args.modes
    affinity = sorted(os.sched_getaffinity(0))
    if len(affinity) != 1:
        parser.error("Run under tools/measure --cpu N for shared serialization and fixed affinity.")
    if args.timeout <= 0:
        parser.error("timeout must be positive")
    artifact = args.artifact.resolve()
    artifact_sha = digest(artifact)
    source_rows = [(str(path.relative_to(ROOT)), digest(path))
                   for path in sorted((ROOT / "src").rglob("*"))
                   if path.is_file() and path.suffix in [".mbt", ".pkg", ".mbti"]]
    source_sha = hashlib.sha256(json.dumps(source_rows, separators=(",", ":")).encode()).hexdigest()
    provenance = {"source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
                  "source_manifest_sha256": source_sha, "source_files": len(source_rows),
                  "working_diff_sha256": hashlib.sha256(subprocess.check_output(["git", "diff", "HEAD"], cwd=ROOT)).hexdigest(),
                  "artifact": str(artifact), "artifact_sha256": artifact_sha,
                  "compiler": subprocess.check_output([str(ROOT / "tools/moon"), "version", "--all"], cwd=ROOT, text=True).strip(),
                  "platform": platform.platform(), "cpu_affinity": affinity,
                  "target": args.target, "profile": "release", "order": "ABBA", "modes": args.modes,
                  "runner": args.runner,
                  "unit": "microseconds", "projection": "full Collins in both modes",
                  "timing_scope": "fixture construction excluded; prepare + search + final external verification included; SMT search includes internal checks",
                  "records": [], "summary": []}
    args.output.parent.mkdir(parents=True, exist_ok=True)

    def save():
        args.output.write_text(json.dumps(provenance, indent=2, ensure_ascii=False) + "\n")

    save()
    for layer in args.layers or ["cad", "smt"]:
        for case in args.cases or CASES:
            rows = []
            for position, mode in enumerate([first_mode, second_mode, second_mode, first_mode]):
                if digest(artifact) != artifact_sha:
                    raise RuntimeError("Frozen artifact changed")
                command = [*args.runner, str(artifact), layer, mode, case]
                began = time.perf_counter()
                try:
                    run = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=args.timeout)
                except subprocess.TimeoutExpired as error:
                    record = {"layer": layer, "case": case, "mode": mode,
                              "position": position, "completed": False,
                              "timeout_seconds": args.timeout, "process_wall_seconds": time.perf_counter()-began,
                              "stdout": str(error.stdout or ""), "stderr": str(error.stderr or "")}
                    provenance["records"].append(record)
                    rows.append(record)
                    save()
                    print(json.dumps({key: record[key] for key in ["layer", "case", "mode", "completed"]}), flush=True)
                    continue
                wall = time.perf_counter() - began
                if run.returncode:
                    raise RuntimeError(f"Failed {command}: {run.returncode}\n{run.stdout}\n{run.stderr}")
                values = [json.loads(line) for line in run.stdout.splitlines() if line.startswith("{")]
                if len(values) != 1:
                    raise RuntimeError("Expected one measured and checked decision: " + run.stdout)
                record = {**values[0], "position": position, "completed": True,
                          "process_wall_seconds": wall, "stderr": run.stderr}
                if any(record[key] != expected for key, expected in [("layer", layer), ("mode", mode), ("case", case)]):
                    raise RuntimeError("Wrong measurement source binding")
                provenance["records"].append(record)
                rows.append(record)
                save()
            completed = [row for row in rows if row["completed"]]
            if len(completed) == 4:
                if len({row["satisfiable"] for row in completed}) != 1:
                    raise RuntimeError("Modes disagree")
                summary = {"layer": layer, "case": case}
                for mode in args.modes:
                    mode_rows = [row for row in completed if row["mode"] == mode]
                    summary[mode] = {key: statistics.median(row[key] for row in mode_rows)
                                     for key in ["preparation_us", "search_us", "verification_us", "total_us", "transitions", "boolean_restarts", "theory_conflicts"]}
                summary["total_speedup"] = summary[first_mode]["total_us"] / summary[second_mode]["total_us"]
                summary["conservative_total_speedup"] = min(row["total_us"] for row in completed if row["mode"] == first_mode) / max(row["total_us"] for row in completed if row["mode"] == second_mode)
                provenance["summary"].append(summary)
                save()
                print(json.dumps(summary), flush=True)
    if digest(artifact) != artifact_sha:
        raise RuntimeError("Frozen artifact changed")
    for name, sha in source_rows:
        if digest(ROOT / name) != sha:
            raise RuntimeError("Source changed during run: " + name)
    provenance["finished_utc"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    save()


if __name__ == "__main__":
    main()
