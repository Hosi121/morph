#!/usr/bin/env python3
"""Compare untruncated, opt-in complete continuation traces from two saved ELFs."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess


def read_trace(executable: Path, full: bool) -> dict:
    environment = dict(os.environ, MORPH_CDCL_TRACE="full" if full else "1")
    aggregate = hashlib.sha256()
    cases = {}
    recent = []
    frames = byte_count = 0
    process = subprocess.Popen(
        [str(executable), "trace_wbtest.mbt:0-1"],
        env=environment, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    )
    assert process.stdout is not None
    try:
        for line in process.stdout:
            prefix = b"MORPH_CDCL_TRACE:"
            if not line.startswith(prefix):
                recent = (recent + [line.decode(errors="replace")[-1000:]])[-10:]
                continue
            frame = json.loads(line[len(prefix):])
            case = cases.setdefault(frame["case_name"], {"frames": 0, "terminal": False})
            assert not case["terminal"], "frame after terminal state"
            assert frame["step"] == case["frames"], "missing or reordered transition"
            assert frame["kind"] in (["initial"] if frame["step"] == 0 else ["paused", "terminal"])
            assert "..." not in frame["value"], "truncated representation"
            case["frames"] += 1
            case["terminal"] = frame["kind"] == "terminal"
            aggregate.update(line)
            byte_count += len(line)
            frames += 1
        status = process.wait()
    except BaseException:
        process.kill()
        process.wait()
        raise
    if status:
        raise RuntimeError(f"trace process exited {status}: {''.join(recent)}")
    if len(cases) != 6 or not all(case["terminal"] for case in cases.values()):
        raise RuntimeError(f"expected six complete traces, got {cases}: {''.join(recent)}")
    return {"elf": str(executable), "elf_sha256": hashlib.sha256(executable.read_bytes()).hexdigest(),
            "trace_sha256": aggregate.hexdigest(), "frames": frames, "bytes": byte_count, "cases": cases}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("baseline", type=Path)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--full", action="store_true", help="use the larger four-bit trace fixture")
    args = parser.parse_args()
    baseline = read_trace(args.baseline.resolve(), args.full)
    candidate = read_trace(args.candidate.resolve(), args.full)
    equal = all(baseline[key] == candidate[key] for key in ["trace_sha256", "frames", "bytes", "cases"])
    result = {"equal": equal, "baseline": baseline, "candidate": candidate}
    rendered = json.dumps(result, indent=2) + "\n"
    if args.output:
        args.output.write_text(rendered)
    print(rendered, end="")
    if not equal:
        raise SystemExit("complete continuation traces differ")


if __name__ == "__main__":
    main()
