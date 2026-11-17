#!/usr/bin/env python3
"""Paired same-artifact GF2 prototype timings; invoke through tools/measure."""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import platform
import statistics
import subprocess
import tempfile
import time


ROOT = Path(__file__).resolve().parent.parent


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def execute(exe: Path, variant: str, workload: str, shape: str, repetitions: int) -> dict:
    command = [str(exe), variant, workload, shape, str(repetitions)]
    with tempfile.TemporaryFile(mode="w+") as stdout, tempfile.TemporaryFile(mode="w+") as stderr:
        start = time.perf_counter_ns()
        process = subprocess.Popen(command, stdout=stdout, stderr=stderr)
        _, status, usage = os.wait4(process.pid, 0)
        elapsed = time.perf_counter_ns() - start
        process.returncode = os.waitstatus_to_exitcode(status)
        stdout.seek(0)
        output = stdout.read()
        stderr.seek(0)
        errors = stderr.read()
    if process.returncode or errors:
        raise RuntimeError(f"{command}: exit={process.returncode}\n{output}\n{errors}")
    value = json.loads(output)
    if not value["checked"] or value["digest"] != value["rank"] * repetitions:
        raise RuntimeError(f"invalid benchmark output: {output}")
    return {"variant": variant, "elapsed_ns": elapsed, "max_rss_kib": usage.ru_maxrss,
            "user_seconds": usage.ru_utime, "system_seconds": usage.ru_stime, "output": value}


def main() -> None:
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument("--artifact", type=Path, default=ROOT / "_build/native/release/build/cmd/gf2kernelbench/gf2kernelbench.exe")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--rounds", type=int, default=5)
    parser.add_argument("--minimum-seconds", type=float, default=0.12)
    parser.add_argument("--workloads", nargs="+", default=["rref", "factor", "certificate", "solve", "reuse"])
    parser.add_argument("--shapes", nargs="+", default=["small", "dense", "sparse", "dependent", "wide", "tall"])
    args = parser.parse_args()
    if os.sched_getaffinity(0) != {4}:
        raise SystemExit("invoke as tools/measure --cpu 4 python3 tools/measure_gf2_kernel.py ...")
    artifact = args.artifact.resolve()
    source_files = sorted(path for folder in ["src/gf2", "src/cmd/gf2kernelbench", "src/rowreduce", "src/matrix", "src/core", "src/algebra"]
                          for path in (ROOT / folder).rglob("*") if path.is_file() and (path.suffix in {".mbt", ".pkg"} or path.name.endswith(".mbti")))
    data = {"kind": "same-native-release-artifact-prototype", "baseline_commit": "4d9e6c4e0795f3e950fbeaac2b191f195eea45b5",
            "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
            "source_files": {str(path.relative_to(ROOT)): sha(path) for path in source_files},
            "artifact": str(artifact.relative_to(ROOT)), "artifact_sha256": sha(artifact),
            "driver_sha256": sha(Path(__file__)), "rounds": args.rounds,
            "minimum_seconds": args.minimum_seconds,
            "compiler": subprocess.check_output([str(ROOT / "tools/moon"), "version", "--all"], cwd=ROOT, text=True).strip(),
            "platform": platform.platform(), "affinity": sorted(os.sched_getaffinity(0)),
            "cpuinfo": Path("/proc/cpuinfo").read_text().split("\n\n")[4],
            "interval": "whole process: source construction, generic exact reference, repeated API call, validation, digest, output, teardown",
            "memory": "per-child wait4 ru_maxrss KiB; whole process high-water mark",
            "order": "ABBA rounds: baseline,gf2,gf2,baseline; independent process per sample",
            "started_utc": dt.datetime.now(dt.timezone.utc).isoformat(), "cases": []}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    for workload in args.workloads:
        for shape in args.shapes:
            case = {"workload": workload, "shape": shape, "setup_samples": [], "calibration": [], "samples": []}
            for variant in ["baseline", "gf2"]:
                case["setup_samples"].append(execute(artifact, variant, workload, shape, 0))
            repetitions = 1
            while True:
                trial = [execute(artifact, variant, workload, shape, repetitions) for variant in ["baseline", "gf2"]]
                case["calibration"].extend(trial)
                if min(item["elapsed_ns"] for item in trial) >= args.minimum_seconds * 1e9:
                    break
                repetitions *= 2
            case["repetitions"] = repetitions
            for round_index in range(args.rounds):
                for position, variant in enumerate(["baseline", "gf2", "gf2", "baseline"]):
                    result = execute(artifact, variant, workload, shape, repetitions)
                    result.update(round=round_index, position=position)
                    case["samples"].append(result)
            expected = case["samples"][0]["output"]
            if any(sample["output"] != expected for sample in case["samples"]):
                raise RuntimeError("baseline and GF2 outputs differ")
            medians = {variant: statistics.median(sample["elapsed_ns"] for sample in case["samples"] if sample["variant"] == variant)
                       for variant in ["baseline", "gf2"]}
            case["summary"] = {"median_ns": medians, "speedup": medians["baseline"] / medians["gf2"],
                               "median_max_rss_kib": {variant: statistics.median(sample["max_rss_kib"] for sample in case["samples"] if sample["variant"] == variant) for variant in ["baseline", "gf2"]}}
            data["cases"].append(case)
            data["updated_utc"] = dt.datetime.now(dt.timezone.utc).isoformat()
            args.output.write_text(json.dumps(data, indent=2) + "\n")
            print(f"{workload:12} {shape:10} reps={repetitions:6} baseline={medians['baseline']/1e6:9.3f}ms gf2={medians['gf2']/1e6:9.3f}ms speedup={case['summary']['speedup']:.3f}", flush=True)
    data["finished_utc"] = dt.datetime.now(dt.timezone.utc).isoformat()
    if sha(artifact) != data["artifact_sha256"]:
        raise RuntimeError("artifact changed during measurement")
    args.output.write_text(json.dumps(data, indent=2) + "\n")


if __name__ == "__main__":
    main()
