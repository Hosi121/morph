#!/usr/bin/env python3
"""Freeze reproducible baseline/candidate permutation benchmark artifacts.

Baseline production tensor source is restored from 1931625 only during its
scoped build. The final canonical benchmark and tests remain identical. The
candidate files are restored in finally, including when the build fails.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tarfile

BASELINE = "193162547171f36b694e6b6e70c128ddc0b1ef14"
ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "docs/measurements/tensor-kernel-20261118"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("side", choices=("baseline", "candidate"))
    args = parser.parse_args()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    saved = {name: (ROOT / name).read_bytes() for name in
             ("src/tensor/tensor.mbt", "src/tensor/permutation.mbt")}
    try:
        if args.side == "baseline":
            (ROOT / "src/tensor/tensor.mbt").write_bytes(subprocess.check_output(
                ["git", "show", BASELINE + ":src/tensor/tensor.mbt"], cwd=ROOT))
            (ROOT / "src/tensor/permutation.mbt").unlink()
        command = ["tools/measure", "--cpu", "4", "tools/moon", "build",
                   "src/cmd/tensorbench", "--target", "native", "--release",
                   "--deny-warn", "-j", "1"]
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
        (OUTPUT / (args.side + "-build.txt")).write_text(result.stdout + result.stderr)
        print(result.stdout + result.stderr, end="", flush=True)
        result.check_returncode()
        artifact = ROOT / "_build/native/release/build/cmd/tensorbench/tensorbench.exe"
        shutil.copy2(artifact, OUTPUT / (args.side + ".exe"))
        files = sorted([ROOT / "moon.mod", ROOT / "tools/moon"] +
            list((ROOT / "src").rglob("*.mbt")) + list((ROOT / "src").rglob("moon.pkg")))
        with tarfile.open(OUTPUT / (args.side + "-source.tar.gz"), "w:gz") as archive:
            for path in files:
                archive.add(path, arcname=path.relative_to(ROOT))
        record = dict(baseline_commit=BASELINE,
            branch_commit=subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
            compiler=subprocess.check_output([str(ROOT / "tools/moon"), "version", "--all"], cwd=ROOT, text=True),
            files={str(path.relative_to(ROOT)): sha(path) for path in files},
            artifact_sha256=sha(artifact), build_command=command)
        (OUTPUT / (args.side + "-provenance.json")).write_text(json.dumps(record, indent=2) + "\n")
    finally:
        for name, contents in saved.items():
            (ROOT / name).write_bytes(contents)


if __name__ == "__main__":
    main()
