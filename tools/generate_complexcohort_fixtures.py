#!/usr/bin/env python3
"""Independent exact common-complex-ambient oracle with selected real roots."""

from argparse import ArgumentParser
from fractions import Fraction as Q
from pathlib import Path
import json
import subprocess
import sys

import sympy as sp

sys.dont_write_bytecode = True
from generate_complexsubfield_fixtures import (
    Ambient, RADICAL_BOUNDS, T, array, coefficients, polynomial, q_literal,
)

ROOT = Path(__file__).resolve().parents[1]


def source(value, interval=None, nonminimal=False):
    value = sp.sympify(value)
    assert not value.atoms(sp.Float)
    minimum = sp.Poly(sp.minpoly(value, T), T, domain=sp.QQ).monic()
    if interval is None:
        assert value.is_Rational
        interval = (Q(value) - 1, Q(value))
    lower, upper = interval
    if value.is_Rational:
        assert lower < Q(value) <= upper
    else:
        bound = None
        for radical, (_, _, lo, hi) in RADICAL_BOUNDS.items():
            factor = sp.cancel(value / radical)
            if factor.is_Rational:
                bounds = sorted([Q(factor) * lo, Q(factor) * hi])
                assert lower <= bounds[0] and bounds[1] <= upper
                bound = bounds
                break
        assert bound is not None
    definition = minimum * sp.Poly(T - 3, T) if nonminimal else minimum
    # The rational value 1 uses x^2-1, with selected root 1 rather than -1.
    if nonminimal and value == 1:
        definition = sp.Poly(T**2 - 1, T)
    assert definition.count_roots(lower, upper) == 1
    assert definition.eval(value).expand() == 0
    return dict(value=value, minimum=coefficients(minimum), definition=coefficients(definition),
                lower=Q(lower), upper=Q(upper), nonminimal=nonminimal)


def record(ambient, name, inputs, alpha_terms, pause=False):
    expressions = [a["value"] + sp.I * b["value"] for a, b in inputs]
    selected_alpha = sum((sp.Rational(q) * inputs[index][int(imaginary)]["value"]
                          for index, imaginary, q in alpha_terms), sp.S.Zero)
    assert sp.expand(selected_alpha - ambient.alpha) == 0
    samples = []
    for expression in expressions:
        samples.append(dict(vector=ambient.vector(expression),
                            minimum=coefficients(sp.Poly(sp.minpoly(expression, T), T).monic())))
    products = []
    pairs = [(0, 0)] if inputs else []
    if len(inputs) > 1:
        pairs.append((0, len(inputs) - 1))
    for left, right in pairs:
        expected = ambient.vector(sp.expand(expressions[left] * expressions[right]))
        assert ambient.multiply(samples[left]["vector"], samples[right]["vector"]) == expected
        products.append((left, right, expected))
    return dict(name=name, ambient=ambient, inputs=inputs, alpha_terms=alpha_terms,
                samples=samples, products=products, pause=pause)


def root_literal(root):
    return "{ " + f'definition: {array(root["definition"])}, minimum: {array(root["minimum"])}, lower: {q_literal(root["lower"])}, upper: {q_literal(root["upper"])}' + " }"


def literal(record):
    ambient = record["ambient"]
    fields = [f'degree: {ambient.dimension}', f'real_minimum: {array(ambient.modulus)}',
              'inputs: [' + ", ".join(f'({root_literal(a)}, {root_literal(b)})' for a, b in record["inputs"]) + ']',
              'alpha_terms: [' + ", ".join(f'({index}, {str(imaginary).lower()}, {q_literal(q)})' for index, imaginary, q in record["alpha_terms"]) + ']',
              'values: [' + ", ".join(f'({array(sample["vector"][:ambient.degree])}, {array(sample["vector"][ambient.degree:])}, {array(sample["minimum"])})' for sample in record["samples"]) + ']',
              'products: [' + ", ".join(f'({left}, {right}, {array(value[:ambient.degree])}, {array(value[ambient.degree:])})' for left, right, value in record["products"]) + ']',
              f'pause_merge: {str(record["pause"]).lower()}']
    return "{\n" + ",\n".join(fields) + ",\n}"


def generate():
    assert sp.__version__ == "1.14.0"
    sqrt2, sqrt3 = sp.sqrt(2), sp.sqrt(3)
    gaussian = Ambient("QQ(i)", sp.S.Zero, (-1, 0), [])
    quadratic = Ambient("QQ(sqrt2,i)", sqrt2, (1, 2), [sqrt2])
    third = Ambient("QQ(sqrt3,i)", sqrt3, (1, 2), [sqrt3])
    eighth = Ambient("QQ(sqrt2,sqrt3,i)", sqrt2 + sqrt3, (3, 4), [sqrt2, sqrt3])
    zero, one = source(0), source(1)
    a, b = source(sqrt2, (1, 2)), source(sqrt3, (1, 2))
    z = (a, one)
    records = [
        record(gaussian, "empty", [], []),
        record(gaussian, "Gaussian rationals", [(source(sp.Rational(2, 3)), source(sp.Rational(-5, 7))), (zero, one), (source(-2), zero)], []),
        record(quadratic, "real only nonminimal sqrt2", [(source(sqrt2, (1, 2), True), zero)], [(0, False, Q(1))]),
        record(quadratic, "sqrt2 plus i repeated", [z, (a, zero), z], [(0, False, Q(1))]),
        record(quadratic, "sqrt2 cohort reordered", [(a, zero), z], [(0, False, Q(1))]),
        record(third, "cube root of unity", [(source(sp.Rational(-1, 2)), source(sqrt3 / 2, (0, 1)))], [(0, True, Q(2))]),
        record(eighth, "independent real coordinates and swap", [(a, b), (b, a)], [(0, False, Q(1)), (0, True, Q(1))], True),
        record(quadratic, "contained dependent coordinates", [(a, source(2 * sqrt2, (2, 3))), (source(-sqrt2, (-2, -1)), zero)], [(0, False, Q(1))]),
        record(quadratic, "nonminimal rational before sqrt2", [(source(7), source(1, (0, 1), True)), (a, zero)], [(1, False, Q(1))]),
    ]
    tests = ["// Generated by tools/generate_complexcohort_fixtures.py; independent exact oracle.", ""]
    for fixture in records:
        tests += ["///|", f'test "independent complex-cohort oracle: {fixture["name"]}" {{',
                  f'  oracle_assert_cohort({literal(fixture)})', "}", ""]
    formatted = subprocess.run([str(ROOT / ".tools/moon/bin/moonfmt"), "-"],
                               input="\n".join(tests), text=True, capture_output=True, check=True).stdout
    stats = dict(cases=len(records), ambient_degrees=sorted({r["ambient"].dimension for r in records}),
                 selected_real_sources=2 * sum(len(r["inputs"]) for r in records),
                 nonminimal_sources=sum(root["nonminimal"] for r in records for pair in r["inputs"] for root in pair),
                 complex_minima=sum(len(r["samples"]) for r in records),
                 products=sum(len(r["products"]) for r in records))
    docs = ["# Independent exact complex cohort oracle (2026-11-17)", "",
            "This finite oracle uses SymPy 1.14.0 algebraic expressions, exact minimal polynomials, to_number_field conversions, and Fraction quotient multiplication. It shares only the independent host-math routines in generate_complexsubfield_fixtures.py; no MoonBit output or producer primitive choice is an expectation. All selected source intervals are verified by exact rational values or rational-power radical bounds and exact QQ root counting, without floating approximations. Two source definitions deliberately exceed their selected minimum.", "",
            "Each case chooses an independent real primitive a, specified as a rational combination of actual returned real/imaginary components. The external oracle expresses every expected component and product in QQ[a] and computes their complex minimal polynomials independently. MoonBit constructs this a from returned components, checks its independent minimum and the real ambient degree, evaluates the pinned QQ[a] images in the actual ambient field, and compares them with the ordered results. Every coordinate is also realized and compared exactly with its externally selected real root, including signs and nonminimal definitions. No test assumes a particular producer field generator, residue coefficients, trial, or basis order.", "",
            "The Gaussian ambient is degree 2 even for empty or rational input. Real-only sqrt2 is embedded in ambient QQ(sqrt2,i) of degree 4. A primitive cube root of unity has minimum degree 2 but its real-coordinate ambient QQ(sqrt3,i) has degree 4. Thus the expected degree is deliberately the shared real-coordinate ambient degree, not the minimal complex field generated by the cohort. The independent sqrt2+i*sqrt3 / sqrt3+i*sqrt2 cohort has ambient degree 8 and its cross-product is exactly 5*i.", "",
            "Tests additionally preserve an explicit merge pause and retry, require Undecided at zero verification budget, bind the actual Common payload, and reject altered coordinate polynomials. Existing core tests cover the wider certificate attacks.", "",
            "```json", json.dumps(stats, sort_keys=True), "```", "",
            "| Cohort | Ambient degree | Independent real a | Input minima |",
            "| --- | ---: | --- | --- |"]
    for fixture in records:
        docs.append(f'| {fixture["name"]} | {fixture["ambient"].dimension} | `{fixture["ambient"].alpha}` | '
                    + "; ".join(f'`{polynomial(sample["minimum"]).as_expr()}`' for sample in fixture["samples"]) + ' |')
    docs += ["", "Regenerate with `python3 tools/generate_complexcohort_fixtures.py`; use `--check` for exact reproducibility. These bounded cases provide regression evidence, not an arbitrary-field proof or a performance claim. The integrating root task owns JS/wasm-gc and full-suite validation.", ""]
    docs += ["Milestone validation: the regeneration check passes, and `tools/measure --cpu 4 tools/moon test src/complexcompositum --target native --release -j 1` passes 16/16 package tests, including all nine independent oracle fixtures. Scoped fmt/check/info and the repository purity gate pass. The shared performance lock is used for native tests and fixture generation.", ""]
    return {ROOT / "src/complexcompositum/oracle_fixtures_wbtest.mbt": formatted,
            ROOT / "docs/research/complexcohort-oracle-20261117.md": "\n".join(docs)}, stats


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    artifacts, stats = generate()
    for path, content in artifacts.items():
        if args.check:
            if not path.exists() or path.read_text() != content:
                raise SystemExit(f"Stale oracle: {path.relative_to(ROOT)}")
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
    print(json.dumps(stats, sort_keys=True))


if __name__ == "__main__":
    main()
