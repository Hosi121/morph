#!/usr/bin/env python3
"""Run one pinned, already-built MoonBit benchmark ELF and preserve its output."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import resource
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument("binary", type=Path)
parser.add_argument("label")
parser.add_argument("source_commit")
parser.add_argument("--cpu", type=int, default=6)
parser.add_argument("--tests", default="perf_wbtest.mbt:0-2")
parser.add_argument("--cases", type=int, default=9)
parser.add_argument("--timer", choices=["wall", "thread-cpu"], default="wall")
parser.add_argument("--out", type=Path, default=Path(__file__).resolve().parent)
args = parser.parse_args()
binary = args.binary.resolve()
source_commit = subprocess.check_output(["git", "rev-parse", "--verify", args.source_commit + "^{commit}"], text=True).strip()
before = os.getloadavg()
usage_before = resource.getrusage(resource.RUSAGE_CHILDREN)
start = time.perf_counter()
result = subprocess.run(["taskset", "-c", str(args.cpu), str(binary), args.tests], capture_output=True, text=True, check=True)
elapsed = time.perf_counter() - start
usage_after = resource.getrusage(resource.RUSAGE_CHILDREN)
user_seconds = usage_after.ru_utime - usage_before.ru_utime
system_seconds = usage_after.ru_stime - usage_before.ru_stime
args.out.mkdir(parents=True, exist_ok=True)
(args.out / f"{args.label}.stdout").write_text(result.stdout)
(args.out / f"{args.label}.stderr").write_text(result.stderr)
summaries = []
for line in result.stdout.splitlines():
    if not line.startswith("{"):
        continue
    record = json.loads(line)
    if record.get("type") == "result":
        message = record["message"]
        assert message.startswith("@BATCH_BENCH "), message
        summaries.extend(json.loads(message.removeprefix("@BATCH_BENCH "))["summaries"])
assert len(summaries) == args.cases, len(summaries)
report = {"label": args.label, "source_commit": source_commit, "binary_sha256": hashlib.sha256(binary.read_bytes()).hexdigest(),
          "test_selection": args.tests, "case_count": args.cases,
          "benchmark_timer": args.timer, "child_user_seconds": user_seconds,
          "child_system_seconds": system_seconds,
          "child_cpu_to_elapsed": (user_seconds + system_seconds) / elapsed,
          "child_minor_faults": usage_after.ru_minflt - usage_before.ru_minflt,
          "child_major_faults": usage_after.ru_majflt - usage_before.ru_majflt,
          "child_voluntary_switches": usage_after.ru_nvcsw - usage_before.ru_nvcsw,
          "child_involuntary_switches": usage_after.ru_nivcsw - usage_before.ru_nivcsw,
          "child_peak_rss_kib": usage_after.ru_maxrss,
          "timestamp_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(), "pinned_cpu": args.cpu,
          "elapsed_seconds": elapsed, "load_before": before, "load_after": os.getloadavg(), "units": "microseconds per operation", "summaries": summaries}
(args.out / f"{args.label}.json").write_text(json.dumps(report, indent=2) + "\n")
print(args.label, {item["name"]: round(item["mean"], 3) for item in summaries}, flush=True)
