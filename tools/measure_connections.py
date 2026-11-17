#!/usr/bin/env python3
"""Measure checked cross-domain examples from one prebuilt release artifact.

Process startup and every in-program preparation/check are included; compilation
is excluded. These are different workloads, not a speed comparison of algorithms.
Run under tools/measure to serialize and pin execution.
"""
from argparse import ArgumentParser
from datetime import datetime, timezone
from hashlib import sha256
from pathlib import Path
import json
import os
import platform
import statistics
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
STARTS = {
    "groups": "S4:",
    "bernstein": "x^2-x+3/8 on [0,1]:",
    "homology": "circle:",
    "presentation": "RP2:",
    "galois": "z^3-2:",
}


def expected_sections():
    lines = (ROOT / "docs/CONNECTIONS_TOUR.txt").read_text().splitlines(keepends=True)
    positions = []
    for mode, prefix in STARTS.items():
        matches = [i for i, line in enumerate(lines) if line.startswith(prefix)]
        if len(matches) != 1:
            raise SystemExit(f"expected one {mode} section in CONNECTIONS_TOUR.txt")
        positions.append((mode, matches[0]))
    if [p for _, p in positions] != sorted(p for _, p in positions):
        raise SystemExit("tour sections are out of order")
    return {
        mode: "".join(lines[start:positions[i + 1][1] if i + 1 < len(positions) else len(lines)])
        for i, (mode, start) in enumerate(positions)
    }


def source_manifest():
    paths = sorted([ROOT / "moon.mod", ROOT / "tools/moon"] +
                   list((ROOT / "src").rglob("*.mbt")) +
                   list((ROOT / "src").rglob("moon.pkg")))
    digest = sha256()
    for path in paths:
        digest.update(str(path.relative_to(ROOT)).encode() + b"\0" + path.read_bytes() + b"\0")
    return {"files": len(paths), "sha256": digest.hexdigest()}


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("--artifact", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--repetitions", type=int, default=3)
    parser.add_argument("--timeout-seconds", type=float, default=30)
    parser.add_argument("--case", action="append", choices=list(STARTS))
    args = parser.parse_args()
    if args.repetitions < 1 or args.timeout_seconds <= 0:
        parser.error("repetitions and timeout must be positive")
    artifact = args.artifact.resolve(strict=True)
    expected = expected_sections()
    selected = args.case or list(STARTS)
    status = subprocess.check_output(["git", "status", "--porcelain"], cwd=ROOT, text=True)
    result = {
        "utc": datetime.now(timezone.utc).isoformat(),
        "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "working_tree_status": status.splitlines(),
        "source_manifest": source_manifest(),
        "artifact": str(artifact.relative_to(ROOT)) if artifact.is_relative_to(ROOT) else str(artifact),
        "artifact_sha256": sha256(artifact.read_bytes()).hexdigest(),
        "affinity": sorted(os.sched_getaffinity(0)),
        "platform": platform.platform(),
        "python": platform.python_version(),
        "compiler": subprocess.check_output([str(ROOT / "tools/moon"), "version", "--all"], cwd=ROOT, text=True),
        "backend": "native",
        "profile": "release (caller-provided prebuilt artifact)",
        "scope": "process startup, example construction, preparation, computation and all example result checks; excludes compilation",
        "case_scope": {
            "groups": "S4/A5/S5 complete group generation, derived series and replay checks",
            "bernstein": "exact quadratic enclosure, subdivision proof, independent CAD check, strict/non-strict boundary witnesses",
            "homology": "H0/H1/H2 for circle, disk, sphere, RP2 with integral certificate checks",
            "presentation": "five abelianizations including independent RP2/torus simplicial H1 comparisons",
            "galois": "x^3-2 complete splitting field, full exact Galois action, derived series and bound certificate checks",
        },
        "repetitions": args.repetitions,
        "timeout_seconds": args.timeout_seconds,
        "runs": [],
    }
    for repetition in range(args.repetitions):
        for mode in selected:
            before = time.perf_counter()
            try:
                process = subprocess.run([str(artifact), mode], cwd=ROOT, text=True,
                                         capture_output=True, timeout=args.timeout_seconds)
                record = {"repetition": repetition, "mode": mode, "seconds": time.perf_counter() - before,
                          "exit_code": process.returncode, "stdout": process.stdout,
                          "stderr": process.stderr, "censored": False,
                          "checked": process.returncode == 0 and process.stdout == expected[mode]}
            except subprocess.TimeoutExpired:
                record = {"repetition": repetition, "mode": mode,
                          "seconds": time.perf_counter() - before, "censored": True, "checked": False}
            result["runs"].append(record)
            print(f"{mode} trial {repetition + 1}: {record['seconds']:.6f}s checked={record['checked']}", flush=True)
    result["summary"] = {}
    for mode in selected:
        runs = [record for record in result["runs"] if record["mode"] == mode]
        complete = [record["seconds"] for record in runs if record.get("checked")]
        result["summary"][mode] = {
            "completed_and_checked": len(complete),
            "censored": sum(record["censored"] for record in runs),
            "median_seconds_completed_only": statistics.median(complete) if complete else None,
        }
    result["all_checked"] = all(record["checked"] for record in result["runs"])
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    if not result["all_checked"]:
        raise SystemExit("at least one workload did not complete with its expected checked output")


if __name__ == "__main__":
    main()
