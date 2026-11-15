#!/usr/bin/env python3
"""Run one pinned, already-built MoonBit benchmark ELF and preserve its output."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument("binary", type=Path)
parser.add_argument("label")
parser.add_argument("source_commit")
parser.add_argument("--cpu", type=int, default=6)
parser.add_argument("--out", type=Path, default=Path(__file__).resolve().parent)
args = parser.parse_args()
binary = args.binary.resolve()
before = os.getloadavg()
start = time.perf_counter()
result = subprocess.run(["taskset", "-c", str(args.cpu), str(binary), "perf_wbtest.mbt:0-2"], capture_output=True, text=True, check=True)
elapsed = time.perf_counter() - start
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
assert len(summaries) == 9, len(summaries)
report = {"label": args.label, "source_commit": args.source_commit, "binary_sha256": hashlib.sha256(binary.read_bytes()).hexdigest(),
          "timestamp_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(), "pinned_cpu": args.cpu,
          "elapsed_seconds": elapsed, "load_before": before, "load_after": os.getloadavg(), "units": "microseconds per operation", "summaries": summaries}
(args.out / f"{args.label}.json").write_text(json.dumps(report, indent=2) + "\n")
print(args.label, {item["name"]: round(item["mean"], 3) for item in summaries}, flush=True)
