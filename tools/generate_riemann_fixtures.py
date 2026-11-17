#!/usr/bin/env python3
"""Independent exact pointwise geometry fixtures (Python Fraction, no Moon helpers).

Metric jets are obtained by second-order automatic differentiation of rational
coordinate expressions. Curvature is computed by differentiating the inverse
metric and the second-kind Christoffel formula. The MoonBit kernel instead uses
the covariant metric-second-derivative formula and raises its first index later.
Known flat and constant-curvature models independently constrain both routes.
"""
from __future__ import annotations

from dataclasses import dataclass
from fractions import Fraction as Q
from pathlib import Path
import argparse
import itertools
import subprocess

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / 'src/riemann/fixtures_wbtest.mbt'


@dataclass(frozen=True)
class D2:
    value: Q
    first: tuple[Q, ...]
    second: tuple[tuple[Q, ...], ...]

    @classmethod
    def constant(cls, value, n):
        return cls(Q(value), (Q(0),) * n, ((Q(0),) * n,) * n)

    @classmethod
    def variable(cls, value, n, index):
        return cls(Q(value), tuple(Q(i == index) for i in range(n)), ((Q(0),) * n,) * n)

    def coerce(self, value):
        return value if isinstance(value, D2) else D2.constant(value, len(self.first))

    def __add__(self, other):
        other = self.coerce(other)
        n = len(self.first)
        return D2(self.value + other.value,
                  tuple(a + b for a, b in zip(self.first, other.first)),
                  tuple(tuple(self.second[i][j] + other.second[i][j] for j in range(n)) for i in range(n)))

    __radd__ = __add__

    def __neg__(self):
        return self * -1

    def __sub__(self, other):
        return self + -self.coerce(other)

    def __rsub__(self, other):
        return -self + other

    def __mul__(self, other):
        other = self.coerce(other)
        n = len(self.first)
        return D2(self.value * other.value,
                  tuple(self.first[i] * other.value + self.value * other.first[i] for i in range(n)),
                  tuple(tuple(self.second[i][j] * other.value + self.first[i] * other.first[j]
                              + self.first[j] * other.first[i] + self.value * other.second[i][j]
                              for j in range(n)) for i in range(n)))

    __rmul__ = __mul__

    def reciprocal(self):
        n, v = len(self.first), self.value
        return D2(1 / v, tuple(-x / v**2 for x in self.first),
                  tuple(tuple(2 * self.first[i] * self.first[j] / v**3 - self.second[i][j] / v**2
                              for j in range(n)) for i in range(n)))

    def __truediv__(self, other):
        return self * self.coerce(other).reciprocal()

    def __rtruediv__(self, other):
        return self.reciprocal() * other

    def __pow__(self, power):
        if power < 0:
            return self.reciprocal() ** -power
        result = D2.constant(1, len(self.first))
        for _ in range(power):
            result = result * self
        return result


def jets(expressions):
    n = len(expressions)
    return ([[a.value for a in row] for row in expressions],
            [[[expressions[i][j].first[k] for j in range(n)] for i in range(n)] for k in range(n)],
            [[[[expressions[i][j].second[k][l] for j in range(n)] for i in range(n)] for l in range(n)] for k in range(n)])


def inverse(matrix):
    n = len(matrix)
    a = [list(row) + [Q(i == j) for j in range(n)] for i, row in enumerate(matrix)]
    for k in range(n):
        pivot = next(i for i in range(k, n) if a[i][k])
        a[k], a[pivot] = a[pivot], a[k]
        coefficient = a[k][k]
        a[k] = [x / coefficient for x in a[k]]
        for i in range(n):
            if i != k:
                coefficient = a[i][k]
                a[i] = [x - coefficient * y for x, y in zip(a[i], a[k])]
    return [row[n:] for row in a]


def determinant(matrix):
    if not matrix:
        return Q(1)
    return sum(((-1)**j * value * determinant([row[:j] + row[j+1:] for row in matrix[1:]])
                for j, value in enumerate(matrix[0])), Q(0))


def geometry(g, d, h):
    n = len(g)
    gi = inverse(g)
    low = [[[(d[j][i][k] + d[k][i][j] - d[i][j][k]) / 2
             for k in range(n)] for j in range(n)] for i in range(n)]
    gamma = [[[sum((gi[i][a] * low[a][j][k] for a in range(n)), Q(0))
               for k in range(n)] for j in range(n)] for i in range(n)]
    di = [[[-sum((gi[i][a] * d[k][a][b] * gi[b][j] for a in range(n) for b in range(n)), Q(0))
            for j in range(n)] for i in range(n)] for k in range(n)]
    dg = [[[[sum((di[k][i][a] * low[a][j][l]
                  + gi[i][a] * (h[k][j][a][l] + h[k][l][a][j] - h[k][a][j][l]) / 2
                  for a in range(n)), Q(0))
             for l in range(n)] for j in range(n)] for i in range(n)] for k in range(n)]
    upper = [[[[dg[k][i][l][j] - dg[l][i][k][j]
                + sum((gamma[i][k][a] * gamma[a][l][j] - gamma[i][l][a] * gamma[a][k][j]
                       for a in range(n)), Q(0))
                for l in range(n)] for k in range(n)] for j in range(n)] for i in range(n)]
    lower = [[[[sum((g[i][a] * upper[a][j][k][l] for a in range(n)), Q(0))
                for l in range(n)] for k in range(n)] for j in range(n)] for i in range(n)]
    ricci = [[sum((upper[i][j][i][l] for i in range(n)), Q(0)) for l in range(n)] for j in range(n)]
    scalar = sum((gi[i][j] * ricci[i][j] for i in range(n) for j in range(n)), Q(0))
    positive = all(determinant([row[:k] for row in g[:k]]) > 0 for k in range(1, n + 1))
    return dict(inverse=gi, first_kind=low, second_kind=gamma, lower=lower, upper=upper,
                ricci=ricci, scalar=scalar, positive=positive)


def validate(g, d, h, result, expected_curvature=None):
    n = len(g)
    gi, gamma, lower, ricci = (result[k] for k in ('inverse', 'second_kind', 'lower', 'ricci'))
    for i, j in itertools.product(range(n), repeat=2):
        assert sum(g[i][a] * gi[a][j] for a in range(n)) == (i == j)
        assert g[i][j] == g[j][i] and ricci[i][j] == ricci[j][i]
    for i, j, k in itertools.product(range(n), repeat=3):
        assert gamma[i][j][k] == gamma[i][k][j]
        # Metric compatibility, independently relating first jet to second-kind symbols.
        assert d[k][i][j] == sum(g[a][j] * gamma[a][k][i] + g[i][a] * gamma[a][k][j] for a in range(n))
    for i, j, k, l in itertools.product(range(n), repeat=4):
        r = lower[i][j][k][l]
        assert r == -lower[j][i][k][l] == -lower[i][j][l][k] == lower[k][l][i][j]
        assert r + lower[i][k][l][j] + lower[i][l][j][k] == 0
        if expected_curvature is not None:
            assert r == expected_curvature * (g[i][k] * g[j][l] - g[i][l] * g[j][k])
    if expected_curvature is not None:
        assert result['scalar'] == n * (n - 1) * expected_curvature


def fixture(name, expressions, expected_curvature=None):
    g, d, h = jets(expressions)
    result = geometry(g, d, h)
    validate(g, d, h, result, expected_curvature)
    return dict(name=name, n=len(g), metric=g, first=d, second=h, **result)


def diagonal(expressions):
    n = len(expressions)
    return [[expressions[i] if i == j else D2.constant(0, n) for j in range(n)] for i in range(n)]


def sphere(point, radius=Q(1), transform=None, shear=False):
    n = len(point)
    variables = [D2.variable(value, n, i) for i, value in enumerate(point)]
    if shear:
        assert n == 2
        x, y = variables
        coordinates = [x, y + x*x]
        jacobian = [[D2.constant(1, n), D2.constant(0, n)], [2*x, D2.constant(1, n)]]
    else:
        transform = transform or [[Q(i == j) for j in range(n)] for i in range(n)]
        coordinates = [sum((transform[i][j] * variables[j] for j in range(n)), D2.constant(0, n)) for i in range(n)]
        jacobian = [[D2.constant(value, n) for value in row] for row in transform]
    scale = 4 * radius**2 / (1 + sum((x*x for x in coordinates), D2.constant(0, n)))**2
    return [[scale * sum((jacobian[a][i] * jacobian[a][j] for a in range(n)), D2.constant(0, n))
             for j in range(n)] for i in range(n)]


def fixtures():
    z2 = D2.constant(0, 2)
    cases = [fixture('dimension_zero', [], Q(0)),
             fixture('flat_euclidean', diagonal([D2.constant(1, 2), D2.constant(1, 2)]), Q(0)),
             fixture('flat_indefinite_null_basis', [[z2, z2+1], [z2+1, z2]], Q(0))]
    x = D2.variable(Q(2), 1, 0)
    cases.append(fixture('one_dimensional_nonconstant', [[1+x*x]], Q(0)))
    for radius in (Q(1), Q(3, 2), Q(2, 3)):
        r = D2.variable(radius, 2, 0)
        cases.append(fixture('flat_polar_' + str(radius).replace('/', '_'), diagonal([r*0+1, r*r]), Q(0)))
    x = D2.variable(Q(1, 2), 2, 0)
    cases.append(fixture('flat_nonlinear_shear', [[1+4*x*x, 2*x], [2*x, z2+1]], Q(0)))
    for point, radius in [([Q(0), Q(0)], Q(1)), ([Q(1, 2), Q(1, 3)], Q(1)),
                          ([Q(-1), Q(2)], Q(3, 2))]:
        cases.append(fixture('sphere_' + str(len(cases)), sphere(point, radius), 1/radius**2))
    cases.append(fixture('sphere_affine_chart', sphere([Q(1, 2), Q(0)], transform=[[Q(1), Q(1)], [Q(0), Q(2)]]), Q(1)))
    cases.append(fixture('sphere_nonlinear_chart', sphere([Q(1, 2), Q(0)], shear=True), Q(1)))
    cases.append(fixture('three_sphere', sphere([Q(1, 2), Q(0), Q(-1, 2)]), Q(1)))
    y = D2.variable(Q(3, 2), 2, 1)
    cases.append(fixture('hyperbolic_upper_half_plane', diagonal([1/(y*y), 1/(y*y)]), Q(-1)))
    t = D2.variable(Q(2), 2, 0)
    cases.append(fixture('lorentz_de_sitter', diagonal([-1/(t*t), 1/(t*t)]), Q(1)))
    # A general symmetric metric jet: no diagonal/conformal sparsity assumptions.
    n = 3
    value = [[Q(3), Q(1), Q(0)], [Q(1), Q(4), Q(1)], [Q(0), Q(1), Q(2)]]
    d = [[[Q((k+1)*(i+j+1) % 7 - 3, 3) for j in range(n)] for i in range(n)] for k in range(n)]
    h = [[[[Q((k+l+1)*(i+j+1) % 5 - 2, 2) for j in range(n)] for i in range(n)] for l in range(n)] for k in range(n)]
    expressions = [[D2(value[i][j], tuple(d[k][i][j] for k in range(n)),
                       tuple(tuple(h[k][l][i][j] for l in range(n)) for k in range(n)))
                    for j in range(n)] for i in range(n)]
    cases.append(fixture('general_three_dimensional_jet', expressions))
    # Affine-coordinate scalar invariance at the same sphere point.
    transformed = next(f for f in cases if f['name'] == 'sphere_affine_chart')
    original = fixture('unemitted_affine_reference', sphere([Q(1, 2), Q(0)]), Q(1))
    assert transformed['scalar'] == original['scalar']
    return cases


def literal(value):
    if isinstance(value, bool):
        return str(value).lower()
    if isinstance(value, str):
        return '"' + value + '"'
    if isinstance(value, Q):
        assert abs(value.numerator) < 2**31 and value.denominator < 2**31, value
        return f'({value.numerator}, {value.denominator})'
    if isinstance(value, int):
        return str(value)
    return '[' + ', '.join(literal(x) for x in value) + ']'


def generated():
    entries = []
    for item in fixtures():
        fields = ',\n'.join(f'      {key}: {literal(value)}' for key, value in item.items())
        entries.append('    {\n' + fields + ',\n    }')
    return ('// Generated by tools/generate_riemann_fixtures.py; do not edit.\n'
            '// Fraction AD of rational charts, differentiated-inverse curvature oracle.\n\n'
            '///|\nfn independent_fixtures() -> Array[Fixture] {\n  [\n' + ',\n'.join(entries) + ',\n  ]\n}\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    result = subprocess.run([str(ROOT / '.tools/moon/bin/moonfmt'), '-'],
                            input=generated(), text=True, check=True, capture_output=True).stdout
    if args.check:
        if OUTPUT.read_text() != result:
            raise SystemExit('riemann fixtures drift; regenerate')
        print(f'riemann Fraction oracle: {len(fixtures())} complete fixtures verified')
    else:
        OUTPUT.write_text(result)
        print(f'wrote {len(fixtures())} complete fixtures to {OUTPUT.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
