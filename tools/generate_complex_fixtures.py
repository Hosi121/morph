#!/usr/bin/env python3
"""Exact, independent complex-root oracle (SymPy 1.14.0 and Fraction).

No producer code, decimal approximations, numerical roots, or RUR is used.
Horner arithmetic in Fraction[x,y]^2 independently checks SymPy expansion;
all_roots, exact substitution/derivatives and disjoint rational boxes establish
the complete distinct-root set and its multiplicities for these finite cases.
"""

from argparse import ArgumentParser
from fractions import Fraction
from pathlib import Path
import json
import subprocess

import sympy as sp

ROOT = Path(__file__).resolve().parents[1]
z, t = sp.symbols("z t")
x, y = sp.symbols("x y", real=True)


def ratio(value):
    value = sp.Rational(value)
    return int(value.p), int(value.q)


def qliteral(value):
    numerator, denominator = ratio(value)
    return f"({numerator}, {denominator})"


def poly_coefficients(polynomial):
    return list(reversed(polynomial.all_coeffs()))


def fraction_expansion(coefficients):
    """Horner multiplication by (x,y), representing re + i*im sparsely."""
    real, imaginary = {}, {}
    for coefficient in reversed(coefficients):
        next_real, next_imaginary = {}, {}

        def add(target, monomial, value):
            target[monomial] = target.get(monomial, Fraction(0)) + value

        for (a, b), value in real.items():
            add(next_real, (a + 1, b), value)
            add(next_imaginary, (a, b + 1), value)
        for (a, b), value in imaginary.items():
            add(next_imaginary, (a + 1, b), value)
            add(next_real, (a, b + 1), -value)
        add(next_real, (0, 0), Fraction(*ratio(coefficient)))
        real = {monomial: value for monomial, value in next_real.items() if value}
        imaginary = {
            monomial: value for monomial, value in next_imaginary.items() if value
        }
    return real, imaginary


def sympy_terms(expression):
    polynomial = sp.Poly(expression, x, y, domain=sp.QQ)
    return {
        monomial: Fraction(*ratio(coefficient))
        for monomial, coefficient in polynomial.terms()
        if coefficient
    }


def term_literal(terms):
    return "[" + ", ".join(
        f"({qliteral(value)}, [{a}, {b}])"
        for (a, b), value in sorted(terms.items(), reverse=True)
    ) + "]"


def exact_zero(value):
    return sp.simplify(sp.expand_complex(value)) == 0


def rational_sign(value):
    return (value > 0) - (value < 0)


def radical_sign(value):
    """Sign proof for this finite corpus: products of positive rational powers."""
    if value.is_Rational:
        return rational_sign(Fraction(*ratio(value)))
    if value.is_Mul:
        sign = 1
        for factor in value.args:
            sign *= radical_sign(factor)
        return sign
    if value.is_Pow:
        base, exponent = value.args
        assert base.is_Rational and base > 0 and exponent.is_Rational, value
        return 1
    raise AssertionError(f"Coordinate needs an additional exact sign proof: {value}")


def compare_to_rational(value, minimum, bound):
    """Prove sign(value-bound) using monotonic rational powers, never evalf."""
    degree = minimum.degree()
    assert all(minimum.nth(index) == 0 for index in range(1, degree)), minimum
    # minimum(value)=0 has already been checked exactly; it is monic t^d-c.
    power = -Fraction(*ratio(minimum.nth(0)))
    bound = Fraction(*ratio(bound))
    value_sign, bound_sign = radical_sign(value), rational_sign(bound)
    if value_sign != bound_sign:
        return rational_sign(value_sign-bound_sign)
    difference_sign = rational_sign(power-bound**degree)
    return difference_sign if degree % 2 or value_sign >= 0 else -difference_sign


def coordinate(value):
    value = sp.simplify(value)
    assert value.is_real is True, value
    minimum = sp.Poly(sp.minpoly(value, t), t, domain=sp.QQ).monic()
    assert exact_zero(minimum.eval(value)), (value, minimum)
    if value.is_Rational:
        lower = upper = sp.Rational(value)
    else:
        candidates = minimum.intervals(eps=sp.Rational(1, 64))
        selected = [
            (lo, hi)
            for (lo, hi), multiplicity in candidates
            if multiplicity == 1
            and compare_to_rational(value, minimum, lo) == 1
            and compare_to_rational(value, minimum, hi) == -1
        ]
        assert len(selected) == 1, (value, selected)
        lower, upper = selected[0]
        assert minimum.eval(lower) != 0 and minimum.eval(upper) != 0
        assert minimum.count_roots(lower, upper) == 1
    return dict(
        expression=str(value),
        minimum=str(minimum.as_expr()),
        lower=lower,
        upper=upper,
    )


def disjoint(left, right):
    return any(
        left[axis]["upper"] < right[axis]["lower"]
        or right[axis]["upper"] < left[axis]["lower"]
        for axis in ("real", "imaginary")
    )


def root_records(polynomial):
    roots = []
    for value, multiplicity in polynomial.all_roots(multiple=False):
        # Derivative order distinguishes multiplicity from mere annihilation.
        for order in range(multiplicity):
            assert exact_zero(polynomial.diff((z, order)).eval(value))
        assert not exact_zero(polynomial.diff((z, multiplicity)).eval(value))
        real, imaginary = value.as_real_imag()
        assert exact_zero(value - real - sp.I * imaginary)
        roots.append(dict(
            expression=str(value), multiplicity=int(multiplicity),
            real=coordinate(real), imaginary=coordinate(imaginary),
        ))
    for index, left in enumerate(roots):
        assert all(disjoint(left, right) for right in roots[index + 1:])
    assert sum(root["multiplicity"] for root in roots) == polynomial.degree()
    assert len(roots) == polynomial.sqf_part().degree()
    return roots


def box_literal(root):
    bounds = [root[axis][edge] for axis in ("real", "imaginary")
              for edge in ("lower", "upper")]
    return "(" + ", ".join(map(qliteral, bounds)) + f", {root['multiplicity']})"


def rational_arithmetic():
    specifications = [
        ((Fraction(1, 2), Fraction(2, 3)), (Fraction(-3, 5), Fraction(7, 11))),
        ((Fraction(0), Fraction(1)), (Fraction(0), Fraction(1))),
        ((Fraction(3), Fraction(-4)), (Fraction(3), Fraction(4))),
        ((Fraction(0), Fraction(0)), (Fraction(-2, 7), Fraction(5, 3))),
        ((Fraction(-7, 13), Fraction(0)), (Fraction(0), Fraction(-11, 17))),
        ((Fraction(2, 9), Fraction(-5, 8)), (Fraction(1), Fraction(0))),
    ]
    records = []
    for (a, b), (c, d) in specifications:
        norm = c*c + d*d
        assert norm > 0
        operations = dict(
            sum=(a+c, b+d), product=(a*c-b*d, a*d+b*c),
            quotient=((a*c+b*d)/norm, (b*c-a*d)/norm),
        )
        left, right = sp.Rational(a) + sp.I*sp.Rational(b), sp.Rational(c) + sp.I*sp.Rational(d)
        for name, expected in operations.items():
            actual = dict(sum=left+right, product=left*right, quotient=left/right)[name]
            assert exact_zero(actual - sp.Rational(expected[0]) - sp.I*sp.Rational(expected[1]))
        records.append(dict(left=(a, b), right=(c, d), **operations))
    return records


def interval_text(coordinate_record):
    return f"[{coordinate_record['lower']}, {coordinate_record['upper']}]"


def complex_pair_text(pair):
    return f"({pair[0]}, {pair[1]})"


def generate():
    assert sp.__version__ == "1.14.0", f"Expected pinned SymPy 1.14.0, got {sp.__version__}"
    specifications = [
        ("zero root", z),
        ("positive rational", z-sp.Rational(2, 3)),
        ("negative rational", z+sp.Rational(2, 3)),
        ("imaginary units", z*z+1),
        ("real quadratic", z*z-2),
        ("translated quadratic", z*z+2*z+2),
        ("cube roots of unity", z**3-1),
        ("cube roots of two", z**3-2),
        ("mixed multiplicities", (z*z+1)**2*(z-1)),
        ("triple zero", z**3),
        ("rational scaling", -sp.Rational(3, 5)*(z*z+1)),
        ("nonzero constant", sp.Rational(7, 3)),
    ]
    records = []
    tests = ["// Generated by tools/generate_complex_fixtures.py; independent exact oracle.", ""]
    factored_tests = list(tests)
    for name, expression in specifications:
        polynomial = sp.Poly(expression, z, domain=sp.QQ)
        coefficients = poly_coefficients(polynomial)
        real, imaginary = fraction_expansion(coefficients)
        expanded = sp.expand_complex(polynomial.as_expr().subs(z, x+sp.I*y))
        sympy_real, sympy_imaginary = map(sp.expand, expanded.as_real_imag())
        assert real == sympy_terms(sympy_real)
        assert imaginary == sympy_terms(sympy_imaginary)
        roots = root_records(polynomial)
        records.append(dict(name=name, polynomial=polynomial, real=sympy_real,
                            imaginary=sympy_imaginary, roots=roots))
        arguments = [
            "    [" + ", ".join(map(qliteral, coefficients)) + "],",
            f"    {term_literal(real)},", f"    {term_literal(imaginary)},",
        ]
        boxes_argument = "    [" + ", ".join(map(box_literal, roots)) + "],"
        # Keep mixed-factor witness growth as an explicit reference stress;
        # all roots and weights remain enabled in the factored kernel's suite.
        mixed = name == "mixed multiplicities"
        tests.extend([
            "///|", f'test "independent complex oracle: {name}" {{',
            "  assert_cartesian_fixture(" if mixed else "  assert_complex_fixture(",
            *arguments, *([] if mixed else [boxes_argument]), "  )", "}", "",
        ])
        factored_tests.extend([
            "///|", f'test "independent factored complex oracle: {name}" {{',
            "  assert_factored_complex_fixture(", *arguments, boxes_argument,
            "  )", "}", "",
        ])

    # The zero polynomial is an infinite solution set, never a finite empty set.
    assert sp.Poly(0, z, domain=sp.QQ).is_zero
    assert fraction_expansion([sp.S.Zero]) == ({}, {})
    zero_real, zero_imaginary = sp.expand_complex(sp.S.Zero).as_real_imag()
    assert zero_real == zero_imaginary == 0
    arithmetic = rational_arithmetic()
    statistics = dict(
        finite_cases=len(records), nonconstant_cases=len(records)-1,
        distinct_roots=sum(len(record["roots"]) for record in records),
        total_multiplicity=sum(root["multiplicity"] for record in records for root in record["roots"]),
        coordinate_certificates=2*sum(len(record["roots"]) for record in records),
        zero_validation_cases=1, rational_arithmetic_pairs=len(arithmetic),
    )
    documentation = [
        "# Independent exact complex oracle (2026-11-17)", "",
        "The finite oracle checks the complex-root milestone without importing producer code or using its real-variety/RUR construction. It uses pinned SymPy **1.14.0** and Python `Fraction`; decimal approximations and numerical roots are never correctness inputs.", "",
        "## Evidence and schema", "",
        "For each rational polynomial, sparse `Fraction` Horner arithmetic in pairs of bivariate polynomials computes `Re p(x+i*y)` and `Im p(x+i*y)`. SymPy's symbolic complex expansion independently checks every coefficient. `Poly.all_roots(multiple=False)` supplies exact algebraic expressions; exact substitution and derivatives establish each stated multiplicity. The multiplicities sum to the degree, and pairwise disjoint rational coordinate boxes distinguish all roots. This establishes completeness for these cases over the complex algebraic closure.", "",
        "Each coordinate has an exact minimal polynomial, verified by substitution. Irrational coordinates use strict rational isolating intervals, with a single root of the minimal polynomial. All nonrational coordinates here have a binomial minimal polynomial `t^d-c`; their signs follow from products of positive rational powers. Comparing rational `d`th powers, with the selected sign branch, proves each endpoint inequality using `Fraction` alone. Rational coordinates use singleton intervals. Boxes are closed; all are pairwise disjoint within their source polynomial. The source squarefree degree also equals the distinct-root count.", "",
        "The generated MoonBit helper receives ascending rational coefficients `(numerator, denominator)`, Cartesian terms `((numerator, denominator), [x_exponent, y_exponent])`, and boxes `(re_lower, re_upper, im_lower, im_upper, multiplicity)`. Bounds are rational pairs; denominators are positive. Expected equations refer to the original source polynomial, including repeated factors and nonmonic rational scaling. Root order is not an expectation. All twelve root/weight cases run through the factor-first kernel. The unfactored reference also checks eleven root cases; its mixed-multiplicity case checks Cartesian expansion only because full-degree F4 witness growth is a recorded performance stress. Full mixed-root and multiplicity checks remain enabled in the factor-first suite.", "",
        "```json", json.dumps(statistics, sort_keys=True), "```", "",
        "## Expected Cartesian equations", "",
        "| Case | Source p(z) | Re p(x+i*y) | Im p(x+i*y) | Distinct roots | Multiplicities |",
        "| --- | --- | --- | --- | ---: | --- |",
    ]
    for record in records:
        multiplicities = ", ".join(str(root["multiplicity"]) for root in record["roots"]) or "none"
        documentation.append(
            f"| {record['name']} | `{record['polynomial'].as_expr()}` | `{record['real']}` | `{record['imaginary']}` | {len(record['roots'])} | {multiplicities} |"
        )
    documentation.extend([
        "", "## Exact selected roots and coordinate certificates", "",
        "Here `t` is a fresh variable in each coordinate minimal polynomial. Expressions use SymPy's exact syntax: `I` is the imaginary unit and rational powers are algebraic expressions.", "",
        "| Case | Exact root | Multiplicity | Real box | Imaginary box | Real minimal polynomial | Imaginary minimal polynomial |",
        "| --- | --- | ---: | --- | --- | --- | --- |",
    ])
    for record in records:
        for root in record["roots"]:
            documentation.append(
                f"| {record['name']} | `{root['expression']}` | {root['multiplicity']} | `{interval_text(root['real'])}` | `{interval_text(root['imaginary'])}` | `{root['real']['minimum']}` | `{root['imaginary']['minimum']}` |"
            )
    documentation.extend([
        "", "## Additional validation", "",
        "The nonzero constant `7/3` has no roots. The zero polynomial has identically zero real and imaginary equations and infinitely many roots; it is deliberately excluded from the finite-root helper. The zero-polynomial API check belongs to the root-owned validation tests.", "",
        "Direct `Fraction` complex addition, multiplication and division supply six further exact arithmetic cases. Independent SymPy substitution checks each result. Each pair `(a,b)` denotes `a+i*b`; every divisor is nonzero.", "",
        "| Left | Right | Sum | Product | Quotient |",
        "| --- | --- | --- | --- | --- |",
    ])
    for record in arithmetic:
        documentation.append("| " + " | ".join(
            f"`{complex_pair_text(record[key])}`" for key in ("left", "right", "sum", "product", "quotient")
        ) + " |")
    documentation.extend([
        "", "## Reproduction and limits", "",
        "Run `python3 tools/generate_complex_fixtures.py --check` with `sympy==1.14.0` (see `tools/requirements-oracles.txt`). Without `--check`, it regenerates this report and the oracle fixtures under `src/complexroots` and `src/complexfactor`. The generator formats only those fixtures through the repository's pinned `moonfmt`. The check performs every exact oracle assertion before comparing generated artifacts byte for byte.", "",
        "These are finite small-degree regression facts, not a proof of the general algorithm or a scalability result. The largest source degree is five, with squarefree degree three. Rational complex arithmetic is retained as independent reference data here; this fixture helper exercises root isolation and Cartesian expansion. Kernel purity and source-bound certificates remain separate implementation checks. Native and JavaScript execution of the generated fixture requires the root implementation and its helper; the integration owner records those test outcomes.", "",
    ])
    formatted_tests = subprocess.run(
        [str(ROOT / ".tools/moon/bin/moonfmt"), "-"], input="\n".join(tests),
        text=True, capture_output=True, check=True,
    ).stdout
    formatted_factored = subprocess.run(
        [str(ROOT / ".tools/moon/bin/moonfmt"), "-"], input="\n".join(factored_tests),
        text=True, capture_output=True, check=True,
    ).stdout
    return {
        ROOT / "src/complexroots/oracle_fixtures_wbtest.mbt": formatted_tests,
        ROOT / "src/complexfactor/oracle_fixtures_wbtest.mbt": formatted_factored,
        ROOT / "docs/research/complex-oracle-20261117.md": "\n".join(documentation),
    }, statistics


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    artifacts, statistics = generate()
    for path, expected in artifacts.items():
        if args.check:
            if not path.exists() or path.read_text() != expected:
                raise SystemExit(f"Stale artifact: {path.relative_to(ROOT)}")
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(expected)
    print(json.dumps(statistics, sort_keys=True))


if __name__ == "__main__":
    main()
