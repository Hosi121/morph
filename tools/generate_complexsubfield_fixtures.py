#!/usr/bin/env python3
"""Independent exact generated-complex-subfield oracle (SymPy 1.14/Fraction)."""

from argparse import ArgumentParser
from fractions import Fraction as Q
from itertools import product
from pathlib import Path
import json
import subprocess
import sys

import sympy as sp
from sympy.polys.numberfields import primitive_element, to_number_field

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
T = sp.Symbol("t")
RADICAL_BOUNDS = {
    sp.sqrt(2): (2, 2, Q(7, 5), Q(3, 2)),
    sp.sqrt(3): (2, 3, Q(17, 10), Q(26, 15)),
    sp.real_root(2, 3): (3, 2, Q(5, 4), Q(63, 50)),
}


def rational(value):
    value = sp.Rational(value)
    return Q(int(value.p), int(value.q))


def polynomial(values):
    return sp.Poly(sum(sp.Rational(q) * T**j for j, q in enumerate(values)), T, domain=sp.QQ)


def coefficients(value):
    return [rational(q) for q in reversed(value.all_coeffs())]


def add(left, right):
    return [a + b for a, b in zip(left, right)]


def scale(factor, value):
    return [factor * q for q in value]


class Ambient:
    """Independent QQ[a,i]/(minimum(a),i^2+1), using Fraction arithmetic."""

    def __init__(self, name, alpha, interval, generators):
        self.name, self.alpha, self.interval = name, alpha, interval
        self.minimum = sp.Poly(sp.minpoly(alpha, T), T, domain=sp.QQ).monic()
        self.modulus = coefficients(self.minimum)
        self.degree = self.minimum.degree()
        self.dimension = 2 * self.degree
        assert self.minimum.is_irreducible
        assert self.minimum.count_roots(*interval) == 1
        assert not alpha.atoms(sp.Float)
        # Prove the selected interval with rational power inequalities and
        # positivity of the chosen radicals. No approximate sign test occurs.
        if generators:
            lower, upper = Q(0), Q(0)
            assert sp.expand(alpha - sum(generators)) == 0
            for value in generators:
                exponent, constant, lo, hi = RADICAL_BOUNDS[value]
                assert value.is_positive is True
                assert sp.Poly(sp.minpoly(value, T), T) == sp.Poly(T**exponent-constant, T)
                assert 0 <= lo and lo**exponent < constant <= hi**exponent
                lower, upper = lower + lo, upper + hi
            assert interval[0] <= lower and upper <= interval[1]
        else:
            assert interval[0] < rational(alpha) <= interval[1]
        # The independently computed primitive-element result must select a.
        if len(generators) > 1:
            minimum, multipliers, _ = primitive_element(generators, T, ex=True)
            assert multipliers == [1] * len(generators)
            assert sp.Poly(minimum, T).monic() == self.minimum
        self.one = [Q(1)] + [Q(0)] * (self.dimension - 1)

    def real_coordinates(self, value):
        value = sp.expand(sp.radsimp(value))
        if self.degree == 1:
            return [rational(value)]
        image = list(reversed(to_number_field(value, self.alpha).coeffs()))
        result = [rational(q) for q in image] + [Q(0)] * (self.degree - len(image))
        # Algebraic-number conversion, not approximate root matching.
        assert to_number_field(value - sum(sp.Rational(q) * self.alpha**j
                                          for j, q in enumerate(result))).as_expr() == 0
        return result

    def vector(self, value):
        real, imaginary = sp.expand_complex(value).as_real_imag()
        return self.real_coordinates(real) + self.real_coordinates(imaginary)

    def expression(self, vector):
        return sp.expand(sum(sp.Rational(q) * self.alpha**j
                             for j, q in enumerate(vector[:self.degree]))
                         + sp.I * sum(sp.Rational(q) * self.alpha**j
                                      for j, q in enumerate(vector[self.degree:])))

    def mul_real(self, left, right):
        result = [Q(0)] * (2 * self.degree - 1)
        for i, a in enumerate(left):
            for j, b in enumerate(right):
                result[i+j] += a * b
        for j in range(len(result) - 1, self.degree - 1, -1):
            for k in range(self.degree):
                result[j-self.degree+k] -= result[j] * self.modulus[k]
        result = result[:self.degree]
        expected = (polynomial(left) * polynomial(right)).rem(self.minimum)
        assert result == coefficients(expected) + [Q(0)] * (self.degree - len(coefficients(expected)))
        return result

    def multiply(self, left, right):
        a, b = left[:self.degree], left[self.degree:]
        c, d = right[:self.degree], right[self.degree:]
        return add(self.mul_real(a, c), scale(-1, self.mul_real(b, d))) + add(
            self.mul_real(a, d), self.mul_real(b, c))

    def power(self, vector, exponent):
        result = self.one
        for _ in range(exponent):
            result = self.multiply(result, vector)
        return result


def matrix_columns(columns):
    return sp.Matrix.hstack(*(sp.Matrix(column) for column in columns))


def rows(matrix):
    return [[rational(q) for q in row] for row in matrix.tolist()]


def field_record(ambient, name, expressions, expected_degree):
    vectors = [ambient.vector(value) for value in expressions]
    minima = [sp.Poly(sp.minpoly(value, T), T, domain=sp.QQ).monic() for value in expressions]
    # Enumerate ALL monomials below the separate minimum degrees, independently
    # of the producer's closure walk or ordering. Their span is the whole ring.
    exponents = sorted(product(*(range(p.degree()) for p in minima)), key=lambda e: (sum(e), tuple(-n for n in e)))
    monomials = []
    for powers in exponents:
        value = ambient.one
        for vector, exponent in zip(vectors, powers):
            value = ambient.multiply(value, ambient.power(vector, exponent))
        monomials.append(value)
    full = matrix_columns(monomials)
    pivots = full.rref()[1]
    basis = [monomials[j] for j in pivots]
    witnesses = [exponents[j] for j in pivots]
    matrix = matrix_columns(basis)
    dimension = matrix.cols
    assert full.rank() == dimension == expected_degree
    # Independent rectangular left inverse and annihilator specify both span
    # inclusions without imposing an order on the producer's returned basis.
    row_pivots = matrix.T.rref()[1]
    square_inverse = matrix[list(row_pivots), :].inv()
    left_inverse = sp.zeros(dimension, ambient.dimension)
    for j, row in enumerate(row_pivots):
        left_inverse[:, row] = square_inverse[:, j]
    assert left_inverse * matrix == sp.eye(dimension)
    annihilator = sp.Matrix.vstack(*(vector.T for vector in matrix.T.nullspace())) if dimension < ambient.dimension else sp.zeros(0, ambient.dimension)
    assert annihilator * full == sp.zeros(ambient.dimension - dimension, len(monomials))

    def coordinates(value):
        candidate = left_inverse * sp.Matrix(value)
        return [rational(q) for q in candidate] if matrix * candidate == sp.Matrix(value) else None

    closure = []
    table = []
    for value in basis:
        closure.append([coordinates(ambient.multiply(value, generator)) for generator in vectors])
        assert all(column is not None for column in closure[-1])
        table.append([coordinates(ambient.multiply(value, other)) for other in basis])
        assert all(column is not None for column in table[-1])
    candidate = next(c for c in range(20) if len(sp.Poly(sp.minpoly(ambient.expression(
        [sum(Q(c**j) * basis[j][k] for j in range(dimension))
         for k in range(ambient.dimension)]), T), T).all_coeffs()) - 1 == dimension)
    theta_vector = [sum(Q(candidate**j) * basis[j][k] for j in range(dimension))
                    for k in range(ambient.dimension)]
    theta = ambient.expression(theta_vector)
    minimum = sp.Poly(sp.minpoly(theta, T), T, domain=sp.QQ).monic()
    powers = [ambient.power(theta_vector, j) for j in range(dimension)]
    power_matrix = matrix_columns(powers)
    assert power_matrix.rank() == dimension
    power_inverse = (left_inverse * power_matrix).inv() * left_inverse
    assert power_inverse * power_matrix == sp.eye(dimension)
    vanishing = [sum(coefficients(minimum)[j] * ambient.power(theta_vector, j)[k]
                     for j in range(dimension + 1)) for k in range(ambient.dimension)]
    assert not any(vanishing)
    samples = [ambient.one, *vectors, theta_vector, ambient.multiply(theta_vector, theta_vector)]
    # A deterministic fractional combination, and ambient elements which may
    # or may not lie in the generated field, exercise inclusion boundaries.
    fractional = [sum(Q((-1)**j * (j+1), j+2) * basis[j][k] for j in range(dimension))
                  for k in range(ambient.dimension)]
    samples.append(fractional)
    tests = [ambient.vector(ambient.alpha), ambient.vector(sp.I)]
    if ambient.degree == 6:
        tests += [ambient.vector(sp.sqrt(3)), ambient.vector(sp.I * sp.sqrt(3))]
    conversions = []
    for value in samples:
        image = [rational(q) for q in power_inverse * sp.Matrix(value)]
        recovered = [sum(image[j] * powers[j][k] for j in range(dimension))
                     for k in range(ambient.dimension)]
        assert recovered == value
        conversions.append(image)
    return dict(name=name, ambient=ambient, vectors=vectors, expressions=expressions,
                minima=minima, degree=dimension, monomial_count=len(monomials),
                basis=basis, witnesses=witnesses, left_inverse=rows(left_inverse),
                annihilator=rows(annihilator), closure=closure, table=table,
                candidate=candidate, theta=theta_vector, minimum=coefficients(minimum),
                minimum_text=str(minimum.as_expr()), power_basis=rows(power_matrix),
                samples=samples, conversions=conversions,
                tests=[(value, coordinates(value)) for value in tests])


def q_literal(value):
    value = Q(value)
    assert abs(value.numerator) < 2**31 and value.denominator < 2**31
    return f"@oracle.rational({value.numerator}, {value.denominator})"


def array(values):
    return "[" + ", ".join(q_literal(q) for q in values) + "]"


def arrays(values):
    return "[" + ", ".join(array(row) for row in values) + "]"


def naturals(values):
    return "[" + ", ".join(str(n) for n in values) + "]"


def record_literal(record):
    ambient = record["ambient"]
    fields = [f'minimum: {array(ambient.modulus)}',
              f'lower: @oracle.rational({ambient.interval[0]}, 1)',
              f'upper: @oracle.rational({ambient.interval[1]}, 1)',
              f'generators: {arrays(record["vectors"])}',
              f'generator_minima: {arrays([coefficients(p) for p in record["minima"]])}',
              f'degree: {record["degree"]}', f'basis: {arrays(record["basis"])}',
              'monomials: [' + ", ".join(naturals(e) for e in record["witnesses"]) + ']',
              f'left_inverse: {arrays(record["left_inverse"])}',
              f'annihilator: {arrays(record["annihilator"])}',
              'closure: [' + ", ".join(arrays(columns) for columns in record["closure"]) + ']',
              f'candidate: {record["candidate"]}', f'theta: {array(record["theta"])}',
              f'primitive_minimum: {array(record["minimum"])}',
              f'power_basis: {arrays(record["power_basis"])}',
              'samples: [' + ", ".join(f'({array(value)}, {array(image)})' for value, image in zip(record["samples"], record["conversions"])) + ']',
              'inclusions: [' + ", ".join(f'({array(value)}, ' + ('None' if image is None else f'Some({array(image)})') + ')' for value, image in record["tests"]) + ']']
    return "{\n" + ",\n".join(fields) + ",\n}"


def generate():
    assert sp.__version__ == "1.14.0"
    sqrt2, sqrt3, cube = sp.sqrt(2), sp.sqrt(3), sp.real_root(2, 3)
    gaussian = Ambient("QQ(i)", sp.S.Zero, (-1, 0), [])
    quadratic = Ambient("QQ(sqrt2,i)", sqrt2, (1, 2), [sqrt2])
    third = Ambient("QQ(sqrt3,i)", sqrt3, (1, 2), [sqrt3])
    eighth = Ambient("QQ(sqrt2,sqrt3,i)", sqrt2 + sqrt3, (3, 4), [sqrt2, sqrt3])
    twelfth = Ambient("QQ(cbrt2,sqrt3,i)", cube + sqrt3, (2, 3), [cube, sqrt3])
    omega = (-1 + sp.I * sqrt3) / 2
    specifications = [
        (gaussian, "empty generators", [], 1),
        (gaussian, "rational generators", [sp.Rational(3, 2), sp.Rational(-2, 5)], 1),
        (gaussian, "Gaussian unit", [sp.I], 2),
        (quadratic, "real sqrt2", [sqrt2], 2),
        (quadratic, "dependent sqrt2 generators", [sqrt2, 1 + sqrt2, sqrt2**2], 2),
        (quadratic, "independent sqrt2 and i", [sqrt2, sp.I], 4),
        (third, "cube root of unity", [omega], 2),
        (eighth, "sqrt2 plus i sqrt3", [sqrt2 + sp.I * sqrt3], 4),
        (eighth, "independent sqrt2 sqrt3 and i", [sqrt2, sqrt3, sp.I], 8),
        (twelfth, "single nonreal cubic root", [cube * omega], 3),
        (twelfth, "all roots of t^3-2", [cube, cube * omega, cube * sp.conjugate(omega)], 6),
    ]
    records = [field_record(*specification) for specification in specifications]
    assert records[-1]["degree"] == 6 < twelfth.dimension == 12
    # Direct factorization and both field inclusions are exact: all roots give
    # c and omega=(c*omega)/c, while c and omega express every root.
    assert sp.Poly(sp.expand(sp.prod(T-value for value in specifications[-1][2])), T) == sp.Poly(T**3-2, T)
    assert to_number_field((cube * omega) / cube - omega).as_expr() == 0
    tests = ["// Generated by tools/generate_complexsubfield_fixtures.py; independent exact oracle.", ""]
    for record in records:
        tests += ["///|", f'test "independent generated-subfield oracle: {record["name"]}" {{',
                  f'  oracle_assert_subfield({record_literal(record)})', "}", ""]
    formatted = subprocess.run([str(ROOT / ".tools/moon/bin/moonfmt"), "-"],
                               input="\n".join(tests), text=True, capture_output=True, check=True).stdout
    stats = dict(cases=len(records), ambient_degrees=sorted({r["ambient"].dimension for r in records}),
                 generated_degrees=sorted({r["degree"] for r in records}),
                 exhaustive_monomials=sum(r["monomial_count"] for r in records),
                 independently_populated_field_certificates=len(records),
                 independently_populated_primitive_certificates=len(records),
                 conversions=sum(len(r["samples"]) for r in records))
    docs = ["# Independent exact generated complex subfield oracle (2026-11-17)", "",
            "This finite oracle uses SymPy 1.14.0 and Python Fraction arithmetic. No MoonBit output, producer basis order, producer primitive trial order, numerical root, or floating approximation supplies an expectation. All polynomial arrays use increasing powers. The source ambient basis is (1,a,...,a^(d-1),i,i*a,...,i*a^(d-1)).", "",
            "For each generator its independent SymPy minimum bounds its exponent. The complete Cartesian set of bounded monomials therefore spans the generated algebra. SymPy rational rref selects an independent subset, computes a rectangular left inverse and the full annihilator, and independently verifies the rank of the whole set. Fraction quotient multiplication modulo the real minimum and i^2+1 is checked against SymPy QQ[t] remainders. Every basis product with every generator is in the resulting span, as is every pairwise basis product. This establishes the exact generated degree and excludes a larger ambient field which merely contains the inputs.", "",
            "MoonBit tests import independently populated monomial certificates and primitive certificates; they do not assume generate returns the same basis order. Returned bases are checked against the independent span, and both basis dimensions agree. Independent left inverses pin imported basis coordinates and inclusion boundaries. Each input generator's minimum is compared with its independent SymPy minimum. Primitive certificates use the independently chosen monomial basis and an independently searched small integer candidate. Their modulus, ambient power matrix, canonical conversions, and unreduced polynomial evaluation are externally computed. Returned producer primitives are checked for degree, field binding, and reconstruction; the independent imported representation supplies the pinned quotient expectations.", "",
            "```json", json.dumps(stats, sort_keys=True), "```", "",
            "| Case | Ambient degree | Generated degree | Complete monomials | Independent candidate | Primitive minimum |",
            "| --- | ---: | ---: | ---: | ---: | --- |"]
    for record in records:
        docs.append(f'| {record["name"]} | {record["ambient"].dimension} | {record["degree"]} | {record["monomial_count"]} | {record["candidate"]} | `{record["minimum_text"]}` |')
    docs += ["", "The degree-12 source uses a=cbrt(2)+sqrt(3), selected by the exact interval (2,3]. SymPy primitive_element independently returns multipliers [1,1] and the irreducible real minimum `t^6-9*t^4-4*t^3+27*t^2-36*t-23`. Exact root counting gives one root in the chosen interval. Selected values are bound algebraically: (5/4)^3<2<(63/50)^3 and (17/10)^2<3<(26/15)^2 imply 59/20<a<449/150<3. The other source intervals use the same rational-power method, never an approximate radical sign comparison. MoonBit normalizes this single real root to a verified number field; the oracle needs no compositum producer to build the source.", "",
             f'The cbrt(2) image in QQ[a] is `{polynomial(twelfth.real_coordinates(cube)).as_expr()}`; '
             f'the sqrt(3) image is `{polynomial(twelfth.real_coordinates(sqrt3)).as_expr()}`. '
             'SymPy to_number_field verifies both identities exactly. The three roots c, c*omega, c*omega^2 of t^3-2 have complete monomial rank 6 inside ambient rational dimension 12. They generate c and omega because c is nonzero and omega=(c*omega)/c; conversely c and omega express all three roots. Thus the generated field is the S3 splitting field of degree 6, while the degree-12 source is oversized. In particular sqrt(3) and i are excluded individually, whereas i*sqrt(3)=2*omega+1 is included.', "",
             "Regenerate with `python3 tools/generate_complexsubfield_fixtures.py`; check reproducibility with `--check`. Only the generated fixture and this document are rewritten; moonfmt formats the fixture through the pinned repository SDK. These bounded cases are regression evidence and make no performance or arbitrary-field correctness claim. Integration owns JS/wasm-gc validation and the full-suite checks.", ""]
    docs += ["A single nonreal cubic root generates a degree-3 field inside the same degree-12 ambient field. This field need not contain the other two cubic roots. Generated subfields are therefore not restricted to even degrees or Galois extensions. The degree-6 case uses all three roots and is the splitting field.", "",
             "Native/JS/wasm-gc validation and whole-suite results are recorded in the central [validation guide](../VALIDATION.md). Regeneration checks the exact fixtures independently of executing the MoonBit tests; a regenerated fixture is not itself a passing test result.", ""]
    return {ROOT / "src/complexsubfield/oracle_fixtures_wbtest.mbt": formatted,
            ROOT / "docs/research/complexsubfield-oracle-20261117.md": "\n".join(docs)}, stats


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
