#!/usr/bin/env python3
"""Independent Fraction finite-domain oracle for scoped prenex normalization.

The Python interpreter visits the original local-binder tree only; it neither
normalizes the formula nor calls the MoonBit implementation. Nonempty finite
domains validate syntax transformations, not real-closed-field QE semantics.
"""

from __future__ import annotations

import argparse
from fractions import Fraction
from functools import reduce
import itertools
import json
from pathlib import Path
import random
import re


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "src/realformula/generated_fixtures_wbtest.mbt"
MANIFEST = ROOT / "docs/measurements/realformula-fixtures-20261116.json"
RELATIONS = ["LessZero", "AtMostZero", "EqualZero", "NotZero", "AtLeastZero", "GreaterZero"]
DOMAINS = [(-1, 0, 1), (0, 1), (-2, -1), (0,)]


def atom(arity, terms, relation):
    return ("Atom", arity, tuple((Fraction(c), tuple(e)) for c, e in terms), relation)


def evaluate(formula, values, domain):
    op, *args = formula
    if op == "Truth":
        return args[0]
    if op == "Atom":
        arity, terms, relation = args
        assert len(values) == arity
        value = sum((coefficient * reduce(
            lambda x, y: x * y,
            (Fraction(x) ** e for x, e in zip(values, exponents)),
            Fraction(1),
        ) for coefficient, exponents in terms), Fraction(0))
        return {
            "LessZero": value < 0,
            "AtMostZero": value <= 0,
            "EqualZero": value == 0,
            "NotZero": value != 0,
            "AtLeastZero": value >= 0,
            "GreaterZero": value > 0,
        }[relation]
    if op == "Negation":
        return not evaluate(args[0], values, domain)
    if op == "Conjunction":
        return evaluate(args[0], values, domain) and evaluate(args[1], values, domain)
    if op == "Disjunction":
        return evaluate(args[0], values, domain) or evaluate(args[1], values, domain)
    if op == "Exists":
        return any(evaluate(args[0], (*values, x), domain) for x in domain)
    if op == "Forall":
        return all(evaluate(args[0], (*values, x), domain) for x in domain)
    raise AssertionError(op)


def render(formula):
    op, *args = formula
    if op == "Truth":
        return "Truth(" + str(args[0]).lower() + ")"
    if op == "Atom":
        arity, terms, relation = args
        term_text = ", ".join(f"({c.numerator}, {c.denominator}, {list(e)})" for c, e in terms)
        return f"Atom(test_polynomial({arity}, [{term_text}]), {relation})"
    return f"{op}(" + ", ".join(render(arg) for arg in args) + ")"


def binder_count(formula):
    op, *args = formula
    if op in ("Truth", "Atom"):
        return 0
    return (1 if op in ("Exists", "Forall") else 0) + sum(map(binder_count, args))


def random_formula(rng, arity, depth):
    if depth == 0 or rng.randrange(5) == 0:
        if rng.randrange(6) == 0:
            return ("Truth", bool(rng.randrange(2)))
        terms = [(Fraction(rng.choice([-3, -2, -1, 1, 2, 3]), rng.choice([1, 2, 3])),
                  tuple(rng.randrange(3) for _ in range(arity)))
                 for _ in range(rng.randrange(5))]
        return atom(arity, terms, rng.choice(RELATIONS))
    op = rng.choice(["Negation", "Conjunction", "Disjunction", "Exists", "Forall"])
    if op in ("Conjunction", "Disjunction"):
        return (op, random_formula(rng, arity, depth - 1), random_formula(rng, arity, depth - 1))
    return (op, random_formula(rng, arity + (op in ("Exists", "Forall")), depth - 1))


def fixtures():
    eq = atom(2, [(1, (1, 0)), (-1, (0, 1))], "EqualZero")
    ne = atom(2, [(1, (1, 0)), (-1, (0, 1))], "NotZero")
    cases = [
        (0, ("Forall", ("Exists", eq))),
        (0, ("Exists", ("Forall", eq))),
        (1, ("Conjunction", ("Exists", eq), ("Exists", ne))),
        (1, ("Conjunction", ("Exists", eq), ("Forall", ne))),
        (1, ("Negation", ("Disjunction", ("Exists", eq), ("Forall", ne)))),
        (0, ("Negation", ("Forall", ("Exists", ("Negation", eq))))),
        (0, ("Conjunction", ("Exists", ("Truth", True)), ("Forall", ("Truth", False)))),
        (2, ("Forall", ("Negation", ("Exists", ("Truth", False))))),
        (0, ("Forall", ("Exists", ("Forall", atom(3, [(1, (1, 0, 1)), (-1, (0, 1, 1))], "EqualZero"))))),
        (0, ("Exists", ("Forall", ("Exists", atom(3, [(1, (1, 0, 0)), (-1, (0, 1, 0)), (-1, (0, 0, 1))], "EqualZero"))))),
    ]
    for relation in RELATIONS:
        cases.append((0, ("Negation", atom(0, [(Fraction(-1, 2), ())], relation))))
        cases.append((1, ("Negation", ("Exists", atom(2, [(Fraction(-2, 3), (2, 0)), (Fraction(1, 2), (0, 2))], relation)))))
    deep_terms = [(1 if index % 2 == 0 else -1,
                   tuple(int(index == slot) for slot in range(9)))
                  for index in range(9)]
    deep = atom(9, deep_terms, "AtLeastZero")
    for quantifier in reversed(["Forall", "Exists", "Forall", "Exists", "Forall", "Exists", "Forall"]):
        deep = (quantifier, deep)
    cases.append((2, deep))
    siblings = [("Exists", atom(2, [(1, (0, 1)), (-offset, (1, 0))], "EqualZero"))
                for offset in (1, 2, 3, 4)]
    cases.append((1, ("Disjunction", ("Conjunction", *siblings[:2]), ("Conjunction", *siblings[2:]))))
    rng = random.Random(20261116)
    for index in range(80):
        free_count = index % 3
        cases.append((free_count, random_formula(rng, free_count, 4)))
    return cases


def generate():
    cases = fixtures()
    lines = ["// Generated by tools/generate_realformula_fixtures.py; do not edit.",
             "// Exact Python Fraction expectations interpret only the original scoped tree.", ""]
    assignment_count = 0
    true_count = 0
    for index, (free_count, formula) in enumerate(cases):
        lines += ["///|", f'test "independent finite-domain fixture {index:03d}" {{',
                  f"  let formula : Formula = {render(formula)}"]
        for domain in DOMAINS:
            expected = [evaluate(formula, values, domain)
                        for values in itertools.product(domain, repeat=free_count)]
            assignment_count += len(expected)
            true_count += sum(expected)
            expected_text = "[" + ", ".join(str(v).lower() for v in expected) + "]"
            lines.append(f"  check_generated_fixture({free_count}, {list(domain)}, formula, {expected_text})")
        lines += ["}", ""]
    manifest = {
        "generator": "tools/generate_realformula_fixtures.py",
        "seed": 20261116,
        "oracle": "Python Fraction direct original-tree interpreter; MoonBit independently interprets source and prenex",
        "scope": "Nonempty finite-domain syntactic-normalization validation; not RCF quantifier-elimination proof",
        "fixtures": len(cases),
        "domains": list(map(list, DOMAINS)),
        "free_assignments": assignment_count,
        "true_assignments": true_count,
        "false_assignments": assignment_count - true_count,
        "maximum_prefix_binders": max(binder_count(formula) for _, formula in cases),
    }
    return {OUTPUT: "\n".join(lines), MANIFEST: json.dumps(manifest, indent=2) + "\n"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    for path, text in generate().items():
        if args.check:
            def tokens(source):
                source = re.sub(r",\s*([\]\)])", r"\1", source)
                return re.findall(r'"(?:\\.|[^"\\])*"|\S', source)
            matches = path.exists() and (
                tokens(path.read_text()) == tokens(text) if path.suffix == ".mbt"
                else path.read_text() == text
            )
            if not matches:
                raise SystemExit(f"stale generated fixture: {path.relative_to(ROOT)}")
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text)
    print("realformula finite-domain fixtures are current")


if __name__ == "__main__":
    main()
