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
    "src/core/data.mbt": ["replicate", "replicate_onto", "reverse", "reverse_onto"],
    "src/core/natural.mbt": ["halve_nat", "half_nat"],
    "src/binary/binary.mbt": ["full_adder", "increment_bits", "add_bits", "add", "low_bit", "zero", "one", "from_nat", "compare_bits"],
    "src/binary/from_nat_grouped.mbt": ["split_nat_grouped", "from_nat_grouped"],
    "src/binary/comparison.mbt": ["compare_bits_grouped", "compare_bits_tail"],
    "src/binary/constants.mbt": ["canonical_zero", "canonical_one"],
    "src/runbinary/runbinary.mbt": ["digit"],
    "src/polynomial/evaluation.mbt": ["univariate_power", "univariate_horner", "evaluate"],
    "src/polynomial/polynomial.mbt": ["compare_monomial", "insert", "polynomial", "evaluate_generic"],
}

CONSTANTS = {"src/binary/constants.mbt": ["canonical_zero_value", "canonical_one_value"]}


def function_tokens(path, name):
    source = code_only(path.read_text())
    match = re.search(r"\b(?:pub\s+)?fn(?:\[[^\]]+\])?\s+" + re.escape(name) + r"\s*\(", source)
    if not match:
        raise ValueError(f"Missing mapped function: {path}:{name}")
    # Function attributes affect code generation and must travel with the lock.
    attributes = re.search(r"(?:\#[^\n]*\n\s*)+$", source[:match.start()])
    start = attributes.start() if attributes else match.start()
    return braced_tokens(source, match, name, start=start)


def constant_tokens(path, name):
    source = code_only(path.read_text())
    match = re.search(r"\blet\s+" + re.escape(name) + r"\s*:\s*Binary\s*=\s*", source)
    if not match or not source[match.end():].startswith("{"):
        raise ValueError(f"Missing mapped Binary record constant: {path}:{name}")
    return braced_tokens(source, match, name)


def braced_tokens(source, match, name, start=None):
    opening = source.index("{", match.end())
    depth = 1
    position = opening + 1
    while depth and position < len(source):
        depth += (source[position] == "{") - (source[position] == "}")
        position += 1
    if depth:
        raise ValueError(f"Unclosed mapped declaration: {name}")
    return re.sub(r"\s+", "", source[match.start() if start is None else start:position]).encode()


def snapshot():
    functions = {}
    for relative, names in REGIONS.items():
        for name in names:
            functions[f"{relative}::{name}"] = hashlib.sha256(function_tokens(ROOT / relative, name)).hexdigest()
    for relative, names in CONSTANTS.items():
        for name in names:
            functions[f"{relative}::{name}"] = hashlib.sha256(constant_tokens(ROOT / relative, name)).hexdigest()
    return {
        "models": {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                   for p in sorted((ROOT / "formal").rglob("*.lean"))},
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
        for name in current["models"].keys() | expected.get("models", {}).keys():
            if current["models"].get(name) != expected.get("models", {}).get(name):
                print(f"  model-drift: {name}", file=sys.stderr)
        return 1
    print(f"Formal drift gate passed: {len(current['functions'])} reviewed source regions; not a translation proof.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
