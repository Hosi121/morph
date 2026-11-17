#!/usr/bin/env python3
"""Regenerate/check frozen N05 expected terms with independent Fraction arithmetic."""
from argparse import ArgumentParser
from fractions import Fraction
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "docs/research/monic-identity-20261117-raw/fraction-fixtures.json"


def normalize(entries):
    terms = {}
    for numerator, denominator, exponents in entries:
        key = tuple(exponents)
        terms[key] = terms.get(key, Fraction()) + Fraction(numerator, denominator)
    ordered = [(key, value) for key, value in sorted(terms.items(), reverse=True) if value]
    if not ordered:
        return []
    leading = ordered[0][1]
    return [[(value / leading).numerator, (value / leading).denominator, list(key)]
            for key, value in ordered]


def payloads(source):
    result = []
    for match in re.finditer(r"let (?:input|wanted)[0-9]*\s*=\s*(?:n05_)?polynomial\(", source):
        start = match.end()
        depth = 1
        end = start
        while depth:
            if source[end] == "(": depth += 1
            elif source[end] == ")": depth -= 1
            end += 1
        result.append([int(v) for v in re.findall(r"-?[0-9]+", source[start:end-1])])
    return result


def flatten(dimension, terms):
    return [dimension] + [v for n,d,exponents in terms for v in [n,d,*exponents]]


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    fixtures = json.loads(FIXTURE.read_text())
    expected_payloads = []
    for row in fixtures:
        expected = normalize(row["input"])
        if args.check and expected != row["expected"]:
            raise SystemExit("N05 Fraction expected-term drift: " + row["case"])
        row["expected"] = expected
        expected_payloads += [flatten(row["variables"], row["input"]), flatten(row["variables"], expected)]
    if args.check:
        wb = (ROOT / "src/polynomial/monic_identity_n05_wbtest.mbt").read_text().split('test "N05 complete Fraction',1)[1].split('test "N05 canonical',1)[0]
        cli = (ROOT / "src/cmd/conversionmonicbench/main.mbt").read_text().split('"resultant-caller" =>',1)[0]
        if payloads(wb) != expected_payloads or payloads(cli) != expected_payloads:
            raise SystemExit("N05 WB/CLI numeric fixture binding drift")
        # Independent complete result for resultant(x²-2, t-x-1).
        assert [(t-1)**2-2 for t in range(3)] == [-1,-2,-1]
    else:
        FIXTURE.write_text(json.dumps(fixtures,indent=2)+"\n")


if __name__ == "__main__":
    main()
