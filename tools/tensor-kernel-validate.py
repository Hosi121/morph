#!/usr/bin/env python3
"""Run scoped tensor checks serially through the shared measurement lock."""
from pathlib import Path
import hashlib
import json
import subprocess
import time

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "docs/measurements/tensor-kernel-20261118/validation.json"
COMMANDS = [
    ["tools/moon", "check", "src/tensor", "--target", "native", "--deny-warn", "-j", "1"],
    *[["tools/moon", "test", "src/tensor", "--target", target, "--release", "--deny-warn", "-j", "1"]
      for target in ("native", "wasm-gc", "js")],
    ["tools/moon", "info", "src/tensor", "src/cmd/tensorbench", "--target", "native"],
    ["tools/moon", "fmt", "src/tensor", "src/cmd/tensorbench", "--check"],
    ["python3", "tools/audit_purity.py"],
]


def main():
    paths = sorted(list((ROOT / "src").rglob("*.mbt")) +
        list((ROOT / "src").rglob("moon.pkg")) + [ROOT / "moon.mod", ROOT / "tools/moon"] +
        [ROOT / ".tools/moon/bin" / name for name in ("moon", "moonc", "moonrun")])
    source = {str(path.relative_to(ROOT)): hashlib.sha256(path.read_bytes()).hexdigest()
              for path in paths}
    report = json.loads(OUTPUT.read_text()) if OUTPUT.exists() else {}
    if report.get("source_sha256") != source:
        report = dict(commands=[], interfaces_unchanged=False, all_passed=False,
                      source_sha256=source)
    def save():
        OUTPUT.write_text(json.dumps(report, indent=2) + "\n")
    for inner in COMMANDS:
        command = ["tools/measure", "--cpu", "4", *inner]
        if any(r["command"] == command and r["exit_code"] == 0 for r in report["commands"]):
            continue
        start = time.monotonic()
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
        report["commands"].append(dict(command=command, exit_code=result.returncode,
            wall_seconds_including_lock_wait=time.monotonic() - start,
            stdout=result.stdout, stderr=result.stderr))
        save()
        print(" ".join(inner), result.returncode, result.stdout + result.stderr, flush=True)
        result.check_returncode()
    report["interfaces"] = {}
    for name in ("src/tensor/pkg.generated.mbti", "src/cmd/tensorbench/pkg.generated.mbti"):
        original = subprocess.check_output(["git", "show", "1931625:" + name], cwd=ROOT)
        current = (ROOT / name).read_bytes()
        report["interfaces"][name] = dict(unchanged=original == current,
            sha256=hashlib.sha256(current).hexdigest())
    report["interfaces_unchanged"] = all(p["unchanged"] for p in report["interfaces"].values())
    report["all_passed"] = report["interfaces_unchanged"]
    save()
    assert report["all_passed"], "public interface changed"


if __name__ == "__main__":
    main()
