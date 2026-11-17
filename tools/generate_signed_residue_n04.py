#!/usr/bin/env python3
"""Independent integer oracle for N04 signed_reduce; --check detects fixture drift."""
from argparse import ArgumentParser
from pathlib import Path
import json


def fixtures():
    large = int("f123456789abcdef" * 4, 16)
    pairs = [(2,-1),(2,-2),(17,-16),(17,-17),(17,-18),
             (65537,-65536),(65537,-65537),(65537,-65538),
             (65537,-large),(65537,large),(2**127-1,-large),
             (2**255-19,-(2**1024-1)),(2**255-19,2**1024-1)]
    return [{"modulus_hex": format(m,"x"), "negative": a<0,
             "magnitude_hex": format(abs(a),"x"),
             "residue_hex": format(a%m,"x")} for m,a in pairs]


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    text = json.dumps(fixtures(), indent=2) + "\n"
    if args.check:
        if not args.output.is_file() or args.output.read_text() != text:
            raise SystemExit("N04 Python fixture drift: " + str(args.output))
    else:
        args.output.parent.mkdir(parents=True,exist_ok=True)
        args.output.write_text(text)


if __name__ == "__main__":
    main()
