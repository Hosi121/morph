#!/usr/bin/env python3
"""Install a pinned Lean proof checker locally; no global elan or Mathlib."""
from pathlib import Path
from zipfile import ZipFile
import hashlib
import os
import shutil
import stat
import urllib.request

ROOT = Path(__file__).resolve().parent.parent
VERSION = "4.19.0"
SHA256 = "4e09ca16ff782f51f58b409e7bf983591a3fa17b85aa18d56feddca4398b7f29"
ARCHIVE = ROOT / ".tools" / f"lean-{VERSION}-linux.zip"
DESTINATION = ROOT / ".tools/lean"
URL = f"https://github.com/leanprover/lean4/releases/download/v{VERSION}/lean-{VERSION}-linux.zip"


def main():
    if os.uname().machine != "x86_64" or os.uname().sysname != "Linux":
        raise SystemExit("This pinned bootstrap targets Linux x86_64.")
    marker = DESTINATION / "VERSION"
    if (marker.exists() and f"SHA256 {SHA256}" in marker.read_text()
            and (DESTINATION / "bin/lean").is_file()
            and (DESTINATION / "lib/lean/Std/Tactic.olean").is_file()):
        print(f"Lean {VERSION} is already installed under {DESTINATION}")
        return
    ARCHIVE.parent.mkdir(parents=True, exist_ok=True)
    if not ARCHIVE.exists():
        print(f"Downloading {URL}", flush=True)
        with urllib.request.urlopen(URL, timeout=240) as response, ARCHIVE.open("wb") as output:
            shutil.copyfileobj(response, output)
    with ARCHIVE.open("rb") as source:
        actual = hashlib.file_digest(source, "sha256").hexdigest()
    if actual != SHA256:
        raise SystemExit(f"Lean archive checksum mismatch: {actual}")
    DESTINATION.mkdir(parents=True, exist_ok=True)
    with ZipFile(ARCHIVE) as archive:
        for info in archive.infolist():
            relative = Path(info.filename).relative_to(f"lean-{VERSION}-linux")
            if not relative.parts or ".." in relative.parts or relative.is_absolute():
                continue
            selected = str(relative) == "bin/lean" or (
                relative.parts[0] == "lib" and
                (relative.suffix == ".olean" or ".so" in relative.name))
            if not selected or info.is_dir():
                continue
            target = DESTINATION / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            mode = info.external_attr >> 16
            if stat.S_ISLNK(mode):
                link = archive.read(info).decode()
                if not (target.parent / link).resolve().is_relative_to(DESTINATION.resolve()):
                    raise SystemExit(f"Unexpected external symlink: {relative}")
                if not target.exists() and not target.is_symlink():
                    target.symlink_to(link)
            else:
                with archive.open(info) as source, target.open("wb") as output:
                    shutil.copyfileobj(source, output)
                target.chmod(0o755 if str(relative) == "bin/lean" else 0o644)
    (DESTINATION / "VERSION").write_text(f"Lean {VERSION}\nSHA256 {SHA256}\n{URL}\n")
    print(f"Installed Lean {VERSION} under {DESTINATION}")


if __name__ == "__main__":
    main()
