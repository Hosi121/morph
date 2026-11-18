#!/usr/bin/env python3
"""Fraction Hodge oracle: invert compound(g), rather than minors of inverse(g)."""
from argparse import ArgumentParser
from fractions import Fraction as Q
from itertools import combinations, permutations
from math import isqrt
from pathlib import Path
import subprocess

from generate_forms_fixtures import add_poly, multiply_poly, normalize

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'src/hodge/fraction_fixtures_wbtest.mbt'


def determinant(a):
    n = len(a)
    result = Q(0)
    for p in permutations(range(n)):
        value = Q((-1) ** sum(p[i] > p[j] for i in range(n) for j in range(i + 1, n)))
        for i, j in enumerate(p):
            value *= a[i][j]
        result += value
    return result


def inverse(a):
    n = len(a)
    rows = [[Q(x) for x in row] + [Q(i == j) for j in range(n)] for i, row in enumerate(a)]
    for i in range(n):
        pivot = next(j for j in range(i, n) if rows[j][i])
        rows[i], rows[pivot] = rows[pivot], rows[i]
        q = rows[i][i]
        rows[i] = [x / q for x in rows[i]]
        for j in range(n):
            if i != j:
                q = rows[j][i]
                rows[j] = [x - q * y for x, y in zip(rows[j], rows[i])]
    return [row[n:] for row in rows]


def metric_data(g, k):
    n = len(g)
    bases = list(combinations(range(n), k))
    compound = [[determinant([[g[r][c] for c in j] for r in i]) for j in bases] for i in bases]
    gram = inverse(compound)
    complements, signs = [], []
    for basis in bases:
        complement = tuple(i for i in range(n) if i not in basis)
        ordered = basis + complement
        signs.append((-1) ** sum(ordered[i] > ordered[j] for i in range(n) for j in range(i + 1, n)))
        complements.append(complement)
    d = determinant(g)
    nr, dr = isqrt(d.numerator), isqrt(d.denominator)
    root = Q(nr, dr) if nr * nr == d.numerator and dr * dr == d.denominator else None
    return bases, complements, signs, gram, d, root


def scaled(a, q):
    return {i: {e: v * q for e, v in p.items()} for i, p in a.items() if q}


def add(a, b):
    return normalize([(p, i) for form in (a, b) for i, p in form.items()])


def canonical(a, b, root):
    return (add(a, scaled(b, root)), {}) if root is not None else (a, b)


def transformed(a, data, negative):
    bases, complements, signs, gram, _, _ = data
    raw = []
    for complement, sign, row in zip(complements, signs, gram):
        p = {}
        for basis, q in zip(bases, row):
            p = add_poly(p, {e: v * q * sign * (-1 if negative else 1) for e, v in a.get(basis, {}).items()})
        raw.append((p, complement))
    return normalize(raw)


def star(a, b, data, negative):
    return canonical(scaled(transformed(b, data, negative), data[4]), transformed(a, data, negative), data[5])


def bilinear(a, b, bases, gram):
    result = {}
    for i, row in zip(bases, gram):
        for j, q in zip(bases, row):
            product = multiply_poly(a.get(i, {}), b.get(j, {}))
            result = add_poly(result, {e: v * q for e, v in product.items()})
    return {(): result} if result else {}


def inner(a, b, data):
    bases, _, _, gram, d, root = data
    aa = bilinear(a[0], b[0], bases, gram)
    bb = bilinear(a[1], b[1], bases, gram)
    ab = bilinear(a[0], b[1], bases, gram)
    ba = bilinear(a[1], b[0], bases, gram)
    return canonical(add(aa, scaled(bb, d)), add(ab, ba), root)


def input_form(n, bases, shift):
    raw = []
    for i, basis in enumerate(bases):
        p = {(0,) * n: Q((-1) ** (i + shift) * (i + shift + 1), 2 + shift)}
        if n:
            exponent = tuple(1 if j == (i + shift) % n else 0 for j in range(n))
            p = add_poly(p, {exponent: Q(i + 1, 3 + shift)})
        raw.append((p, basis))
    return normalize(raw)


def cases():
    metrics = [[]]
    for n in range(1, 5):
        metrics.extend([
            [[Q(i == j) for j in range(n)] for i in range(n)],
            [[Q(i + 2 if i == j else 0) for j in range(n)] for i in range(n)],
            [[Q(2 if i == j else 1 if abs(i - j) == 1 else 0) for j in range(n)] for i in range(n)],
        ])
    metrics.extend([
        [[Q(4, 9), Q(0)], [Q(0), Q(25, 16)]],
        [[Q(1, 2), Q(1, 3)], [Q(1, 3), Q(2, 3)]],
        [[Q(2), Q(1), Q(0)], [Q(1), Q(3), Q(1)], [Q(0), Q(1), Q(2)]],
    ])
    for g in metrics:
        for k in range(len(g) + 1):
            data = metric_data(g, k)
            for negative in (False, True):
                inputs = [input_form(len(g), data[0], shift) for shift in range(4)]
                a = canonical(inputs[0], inputs[1], data[5])
                b = canonical(inputs[2], inputs[3], data[5])
                yield dict(g=g, k=k, negative=negative, data=data, inputs=inputs,
                           star=star(*a, data, negative), inner=inner(a, b, data))


def rat(q):
    q = Q(q)
    assert -(2 ** 31) <= q.numerator < 2 ** 31 and 0 < q.denominator < 2 ** 31
    return f'({q.numerator}, {q.denominator})'


def matrix(a):
    return '[' + ', '.join('[' + ', '.join(map(rat, row)) + ']' for row in a) + ']'


def form(a):
    terms = []
    for i, p in sorted(a.items()):
        coefficients = ', '.join(f'({q.numerator}, {q.denominator}, {list(e)})' for e, q in sorted(p.items(), reverse=True))
        for q in p.values():
            rat(q)
        terms.append(f'([{coefficients}], {list(i)})')
    return '[' + ', '.join(terms) + ']'


def render():
    lines = ['// Generated by tools/generate_hodge_fixtures.py; compound-metric inversion oracle.', '']
    count = 0
    for count, case in enumerate(cases(), 1):
        data = case['data']
        args = [str(len(case['g'])), str(case['k']), matrix(case['g']), str(case['negative']).lower(),
                rat(data[4]), 'None' if data[5] is None else 'Some(' + rat(data[5]) + ')', matrix(data[3])]
        args.extend(map(form, case['inputs'] + list(case['star']) + list(case['inner'])))
        lines.extend(['///|', f'test "Fraction compound Hodge reference {count}" {{',
                      '  hf_fixture(' + ', '.join(args) + ')', '}', ''])
    return '\n'.join(lines), count


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    text, count = render()
    formatted = subprocess.run([str(ROOT / '.tools/moon/bin/moonfmt'), '-'], input=text,
                               capture_output=True, text=True, check=True).stdout
    if args.check:
        if not OUTPUT.is_file() or OUTPUT.read_text() != formatted:
            raise SystemExit('Hodge Fraction fixture drift')
    else:
        OUTPUT.write_text(formatted)
    print(f'{count} complete Hodge/compound-metric/inner-product cases, dimensions zero through four, both orientations.')


if __name__ == '__main__':
    main()
