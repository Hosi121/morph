#!/usr/bin/env python3
"""Five frozen ABBA blocks for prebuilt tensor permutation kernels.

Run under tools/measure --cpu 4. Every run checks complete independently derived
shape and entry arrays. Process duration includes setup, all iterations, exact
checks, startup and output, and excludes compilation.
"""
import argparse
import hashlib
import itertools
import json
import os
from pathlib import Path
import platform
import statistics
import subprocess
import time

CASES = {
    "permute-scalar": ([], [], 10000),
    "permute-zero": ([3, 0, 5], [2, 0, 1], 10000),
    "permute-tiny": ([2, 3], [1, 0], 10000),
    "permute-rect": ([3, 4, 5], [2, 0, 1], 3000),
    "permute-rank5": ([3, 3, 3, 3, 3], [4, 2, 0, 3, 1], 500),
    "permute-identity": ([3, 4, 5], [0, 1, 2], 3000),
}


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def expected(case):
    dimensions, order, iterations = CASES[case]
    output_shape = [dimensions[axis] for axis in order]
    entries = []
    for coordinates in itertools.product(*(range(n) for n in output_shape)):
        original = [0] * len(dimensions)
        for axis, coordinate in zip(order, coordinates):
            original[axis] = coordinate
        offset = 0
        for size, coordinate in zip(dimensions, original):
            offset = offset * size + coordinate
        entries.append(offset - 7)
    return dict(case=case, iterations=iterations, shape=output_shape,
                entries=entries, checked=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--candidate", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    artifacts = {side: getattr(args, side).resolve(strict=True)
                 for side in ("baseline", "candidate")}
    hashes = {side: sha(path) for side, path in artifacts.items()}
    provenance = {side: json.loads(path.with_name(side + "-provenance.json").read_text())
                  for side, path in artifacts.items()}
    assert provenance["baseline"]["compiler"] == provenance["candidate"]["compiler"]
    for side in artifacts:
        assert hashes[side] == provenance[side]["artifact_sha256"]
    for name in ("src/cmd/tensorbench/main.mbt", "src/cmd/tensorbench/moon.pkg"):
        assert provenance["baseline"]["files"][name] == provenance["candidate"]["files"][name]
    report = dict(schema=1, script_sha256=sha(__file__), provenance_sha256={
        side: sha(path.with_name(side + "-provenance.json")) for side, path in artifacts.items()}, artifacts={
        side: dict(path=str(path), sha256=hashes[side])
        for side, path in artifacts.items()}, platform=platform.platform(),
        affinity=sorted(os.sched_getaffinity(0)), blocks=5,
        order=["baseline", "candidate", "candidate", "baseline"],
        timing="complete native process, compilation excluded",
        oracle="independent Python mixed-radix coordinate and complete output arrays",
        cases=CASES, rows=[], summary={}, all_checked=False)

    def save():
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(report, indent=2) + "\n")

    try:
        for case in CASES:
            wanted = expected(case)
            for block in range(5):
                for position, side in enumerate(report["order"]):
                    start = time.perf_counter_ns()
                    process = subprocess.run([str(artifacts[side]), case],
                        capture_output=True, text=True, timeout=60)
                    elapsed = time.perf_counter_ns() - start
                    payload = json.loads(process.stdout)
                    checked = process.returncode == 0 and payload == wanted
                    report["rows"].append(dict(case=case, block=block,
                        position=position, side=side, process_ns=elapsed,
                        full_checked=checked, payload=payload,
                        stdout=process.stdout, stderr=process.stderr,
                        exit_code=process.returncode))
                    save()
                    if not checked:
                        raise ValueError("full permutation output differs: " + case)
            rows = [r for r in report["rows"] if r["case"] == case]
            medians = {s: statistics.median(r["process_ns"] for r in rows if r["side"] == s)
                       for s in artifacts}
            ratios = []
            for block in range(5):
                values = {s: statistics.median(r["process_ns"] for r in rows
                    if r["side"] == s and r["block"] == block) for s in artifacts}
                ratios.append(values["baseline"] / values["candidate"])
            report["summary"][case] = dict(median_ns=medians,
                before_over_after=medians["baseline"] / medians["candidate"],
                block_ratios=ratios, positive_blocks=sum(r > 1 for r in ratios),
                ranges_ns={s: [min(r["process_ns"] for r in rows if r["side"] == s),
                               max(r["process_ns"] for r in rows if r["side"] == s)]
                           for s in artifacts})
            print(case, json.dumps(report["summary"][case]), flush=True)
            save()
        assert hashes == {side: sha(path) for side, path in artifacts.items()}
        report["all_checked"] = all(row["full_checked"] for row in report["rows"])
    except BaseException as error:
        report["error"] = str(error)
        raise
    finally:
        save()


if __name__ == "__main__":
    main()
