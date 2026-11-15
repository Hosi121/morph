#!/usr/bin/env python3
"""Detect changes to the reviewed MoonBit/Lean correspondence.

Fingerprints are review locks, not a proof of source translation. Run the Lean
checker and review the correspondence before explicitly recording a new lock.
"""
from pathlib import Path
import argparse
import hashlib
import json
import re
import sys

from audit_purity import code_only

ROOT = Path(__file__).resolve().parent.parent
LOCK = ROOT / "formal/source-map.json"
REGIONS = {
    "src/binary/binary.mbt": ["full_adder", "increment_bits", "add_bits", "add", "from_nat"],
    "src/runbinary/runbinary.mbt": ["digit"],
}


def function_tokens(path, name):
    source = code_only(path.read_text())
    match = re.search(r"\b(?:pub\s+)?fn\s+" + re.escape(name) + r"\s*\(", source)
    if not match:
        raise ValueError(f"Missing mapped function: {path}:{name}")
    opening = source.index("{", match.end())
    depth = 1
    position = opening + 1
    while depth and position < len(source):
        depth += (source[position] == "{") - (source[position] == "}")
        position += 1
    if depth:
        raise ValueError(f"Unclosed mapped function: {path}:{name}")
    return re.sub(r"\s+", "", source[match.start():position]).encode()


def snapshot():
    functions = {}
    for relative, names in REGIONS.items():
        for name in names:
            functions[f"{relative}::{name}"] = hashlib.sha256(function_tokens(ROOT / relative, name)).hexdigest()
    return {
        "model": "formal/Binary.lean",
        "model_sha256": hashlib.sha256((ROOT / "formal/Binary.lean").read_bytes()).hexdigest(),
        "lean_version": "4.19.0",
        "functions": functions,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--record", action="store_true", help="record after proof checking and correspondence review")
    args = parser.parse_args()
    current = snapshot()
    if args.record:
        LOCK.write_text(json.dumps(current, indent=2, sort_keys=True) + "\n")
        print("Recorded correspondence lock; this command does not verify translation.")
        return 0
    if not LOCK.exists():
        print("Missing formal source correspondence lock.", file=sys.stderr)
        return 1
    expected = json.loads(LOCK.read_text())
    if current != expected:
        print("Formal model/source drift: review the domain property and the changed correspondence.", file=sys.stderr)
        for name in current["functions"].keys() | expected.get("functions", {}).keys():
            if current["functions"].get(name) != expected.get("functions", {}).get(name):
                print(f"  code-drift: {name}", file=sys.stderr)
        if current["model_sha256"] != expected.get("model_sha256"):
            print("  model-drift: formal/Binary.lean", file=sys.stderr)
        return 1
    print(f"Formal drift gate passed: {len(current['functions'])} reviewed source regions; not a translation proof.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
