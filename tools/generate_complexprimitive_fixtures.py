#!/usr/bin/env python3
"""Independent exact primitive-coordinate oracle using SymPy algebraic expressions."""

from argparse import ArgumentParser
from fractions import Fraction as Q
from pathlib import Path
import json
import subprocess
import sys

import sympy as sp

sys.dont_write_bytecode = True
from generate_complexfield_fixtures import array, coefficients, fraction, mul_base

ROOT = Path(__file__).resolve().parents[1]
T = sp.Symbol("t")


def exact_zero(expression):
    assert not expression.atoms(sp.Float)
    assert sp.simplify(sp.expand_complex(expression)) == 0, expression


def poly(values):
    return sp.Poly(sum(sp.Rational(q) * T**j for j, q in enumerate(values)), T, domain=sp.QQ)


def poly_coefficients(value):
    return [fraction(q) for q in reversed(value.all_coeffs())] if value else []


def vector(value, alpha, degree):
    real, imaginary = sp.expand_complex(value).as_real_imag()
    return coefficients(real, alpha, degree) + coefficients(imaginary, alpha, degree)


def expression(real, imaginary, alpha):
    return sp.expand(sum(sp.Rational(q) * alpha**j for j, q in enumerate(real))
                     + sp.I * sum(sp.Rational(q) * alpha**j for j, q in enumerate(imaginary)))


def field_data(name, degree, constant):
    alpha = sp.S.Zero if degree == 1 else sp.Integer(constant)**sp.Rational(1, degree)
    theta = alpha + sp.I
    dimension = 2 * degree
    columns = [vector(theta**j, alpha, degree) for j in range(dimension)]
    basis = sp.Matrix.hstack(*(sp.Matrix(column) for column in columns))
    inverse = basis.inv()
    assert basis * inverse == inverse * basis == sp.eye(dimension)
    minimum = sp.Poly(sp.minpoly(theta, T), T, domain=sp.QQ).monic()
    assert minimum.degree() == dimension
    exact_zero(minimum.eval(theta))

    def conversion(value):
        coordinates = vector(value, alpha, degree)
        polynomial = poly([fraction(q) for q in inverse * sp.Matrix(coordinates)])
        assert polynomial.is_zero or polynomial.degree() < dimension
        exact_zero(polynomial.eval(theta) - value)
        exact_zero(expression(coordinates[:degree], coordinates[degree:], alpha) - value)
        return dict(real=coordinates[:degree], imaginary=coordinates[degree:],
                    polynomial=poly_coefficients(polynomial), expression=str(sp.expand(value)))

    alpha_image, imaginary_image = conversion(alpha), conversion(sp.I)
    fractions_a = [Q(2, 3), Q(-5, 7), Q(1, 5), Q(-2, 11)][:degree]
    fractions_b = [Q(-3, 5), Q(2, 7), Q(-1, 3), Q(1, 2)][:degree]
    fractions_c = [Q(1, 2), Q(1, 3), Q(-1, 7), Q(2, 5)][:degree]
    fractions_d = [Q(-2, 3), Q(1, 5), Q(3, 7), Q(-1, 2)][:degree]
    values = [theta, sp.conjugate(theta), expression(fractions_a, fractions_b, alpha),
              expression(fractions_c, fractions_d, alpha)]
    names = ["theta", "conjugate theta", "fractional mixed a", "fractional mixed b"]
    products = [(2, 3), (0, 1)]
    if degree == 2 and constant == 2:
        values += [theta**4, theta**8]
        names += ["theta fourth power", "theta eighth power"]
        products.append((4, 4))
    if degree == 4:
        values.append(1 / theta)
        names.append("theta inverse")
        products.append((0, 4))
    samples = [dict(name=label, **conversion(value)) for label, value in zip(names, values)]
    product_records = []
    for left, right in products:
        record = conversion(values[left] * values[right])
        # Independent quotient multiplication: SymPy's QQ[t] remainder and
        # Fraction reduction in QQ[a]/(a^d-c) must agree with exact substitution.
        remainder = (poly(samples[left]["polynomial"]) * poly(samples[right]["polynomial"])).rem(minimum)
        assert poly_coefficients(remainder) == record["polynomial"]
        a, b = samples[left]["real"], samples[left]["imaginary"]
        c, d = samples[right]["real"], samples[right]["imaginary"]
        ac, bd = mul_base(a, c, degree, constant), mul_base(b, d, degree, constant)
        ad, bc = mul_base(a, d, degree, constant), mul_base(b, c, degree, constant)
        assert record["real"] == [x-y for x, y in zip(ac, bd)]
        assert record["imaginary"] == [x+y for x, y in zip(ad, bc)]
        product_records.append(dict(left=left, right=right, **record))

    result = dict(name=name, degree=degree, constant=constant, dimension=dimension,
                  minimum=poly_coefficients(minimum), minimum_text=str(minimum.as_expr()),
                  basis=[[fraction(q) for q in row] for row in basis.tolist()],
                  inverse=[[fraction(q) for q in row] for row in inverse.tolist()],
                  alpha_image=alpha_image["polynomial"], imaginary_image=imaginary_image["polynomial"],
                  samples=samples, products=product_records)
    if degree == 2 and constant == 2:
        assert samples[5]["polynomial"] == [Q(45), Q(0), Q(-28)]
        assert samples[5]["real"] == [Q(17), Q(0)]
        assert samples[5]["imaginary"] == [Q(0), Q(-56)]
    if degree == 4:
        assert samples[4]["polynomial"] == poly_coefficients(sp.invert(sp.Poly(T, T), minimum))
        assert product_records[-1]["polynomial"] == [Q(1)]
    return result


def matrix_literal(rows):
    return "[" + ", ".join(array(row) for row in rows) + "]"


def conversion_literal(record):
    return f'({array(record["real"])}, {array(record["imaginary"])}, {array(record["polynomial"])})'


def generate():
    assert sp.__version__ == "1.14.0"
    records = [field_data(*specification) for specification in [
        ("QQ(i)", 1, 0), ("QQ(sqrt2)(i)", 2, 2), ("QQ(sqrt3)(i)", 2, 3),
        ("QQ(cbrt2)(i)", 3, 2), ("QQ(fourthroot2)(i)", 4, 2),
    ]]
    tests = ["// Generated by tools/generate_complexprimitive_fixtures.py; independent exact oracle.", ""]
    for record in records:
        tests += ["///|", f'test "independent primitive-coordinate oracle: {record["name"]}" {{',
                  "  oracle_assert_primitive_fixture(", f'    {record["degree"]}, {record["constant"]},',
                  f'    {array(record["minimum"])},', f'    {matrix_literal(record["basis"])},',
                  f'    {matrix_literal(record["inverse"])},', f'    {array(record["alpha_image"])},',
                  f'    {array(record["imaginary_image"])},', "    ["]
        for sample in record["samples"]:
            tests += [f'      // {sample["name"]}', f'      {conversion_literal(sample)},']
        tests += ["    ],", "    ["]
        for product in record["products"]:
            tests += [f'      ({product["left"]}, {product["right"]}, {conversion_literal(product)}),']
        tests += ["    ],", "  )", "}", ""]
    formatted = subprocess.run([str(ROOT / ".tools/moon/bin/moonfmt"), "-"],
                               input="\n".join(tests), text=True, capture_output=True, check=True).stdout
    stats = dict(fields=len(records), ambient_degrees=sorted({r["dimension"] for r in records}),
                 conversions=sum(len(r["samples"]) for r in records),
                 products=sum(len(r["products"]) for r in records),
                 exact_basis_matrices=len(records), exact_inverse_matrices=len(records))
    docs = ["# Independent exact primitive-coordinate oracle (2026-11-17)", "",
            "This finite regression oracle uses SymPy 1.14.0 exact algebraic expressions, rational matrices, QQ[t] polynomial remainders, and Python Fraction arithmetic. It does not use MoonBit output, producer internals, numerical roots, or floating approximations as expectations. The only shared code is the external complexfield oracle's exact coordinate extraction, rational literal formatting, and Fraction reduction modulo a^d-c.", "",
            "For K=QQ(a), a is the positive real root of a^d=c; for QQ, d=1,c=0,a=0. The selected primitive is theta=a+i. Coordinates use the ordered QQ basis (1,a,...,a^(d-1),i,i*a,...,i*a^(d-1)). Each power-basis column comes from expanding the algebraic expression (a+i)^j. SymPy inverts that matrix exactly and both matrix products are checked against identity. Independently computed minimal polynomials have degree 2d and vanish under exact substitution. The resulting alpha and i image polynomials and every sample conversion also recover their exact algebraic expressions by substitution. Polynomial coefficient arrays use increasing powers of t; matrix literals contain rows.", "",
            "Each product is checked three ways before emission: direct algebraic-expression multiplication, QQ[t] remainder modulo the independent minimum, and Fraction multiplication in the original real/imaginary quotient basis. MoonBit tests compare prepare's basis and inverse matrices, modulus, generator images, canonical conversions, and product coefficients against these external values. They also pass an independently populated representation certificate to check and from_certificate, and bind each conversion with check_conversion_for.", "",
            "```json", json.dumps(stats, sort_keys=True), "```", "",
            "| Field | Degree | Minimum of theta | Alpha image | i image | Samples | Products |",
            "| --- | ---: | --- | --- | --- | ---: | ---: |"]
    for record in records:
        docs.append(f'| {record["name"]} | {record["dimension"]} | `{record["minimum_text"]}` | '
                    f'`{poly(record["alpha_image"]).as_expr()}` | `{poly(record["imaginary_image"]).as_expr()}` | '
                    f'{len(record["samples"])} | {len(record["products"])} |')
    quartic_inverse = records[-1]["samples"][-1]
    quartic_inverse_expression = expression(quartic_inverse["real"], quartic_inverse["imaginary"],
                                           sp.Integer(2)**sp.Rational(1, 4))
    docs += ["", "The sqrt2 case fixes the nontrivial high-power reduction (sqrt2+i)^8 = 17-56*sqrt2*i = 45-28*t^2. The product of the fourth power with itself must return that same canonical polynomial, not an unreduced degree-eight expression.", "",
             f'The quartic-real-base case fixes theta^(-1) as `{poly(quartic_inverse["polynomial"]).as_expr()}`. '
             f'Its original quotient expression is `{quartic_inverse_expression}` after rationalization; '
             'direct exact substitution and an independent QQ[t] modular inverse agree. Multiplying theta by this element has the pinned canonical polynomial 1.', "",
             "Run `python3 tools/generate_complexprimitive_fixtures.py --check` in the pinned SymPy environment. Regeneration formats only its generated MoonBit fixture with the repository SDK's moonfmt. The fixtures cover five specified real bases and small deterministic samples; they are regression evidence, not a proof for arbitrary fields or a scalability result.", "",
             "Milestone validation: regeneration check passes, and `tools/measure --cpu 4 tools/moon test src/complexprimitive --target native --release -j 1` passes 11 tests, including these five oracle cases. The shared measurement lock is used. JS and wasm-gc validation remains with the integrating root task.", ""]
    return {ROOT / "src/complexprimitive/oracle_fixtures_wbtest.mbt": formatted,
            ROOT / "docs/research/complexprimitive-oracle-20261117.md": "\n".join(docs)}, stats


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
