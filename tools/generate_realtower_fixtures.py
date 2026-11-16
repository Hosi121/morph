#!/usr/bin/env python3
"""Independent exact flat-number-field fixtures for recursive real towers.

Kernel arithmetic keeps nested rational expressions. This oracle instead uses a
single irreducible polynomial X^(2^depth)-2 and Fraction coefficient vectors.
SymPy supplies only polynomial inversion over QQ; signs use rational interval
arithmetic and exact bisection, never Float or evalf. Relative root counts use a
separate Fraction-vector Sturm implementation, without calling Morph.
"""
from __future__ import annotations

from dataclasses import dataclass
from fractions import Fraction as F
from pathlib import Path
import random
import argparse
import re
import sympy as sp

ROOT = Path(__file__).resolve().parent.parent
X = sp.Symbol("X")


@dataclass(frozen=True)
class K:
    degree: int
    values: tuple[F, ...]

    @classmethod
    def make(cls, degree, values):
        result = [F(v) for v in values]
        result += [F(0)] * max(0, degree - len(result))
        for i in range(len(result) - 1, degree - 1, -1):
            result[i - degree] += 2 * result[i]
        return cls(degree, tuple(result[:degree]))

    def __add__(self, other):
        assert self.degree == other.degree
        return K.make(self.degree, [a + b for a, b in zip(self.values, other.values)])

    def __neg__(self):
        return K.make(self.degree, [-a for a in self.values])

    def __sub__(self, other):
        return self + -other

    def __mul__(self, other):
        assert self.degree == other.degree
        result = [F(0)] * (2 * self.degree - 1)
        for i, a in enumerate(self.values):
            for j, b in enumerate(other.values):
                result[i + j] += a * b
        return K.make(self.degree, result)

    def inverse(self):
        assert not self.zero()
        source = sp.Poly(sum(sp.Rational(v.numerator, v.denominator) * X**i
                             for i, v in enumerate(self.values)), X, domain=sp.QQ)
        modulus = sp.Poly(X**self.degree - 2, X, domain=sp.QQ)
        inverse = sp.invert(source, modulus)
        assert not inverse.as_expr().atoms(sp.Float)
        result = K.make(self.degree, [F(inverse.nth(i)) for i in range(self.degree)])
        assert self * result == K.make(self.degree, [1])
        return result

    def zero(self):
        return not any(self.values)

    def sign(self):
        if self.zero():
            return 0
        if self.degree == 1:
            return 1 if self.values[0] > 0 else -1
        lower, upper = F(1), F(2)
        while True:
            lo, hi = F(0), F(0)
            for c in reversed(self.values):
                products = (lo * lower, lo * upper, hi * lower, hi * upper)
                lo, hi = min(products) + c, max(products) + c
            if lo > 0:
                return 1
            if hi < 0:
                return -1
            mid = (lower + upper) / 2
            if mid**self.degree < 2:
                lower = mid
            else:
                upper = mid


def trim(p):
    p = list(p)
    while p and p[-1].zero():
        p.pop()
    return p


def add(a, b):
    degree = (a or b)[0].degree
    z = K.make(degree, [])
    return trim([(a[i] if i < len(a) else z) + (b[i] if i < len(b) else z)
                 for i in range(max(len(a), len(b)))])


def multiply(a, b):
    if not a or not b:
        return []
    result = [K.make(a[0].degree, [])] * (len(a) + len(b) - 1)
    for i, u in enumerate(a):
        for j, v in enumerate(b):
            result[i + j] = result[i + j] + u * v
    return trim(result)


def derivative(p):
    return trim([p[i] * K.make(p[i].degree, [i]) for i in range(1, len(p))])


def remainder(a, b):
    a = trim(a)
    inv = b[-1].inverse()
    while len(a) >= len(b):
        coefficient = a[-1] * inv
        offset = len(a) - len(b)
        for i, c in enumerate(b):
            a[i + offset] = a[i + offset] - coefficient * c
        a = trim(a)
    return a


def evaluate(p, x):
    degree = p[0].degree
    value = K.make(degree, [])
    point = K.make(degree, [x])
    for c in reversed(p):
        value = value * point + c
    return value


def right_sign(p, x):
    while True:
        value = evaluate(p, x)
        if not value.zero():
            return value.sign()
        p = derivative(p)
        assert p


def sturm_sequence(p):
    seq = [trim(p)]
    nxt = derivative(seq[0])
    while nxt:
        seq.append(nxt)
        nxt = [-v for v in remainder(seq[-2], seq[-1])]
    return seq


def count_roots(p, lower, upper):
    seq = sturm_sequence(p)
    def variations(x):
        signs = [right_sign(row, x) for row in seq]
        return sum(a != b for a, b in zip(signs, signs[1:]))
    result = variations(lower) - variations(upper)
    assert result >= 0
    return result


def total_roots(p):
    seq = sturm_sequence(p)
    plus = [row[-1].sign() for row in seq]
    minus = [sign * (-1 if (len(row) - 1) % 2 else 1)
             for sign, row in zip(plus, seq)]
    variations = lambda signs: sum(a != b for a, b in zip(signs, signs[1:]))
    return variations(minus) - variations(plus)


def pairs(values):
    return "[" + ", ".join(f"({v.numerator}, {v.denominator})" for v in values) + "]"


def poly_literal(values):
    return "[" + ", ".join(pairs(v.values) for v in values) + "]"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stress", action="store_true", help="include expensive dense quartics at high tower depths")
    parser.add_argument("--check", action="store_true", help="check generated syntax, allowing moon fmt whitespace and trailing commas")
    options = parser.parse_args()
    rows = ["// Generated by tools/generate_realtower_fixtures.py; exact Fraction oracle.",
            "// Flat X^(2^depth)-2 fields; no Float, evalf, or Morph oracle calls."]
    scalar_count = 0
    root_count = 0
    rng = random.Random(20261116)
    for depth in range(4):
        degree = 2**depth
        k = lambda cs: K.make(degree, cs)
        gamma = k([0, 1])
        z, unit = k([]), k([1])
        cases = [([-1, 1], [1, 1]), ([0, 1], [-1, 1]),
                 ([1, -2, 1], [2, -1, 1]), ([-3, 1], [-1, -1]),
                 ([-2] + [0] * (degree - 1) + [1], [1]),
                 ([F(1, 3), F(-2, 5), F(1, 7)], [F(3, 2), F(1, 4)])]
        for _ in range(5):
            cases.append(([rng.randint(-3, 3) for _ in range(degree + 1)],
                          [rng.randint(-2, 2) for _ in range(degree)]))
        emitted = []
        for numerator, denominator in cases:
            n, d = k(numerator), k(denominator)
            if d.zero():
                continue
            expected = n * d.inverse()
            assert expected.sign() == n.sign() * d.sign()
            emitted.append(f"    ({pairs(map(F, numerator))}, {pairs(map(F, denominator))}, {pairs(expected.values)}, {expected.sign()}),")
            scalar_count += 1
        rows += ["", "///|", f'test "flat exact field scalar oracle depth {depth}" {{',
                 f"  let (field, generator) = flat_context({depth})",
                 "  let cases = [", *emitted, "  ]", "  for (numerator, denominator, expected, sign) in cases {",
                 "    let n = flat_scalar(field, generator, numerator)",
                 "    let d = flat_scalar(field, generator, denominator)",
                 "    let value = scalar_divide(n, d).unwrap()",
                 "    assert_true(scalar_equal(value, flat_scalar(field, generator, expected)).unwrap())",
                 "    let order : @core.Ordering = if sign < 0 { Less } else if sign > 0 { Greater } else { Equal }",
                 "    let result = scalar_sign(value).unwrap()",
                 "    assert_true(result.sign.equal(order))",
                 "    assert_true(check_scalar(value, order, result.certificate))",
                 "  }", "}"]
        # Coefficients lie in flat K; the roots of y^2-gamma need a new tower level.
        linear = [-gamma, unit]
        quadratic = [-gamma, z, unit]
        no_roots = [gamma, z, unit]
        cubic = [z, -gamma, z, unit]
        quartic = multiply(multiply(linear, linear), quadratic)
        dense = [k([1, -1]), k([-1, 2]), k([2, 1]), k([-1]), unit]
        polynomials = [quadratic, no_roots, cubic]
        if depth < 2 or options.stress:
            polynomials += [quartic, dense]
        spans = [(F(-3), F(-1)), (F(-1), F(0)), (F(0), F(1)),
                 (F(1), F(2)), (F(-3), F(3)), (F(-1, 2), F(3, 2))]
        for index, polynomial in enumerate(polynomials):
            counts = [(a, b, count_roots(polynomial, a, b)) for a, b in spans]
            total = total_roots(polynomial)
            root_count += len(counts)
            rows += ["", "///|", f'test "flat exact relative roots depth {depth} case {index}" {{',
                     f"  let (field, generator) = flat_context({depth})",
                     f"  let input = flat_polynomial(field, generator, {poly_literal(polynomial)})",
                     "  let sys = system(input).unwrap()", "  let spans = ["]
            rows += [f"    (({a.numerator}, {a.denominator}), ({b.numerator}, {b.denominator}), {n})," for a,b,n in counts]
            rows += ["  ]", "  for (lower, upper, expected) in spans {",
                     "    let span : @sturm.Interval = { lower: q(lower.0, lower.1), upper: q(upper.0, upper.1) }",
                     "    let count = count_between(sys, span).unwrap()",
                     "    assert_true(count.count.equal(@oracle.nat(expected)))",
                     "    assert_true(check_count(sys, span, @oracle.nat(expected), count))", "  }",
                     "  let result = finish(isolate(sys).unwrap(), 1000)",
                     f"  assert_true(@core.length(roots(result)).equal(@oracle.nat({total})))",
                     "  assert_true(check_isolation_result(input, result, solution_certificate(result)))", "}"]
    output = ROOT / "src/realtower/flat_fixtures_wbtest.mbt"
    source = "\n".join(rows) + "\n"
    if options.check:
        def syntax(text):
            tokens = [token for token in re.findall(r'//[^\n]*|"(?:\\.|[^"\\])*"|[^\s]', text)
                      if not token.startswith("//")]
            return [token for i, token in enumerate(tokens)
                    if not (token == "," and i + 1 < len(tokens) and tokens[i + 1] in ")]}")]
        if not output.exists() or syntax(output.read_text()) != syntax(source):
            raise SystemExit("Generated fixture syntax differs; regenerate and run moon fmt.")
    else:
        output.write_text(source)
    action = "Verified" if options.check else "Generated"
    print(f"{action} {scalar_count} exact scalar quotients and {root_count} relative root-count queries across depths 0..3; {root_count // 6} full covers.")


if __name__ == "__main__":
    main()
