#!/usr/bin/env python3
"""Regenerate MoonBit interfaces and reject stale committed API snapshots.

The compiler owns .mbti syntax. Changed files are left generated for review.
This checks drift, not compatibility with an earlier release.
"""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent


def snapshot():
    return {p.relative_to(ROOT): p.read_bytes()
            for p in (ROOT / "src").rglob("pkg.generated.mbti")}


def main():
    before = snapshot()
    result = subprocess.run([str(ROOT / "tools/moon"), "info"], cwd=ROOT)
    if result.returncode:
        return result.returncode
    after = snapshot()
    changed = sorted(p for p in before.keys() | after.keys()
                     if before.get(p) != after.get(p))
    if changed:
        print("Generated interfaces were stale; review the regenerated files:", file=sys.stderr)
        for path in changed:
            print(f"  {path}", file=sys.stderr)
        return 1
    print(f"Interface drift gate passed: {len(after)} compiler-generated snapshots.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
