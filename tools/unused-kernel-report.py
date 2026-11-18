#!/usr/bin/env python3
"""Summarize the bounded expansion comparison and scoped call-path inventory."""
import argparse
import hashlib
import json
import platform
import re
import statistics
import subprocess
from pathlib import Path

import audit_paths

ROOT = Path(__file__).resolve().parent.parent
BASELINE = "1931625"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def function_body(source, name):
    code = re.sub(r"\s+", "", audit_paths.code_only(source))
    opening = code.index("{", code.index(f"fn{name}("))
    depth, end = 1, opening + 1
    while depth:
        depth += (code[end] == "{") - (code[end] == "}")
        end += 1
    return code[opening:end].encode()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bench", type=Path,
                        default=ROOT / "tools/unused-kernel-js-bench.txt")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    rows = [json.loads(line) for line in args.bench.read_text().splitlines()
            if line.startswith('[{"name":')]
    assert len(rows) == 1, "expected one benchmark JSON array"
    rows = rows[0]
    assert len(rows) == 60, "expected 3 cases, 5 ABBA blocks, 4 groups"
    groups = {}
    for offset in range(0, len(rows), 4):
        block = rows[offset:offset + 4]
        case, block_name, _ = block[0]["name"].split("/")
        assert [row["name"] for row in block] == [
            f"{case}/{block_name}/{kind}"
            for kind in ("reference", "candidate", "candidate", "reference")]
        assert all(row["runs"] == 5 for row in block)
        reference = statistics.mean(row["mean"] for row in (block[0], block[3]))
        candidate = statistics.mean(row["mean"] for row in (block[1], block[2]))
        groups.setdefault(case, []).append({
            "block": block_name,
            "reference_mean_us": reference,
            "candidate_mean_us": candidate,
            "reference_over_candidate": reference / candidate,
        })
    results = {}
    for case, blocks in groups.items():
        assert [block["block"] for block in blocks] == [f"block{i}" for i in range(5)]
        results[case] = {
            "blocks": blocks,
            "reference_median_block_mean_us": statistics.median(
                block["reference_mean_us"] for block in blocks),
            "candidate_median_block_mean_us": statistics.median(
                block["candidate_mean_us"] for block in blocks),
            "median_reference_over_candidate": statistics.median(
                block["reference_over_candidate"] for block in blocks),
            "improved_blocks": sum(block["reference_over_candidate"] > 1 for block in blocks),
        }
    references, failures, importers = audit_paths.inventory()
    assert not failures, failures
    baseline_source = subprocess.check_output(
        ["git", "show", f"{BASELINE}:src/runbinary/runbinary.mbt"], cwd=ROOT, text=True)
    baseline_body = function_body(baseline_source, "expand")
    reference_body = function_body(
        (ROOT / "src/runbinary/expansion_bench_wbtest.mbt").read_text(), "expansion_reference")
    assert baseline_body == reference_body, "benchmark reference body differs from baseline"
    unchanged = {}
    for path in ("src/core/data.mbt", "src/core/pkg.generated.mbti",
                 "src/runbinary/pkg.generated.mbti", "formal/source-map.json"):
        current = (ROOT / path).read_bytes()
        baseline = subprocess.check_output(["git", "show", f"{BASELINE}:{path}"], cwd=ROOT)
        unchanged[path] = {"sha256": sha(current), "matches_baseline": current == baseline}
        assert current == baseline, path
    report = {
        "baseline": BASELINE,
        "environment": {
            "system": platform.platform(),
            "moon": subprocess.check_output([str(ROOT / "tools/moon"), "version"], text=True).strip(),
            "node": subprocess.check_output(["node", "--version"], text=True).strip(),
            "backend": "js release", "cpu": 4,
            "command": "tools/measure --cpu 4 tools/moon bench src/runbinary/expansion_bench_wbtest.mbt --target js --release -j 1",
            "sampling": "same artifact; 5 ABBA blocks per case, 5 bench samples per group; group means in microseconds",
            "timed_scope": "public expand, with width check, run-length conversion, bit-list normalization and retained result; excludes input construction and equality checks",
        },
        "call_paths": {"symbols": {symbol: references[symbol]
                                   for symbol in ("core.gcd", "core.interleave")},
                       "runbinary_body_importers": importers,
                       "method": "existing lexical inventory; excludes self-recursion, comments and strings; not an external-usage/reachability proof"},
        "unchanged": unchanged,
        "reference_matches_baseline_body_tokens": True,
        "baseline_expand_body_tokens_sha256": sha(baseline_body),
        "measurement_log_sha256": sha(args.bench.read_bytes()),
        "bench_source_sha256": sha((ROOT / "src/runbinary/expansion_bench_wbtest.mbt").read_bytes()),
        "candidate_source_sha256": sha((ROOT / "src/runbinary/runbinary.mbt").read_bytes()),
        "results": results,
    }
    output = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.write_text(output)
    else:
        print(output, end="")


if __name__ == "__main__":
    main()
