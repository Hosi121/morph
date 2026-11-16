#!/usr/bin/env python3
"""Compare native exact complex algebra routes, keeping timeout censoring.

Run under tools/measure --cpu N. Each route includes exact input preparation,
computation and result checks. A timeout is never a solved result.
"""
from argparse import ArgumentParser
from datetime import datetime, timezone
from pathlib import Path
import hashlib
import json
import os
import platform
import statistics
import subprocess
import time


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("--artifact", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--case", choices=["complex-roots", "field-power", "field-square"], default="complex-roots")
    parser.add_argument("--abba-repetitions", type=int, default=3)
    parser.add_argument("--timeout-seconds", type=float, default=5.0)
    args = parser.parse_args()
    if args.abba_repetitions < 1 or args.timeout_seconds <= 0:
        parser.error("repetitions and timeout must be positive")
    affinity = sorted(os.sched_getaffinity(0))
    if len(affinity) != 1:
        parser.error("use tools/measure --cpu N so the comparison shares one CPU")
    artifact = args.artifact.resolve(strict=True)
    root = Path(__file__).resolve().parents[1]
    dirty_paths = subprocess.check_output(
        ["git", "diff", "--name-only", "HEAD"], cwd=root, text=True,
    ).splitlines()
    if args.case == "complex-roots":
        modes = ["unfactored-zero", "factored"]
        expected = {"source": "(z^2+1)^2(z-1)", "roots": 3,
                    "multiplicity_sum": 5, "checked": True}
        scope = "process startup, input construction, preparation/factorization, enumeration, final exact checker; excludes compilation"
    else:
        square = args.case == "field-square"
        modes = ["coordinate-square", "field-square"] if square else ["coordinate", "field"]
        expected = {"source": "(sqrt(2)+i)^2" if square else "(sqrt(2)+i)^8", "field_degree": 4,
                    "numeric_equal": True, "checked": True}
        scope = "process startup, shared exact input/field preparation, " + ("one squaring" if square else "three squarings") + ", representation-specific validation/realization and numeric result equality; excludes compilation"
    report = {
        "utc": datetime.now(timezone.utc).isoformat(), "backend": "native",
        "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(),
        "tracked_dirty": bool(subprocess.check_output(["git", "status", "--porcelain", "--untracked-files=no"], cwd=root, text=True).strip()),
        "dirty_paths": dirty_paths,
        "code_dirty": any(path.startswith(("src/", "tools/", "formal/")) or path == "moon.mod"
                          for path in dirty_paths),
        "artifact": str(artifact.relative_to(root)) if artifact.is_relative_to(root) else str(artifact),
        "artifact_sha256": hashlib.sha256(artifact.read_bytes()).hexdigest(),
        "affinity": affinity, "platform": platform.platform(),
        "python": platform.python_version(), "source": expected["source"],
        "case": args.case, "scope": scope,
        "timeout_seconds": args.timeout_seconds, "abba_repetitions": args.abba_repetitions,
        "runs": [], "summary": {},
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)

    def save():
        temporary = args.output.with_suffix(args.output.suffix + ".tmp")
        temporary.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n")
        temporary.replace(args.output)

    for repetition in range(args.abba_repetitions):
        for mode in [modes[0], modes[1], modes[1], modes[0]]:
            started = time.monotonic()
            row = {"repetition": repetition, "mode": mode}
            try:
                result = subprocess.run([str(artifact), mode], cwd=root, text=True,
                                        capture_output=True, timeout=args.timeout_seconds)
                row.update(seconds=time.monotonic()-started, exit_code=result.returncode,
                           censored=False, stdout=result.stdout, stderr=result.stderr)
                try:
                    valid = result.returncode == 0 and json.loads(result.stdout) == expected
                except json.JSONDecodeError:
                    valid = False
                if not valid:
                    report["runs"].append(row)
                    save()
                    raise SystemExit("exact comparison failed; details retained in output")
                row["checked"] = True
            except subprocess.TimeoutExpired:
                row.update(seconds=time.monotonic()-started, censored=True, checked=False)
            report["runs"].append(row)
            save()
            print(json.dumps({key: value for key, value in row.items()
                              if key not in {"stdout", "stderr"}}), flush=True)
    for mode in modes:
        rows = [row for row in report["runs"] if row["mode"] == mode]
        completed = [row["seconds"] for row in rows if not row["censored"]]
        report["summary"][mode] = {
            "completed": len(completed), "censored": len(rows)-len(completed),
            "median_seconds_completed_only": statistics.median(completed) if completed else None,
        }
    save()
    print(json.dumps(report["summary"], indent=2))


if __name__ == "__main__":
    main()
