#!/usr/bin/env python3
"""Compare two prebuilt exact-field public-API benchmarks in ABBA blocks.

Run under tools/measure --cpu N. Compilation is excluded. Every executable must
emit a JSON object with checked=true and identical non-timing output. Process
time includes startup, setup, calculation and checks; optional elapsed_us keeps
the benchmark's separately declared inner interval. Raw values are retained.
"""
from argparse import ArgumentParser
from datetime import datetime, timezone
from hashlib import sha256
from pathlib import Path
import json
import math
import os
import platform
import statistics
import subprocess
import time


def normalized(payload):
    if not isinstance(payload, dict) or payload.get("checked") is not True:
        raise ValueError("benchmark did not report a checked result")
    if "elapsed_us" in payload:
        value = payload["elapsed_us"]
        if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or value < 0:
            raise ValueError("invalid inner duration")
    return {key: value for key, value in payload.items() if key != "elapsed_us"}


def digest(path):
    return sha256(Path(path).read_bytes()).hexdigest()


def provenance(root, artifact, harness):
    root = root.resolve(strict=True)
    def git(*args):
        return subprocess.check_output(["git", "-C", str(root), *args], text=True).strip()
    sources = sorted([root / "moon.mod", root / "tools/moon"] +
                     list((root / "src").rglob("*.mbt")) + list((root / "src").rglob("moon.pkg")))
    manifest = sha256()
    for path in sources:
        manifest.update(str(path.relative_to(root)).encode() + b"\0" + path.read_bytes() + b"\0")
    return {"root": str(root), "commit": git("rev-parse", "HEAD"),
            "working_tree": git("status", "--porcelain").splitlines(),
            "source_manifest_sha256": manifest.hexdigest(), "source_file_count": len(sources),
            "artifact": str(artifact), "artifact_sha256": digest(artifact),
            "harness": {name: digest(root / harness / name) for name in ("main.mbt", "moon.pkg")},
            "compiler": subprocess.check_output([str(root / "tools/moon"), "version", "--all"], text=True)}


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("--before", type=Path, required=True)
    parser.add_argument("--after", type=Path, required=True)
    parser.add_argument("--before-root", type=Path, required=True)
    parser.add_argument("--after-root", type=Path, required=True)
    parser.add_argument("--harness", required=True, help="same relative CLI package path in both roots")
    parser.add_argument("--case", action="append", required=True)
    parser.add_argument("--groups", type=int, default=5)
    parser.add_argument("--timeout-seconds", type=float, default=120)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.groups < 1 or args.timeout_seconds <= 0:
        parser.error("positive groups and timeout required")
    artifacts = {"before": args.before.resolve(strict=True), "after": args.after.resolve(strict=True)}
    before = provenance(args.before_root, artifacts["before"], args.harness)
    after = provenance(args.after_root, artifacts["after"], args.harness)
    if before["harness"] != after["harness"]:
        parser.error("benchmark sources differ; freeze an identical harness first")
    report = {"utc": datetime.now(timezone.utc).isoformat(), "before": before, "after": after,
              "platform": platform.platform(), "affinity": sorted(os.sched_getaffinity(0)),
              "groups": args.groups, "order": ["before", "after", "after", "before"],
              "scope": "whole process including startup, any warm-up, setup, operation and result checks; prebuilt artifacts exclude compilation",
              "inner_scope": "elapsed_us if supplied; interval is defined by the identical benchmark source",
              "runs": [], "summary": {}, "all_checked": False}
    expected = {}
    def save():
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    try:
        for case in args.case:
            for group in range(args.groups):
                for position, variant in enumerate(report["order"]):
                    start = time.perf_counter_ns()
                    process = subprocess.run([str(artifacts[variant]), case], capture_output=True,
                                             text=True, timeout=args.timeout_seconds)
                    elapsed = time.perf_counter_ns() - start
                    payload = json.loads(process.stdout)
                    result = normalized(payload)
                    checked = process.returncode == 0 and result == expected.setdefault(case, result)
                    report["runs"].append({"case": case, "group": group, "position": position,
                                           "variant": variant, "process_ns": elapsed,
                                           "payload": payload, "stdout": process.stdout,
                                           "stderr": process.stderr, "exit_code": process.returncode,
                                           "checked": checked})
                    save()
                    if not checked:
                        raise ValueError("unequal output or failed benchmark: " + case)
            runs = [run for run in report["runs"] if run["case"] == case]
            entry = {}
            for timer in ("process_ns", "elapsed_us"):
                if timer == "elapsed_us" and not all(timer in run["payload"] for run in runs):
                    continue
                def value(run):
                    return run[timer] if timer == "process_ns" else run["payload"][timer]
                medians = {variant: statistics.median(value(run) for run in runs if run["variant"] == variant)
                           for variant in artifacts}
                ratios = []
                for group in range(args.groups):
                    by_variant = {variant: statistics.median(value(run) for run in runs
                                  if run["group"] == group and run["variant"] == variant)
                                  for variant in artifacts}
                    ratios.append(by_variant["before"] / by_variant["after"] if by_variant["after"] else None)
                entry[timer] = {"medians": medians,
                                "ranges": {variant: [min(value(run) for run in runs if run["variant"] == variant),
                                                      max(value(run) for run in runs if run["variant"] == variant)]
                                           for variant in artifacts},
                                "before_over_after": medians["before"] / medians["after"] if medians["after"] else None,
                                "block_ratios": ratios}
            report["summary"][case] = entry
            save()
            print(case, json.dumps(entry), flush=True)
        report["all_checked"] = all(run["checked"] for run in report["runs"])
        for variant, artifact in artifacts.items():
            assert digest(artifact) == report[variant]["artifact_sha256"], "artifact changed during measurement"
    except BaseException as error:
        report["error"] = str(error)
        raise
    finally:
        save()


if __name__ == "__main__":
    main()
