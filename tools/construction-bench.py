#!/usr/bin/env python3
"""Verify saved quotient-experiment outputs, source hashes and time/RSS summaries.

The unadopted producer and generic packages were removed from the normal source.
Restore revision cf08aaa to rerun the experiment; this command verifies evidence.
"""
import argparse
import base64
import gzip
import hashlib
import json
import math
from pathlib import Path
import re
import statistics
import sys


SCHEMA = "mathematical-construction-benchmark-v1"
CASES = {
    "gf2-d4": {"degree": 4, "prime": 2, "modulus": [1, 1, 0, 0, 1],
               "cycle": 64, "iterations": 32768},
    "gf2-d8": {"degree": 8, "prime": 2, "modulus": [1, 1, 0, 1, 1, 0, 0, 0, 1],
               "cycle": 64, "iterations": 32768},
    "fp5-d2": {"degree": 2, "prime": 5, "modulus": [2, 0, 1],
               "cycle": 25, "iterations": 16384},
    "qq-d2": {"degree": 2, "prime": None, "modulus": [-2, 0, 1],
              "cycle": 16, "iterations": 8192},
    "qq-d4": {"degree": 4, "prime": None, "modulus": [1, 0, -10, 0, 1],
              "cycle": 16, "iterations": 8192},
}
COMPARISONS = [(case, "generic") for case in CASES] + [
    ("gf2-d4", "fused"), ("gf2-d8", "fused")]
MAX_PROCESSES = 140
TIMEOUT_SECONDS = 60
RAW_LIMIT = 64 * 1024 * 1024


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def packed(data):
    return {"encoding": "gzip+base64", "sha256": sha(data), "bytes": len(data),
            "data": base64.b64encode(gzip.compress(data, mtime=0)).decode("ascii")}


def unpacked(record):
    require(record["encoding"] == "gzip+base64", "unknown compressed encoding")
    require(type(record["bytes"]) is int and 0 <= record["bytes"] <= RAW_LIMIT,
            "invalid uncompressed byte count")
    data = gzip.decompress(base64.b64decode(record["data"], validate=True))
    require(len(data) == record["bytes"] and sha(data) == record["sha256"],
            "compressed content length/hash mismatch")
    return data


def trim(values, prime=None):
    result = [x % prime if prime is not None else x for x in values]
    while result and result[-1] == 0:
        result.pop()
    return result


def integer_product(a, b):
    """Ordinary integer convolution; no GF2 bit kernel is reused."""
    if not a or not b:
        return []
    product = [0] * (len(a) + len(b) - 1)
    for i, left in enumerate(a):
        for j, right in enumerate(b):
            product[i + j] += left * right
    return product


def monic_division(dividend, divisor, prime=None):
    """Integer long division, reducing coefficients modulo p when requested."""
    divisor = trim(divisor, prime)
    require(divisor and divisor[-1] == 1, "oracle requires a monic divisor")
    remainder = trim(dividend, prime)
    quotient = [0] * max(0, len(remainder) - len(divisor) + 1)
    while len(remainder) >= len(divisor):
        shift = len(remainder) - len(divisor)
        factor = remainder[-1]
        quotient[shift] = factor
        for index, coefficient in enumerate(divisor):
            remainder[index + shift] -= factor * coefficient
        remainder = trim(remainder, prime)
    return trim(quotient, prime), remainder


def product_remainder(a, b, modulus, prime=None):
    return monic_division(integer_product(a, b), modulus, prime)[1]


def inputs(case, index):
    config = CASES[case]
    degree = config["degree"]
    if case.startswith("gf2-"):
        a = (index * 17 + 3) % (1 << degree)
        b = (index * 29 + 5) % (1 << degree)
        return ([(a >> j) & 1 for j in range(degree)],
                [(b >> j) & 1 for j in range(degree)])
    if case == "fp5-d2":
        return [index % 5, index // 5], [(index * 3 + 1) % 5, (index * 2 + 4) % 5]
    return ([(index * 3 + j * 2) % 5 - 2 for j in range(degree)],
            [(index * 2 + j * 3 + 1) % 5 - 2 for j in range(degree)])


def expected_outputs(case):
    config = CASES[case]
    cycle = []
    for index in range(config["cycle"]):
        left, right = inputs(case, index)
        remainder = product_remainder(left, right, config["modulus"], config["prime"])
        if case.startswith("gf2-"):
            value = [sum(coefficient << j for j, coefficient in enumerate(remainder))]
        elif case.startswith("qq-"):
            # Integer inputs and a monic integer modulus imply integer residues;
            # the CLI's rational numerator encoding therefore loses no denominator.
            value = remainder + [0] * (config["degree"] - len(remainder))
        else:
            value = remainder
        cycle.append(value)
    return [cycle[i % len(cycle)] for i in range(config["iterations"])]


def check_output(stdout, case, route, expected):
    payload = json.loads(stdout)
    require(set(payload) == {"case", "route", "elapsed_us", "outputs"}, "unexpected CLI JSON fields")
    require(payload["case"] == case and payload["route"] == route, "CLI case/route mismatch")
    elapsed = payload["elapsed_us"]
    require(type(elapsed) in (int, float) and math.isfinite(elapsed) and elapsed > 0,
            "CLI elapsed_us must be finite and positive")
    actual = payload["outputs"]
    require(type(actual) is list and len(actual) == len(expected), "wrong output count")
    for index, (row, reference) in enumerate(zip(actual, expected)):
        require(type(row) is list and all(type(x) is int for x in row),
                f"non-integer coefficient output at {index}")
        require(row == reference, f"independent polynomial result differs: {case}/{route} output {index}")
    return elapsed


def protocol_plan(pairs):
    require(type(pairs) is int and 1 <= pairs <= 5, "pairs must be between 1 and 5 (140-process maximum)")
    for case, candidate in COMPARISONS:
        comparison = f"{case}:old-vs-{candidate}"
        for pair in range(pairs):
            for position, route in enumerate(("old", candidate, candidate, "old")):
                yield {"comparison": comparison, "case": case, "candidate": candidate,
                       "pair": pair, "abba_position": position, "route": route}


def summarize(runs, pairs):
    result = {}
    for case, candidate in COMPARISONS:
        name = f"{case}:old-vs-{candidate}"
        rows = [r for r in runs if r["comparison"] == name]
        metrics = {}
        for field in ("elapsed_us", "peak_rss_kib", "process_wall_seconds", "validated_wall_seconds"):
            sides = {route: [r[field] for r in rows if r["route"] == route]
                     for route in ("old", candidate)}
            metrics[field] = {"median": {route: statistics.median(xs) for route, xs in sides.items()},
                              "range": {route: [min(xs), max(xs)] for route, xs in sides.items()}}
        paired, blocks = [], []
        for pair in range(pairs):
            block = sorted((r for r in rows if r["pair"] == pair), key=lambda r: r["abba_position"])
            require(len(block) == 4, "incomplete ABBA block")
            paired.extend([block[0]["elapsed_us"] / block[1]["elapsed_us"],
                           block[3]["elapsed_us"] / block[2]["elapsed_us"]])
            blocks.append(statistics.median([block[0]["elapsed_us"], block[3]["elapsed_us"]]) /
                          statistics.median([block[1]["elapsed_us"], block[2]["elapsed_us"]]))
        result[name] = {"case": case, "candidate": candidate, "run_count": len(rows),
                        "metrics": metrics, "elapsed_old_over_candidate_paired_ratios": paired,
                        "elapsed_old_over_candidate_paired_ratio_median": statistics.median(paired),
                        "elapsed_old_over_candidate_block_ratios": blocks,
                        "elapsed_old_over_candidate_block_ratio_median": statistics.median(blocks)}
    return result


def verify(path):
    data = path.read_bytes()
    if path.suffix == ".gz":
        data = gzip.decompress(data)
    report = json.loads(data)
    require(report["schema"] == SCHEMA and report["status"] == "complete", "incomplete/wrong-schema evidence")
    require(report["all_outputs_checked"] is True, "evidence did not check every output")
    pairs = report["pairs"]
    plan = list(protocol_plan(pairs))
    require(report["cohorts"] == CASES, "cohort schedule differs from this independent oracle")
    require(report["planned_processes"] == len(plan) == len(report["runs"]), "wrong process count")
    require(report["maximum_processes"] == MAX_PROCESSES and len(plan) <= MAX_PROCESSES,
            "process budget mismatch")
    require(report["timeout_seconds"] == TIMEOUT_SECONDS, "timeout differs from fixed protocol")
    require(report["comparison_order"] == [f"{c}:old-vs-{r}" for c, r in COMPARISONS], "comparison order differs")
    require(report["environment"]["affinity"] == [4], "measurement CPU differs")
    sources = report["source_snapshot"]
    archived = json.loads(unpacked(sources["files"]))
    require({name: sha(value.encode()) for name, value in archived.items()} == sources["sha256"],
            "archived dependency source hashes differ")
    manifest = json.dumps(sources["sha256"], sort_keys=True, separators=(",", ":")).encode()
    require(sha(manifest) == sources["manifest_sha256"], "dependency manifest hash differs")
    require("tools/construction-bench.py" in archived and "src/cmd/constructionbench/main.mbt" in archived,
            "archived harness/benchmark source is missing")
    require(re.fullmatch(r"[0-9a-f]{40}", report["environment"]["git_revision"]) is not None,
            "invalid Git revision")
    executable = report["executable"]
    require(re.fullmatch(r"[0-9a-f]{64}", executable["sha256_before"]) is not None,
            "invalid executable digest")
    require(executable["sha256_before"] == executable["sha256_after"], "executable was not frozen")
    live_executable = Path(executable["path"])
    live_status = "not retained; archived source and recorded frozen ELF digest checked"
    if live_executable.exists():
        require(live_executable.stat().st_size == executable["bytes"] and
                sha(live_executable.read_bytes()) == executable["sha256_before"], "retained executable hash differs")
        live_status = "retained executable bytes/hash checked"
    references = {case: expected_outputs(case) for case in CASES}
    for index, (row, spec) in enumerate(zip(report["runs"], plan)):
        require(row["index"] == index and all(row[key] == value for key, value in spec.items()),
                "raw run ordering/specification differs")
        require(row["exit_code"] == 0, "failed process in complete evidence")
        elapsed = check_output(unpacked(row["stdout"]), row["case"], row["route"], references[row["case"]])
        require(row["elapsed_us"] == elapsed, "stored internal time differs from raw stdout")
        require(row["outputs_checked"] == len(references[row["case"]]), "checked-output count differs")
        require(type(row["peak_rss_kib"]) is int and row["peak_rss_kib"] > 0 and
                row["peak_rss_raw"] == str(row["peak_rss_kib"]), "invalid raw RSS sample")
        for key in ("process_wall_seconds", "validated_wall_seconds", "validation_seconds"):
            require(type(row[key]) in (int, float) and math.isfinite(row[key]) and row[key] >= 0,
                    "invalid process/validation wall sample")
        require(row["process_wall_seconds"] > 0 and
                math.isclose(row["validated_wall_seconds"], row["process_wall_seconds"] + row["validation_seconds"],
                             rel_tol=1e-12, abs_tol=1e-9), "wall scopes do not reconcile")
        require(row["elapsed_us"] <= row["process_wall_seconds"] * 1e6,
                "internal time exceeds full process wall time")
        require(row["argv"][:3] == ["/usr/bin/time", "-f", "%M"] and
                row["argv"][3] == "-o" and row["argv"][5:] == [executable["path"], row["case"], row["route"]],
                "raw command differs from measured GNU time invocation")
    require(report["summary"] == summarize(report["runs"], pairs), "stored ratios/medians/ranges differ")
    print(f"Verified {len(plan)} complete process outputs and RSS/time summaries; {live_status}.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verify", type=Path, required=True, metavar="REPORT")
    verify(parser.parse_args().verify)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError) as error:
        print(f"construction-bench: {error}", file=sys.stderr)
        sys.exit(1)
