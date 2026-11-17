#!/usr/bin/env python3
"""Independent relative fixtures: bitmask boundaries, Fraction kernels, integer minors.

No MoonBit, Smith reduction, external algebra library or production fixture import.
All pairs on three labelled vertices and every subcomplex of the full tetrahedron
are enumerated. Relative connecting ranks are computed directly from rational
cycle lifts and boundaries in A. Maximal minor gcd independently detects RP2
relative torsion and the index-two image into the full 1-skeleton.
"""
from __future__ import annotations

import argparse
from fractions import Fraction
from itertools import combinations
from math import gcd
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "src/relativehomology/fixtures_wbtest.mbt"
RP2 = [(0,1,2), (0,2,3), (0,1,5), (0,4,5), (0,3,4),
       (1,2,4), (1,3,4), (1,3,5), (2,3,5), (2,4,5)]


def simplex(vertices):
    return sum(1 << v for v in vertices)


def closure(facets):
    result = set()
    for f in facets:
        sub = f
        while sub:
            result.add(sub)
            sub = (sub - 1) & f
    return result


def ordered(faces, k):
    return sorted((f for f in faces if f.bit_count() == k + 1), key=vertices)


def vertices(mask):
    return [v for v in range(mask.bit_length()) if mask & (1 << v)]


def boundary(kfaces, afaces, degree):
    columns = ordered(kfaces - afaces, degree)
    rows = ordered(kfaces - afaces, degree - 1) if degree else []
    # Bit tests derive incidence, independently of the production face function.
    matrix = [[((-1) ** (s & ((s ^ f) - 1)).bit_count()
                if f & s == f and (s ^ f).bit_count() == 1 else 0)
               for s in columns] for f in rows]
    return matrix, len(columns)


def reduced(matrix, width):
    a = [[Fraction(x) for x in row] for row in matrix]
    pivots = []
    for column in range(width):
        r = len(pivots)
        p = next((i for i in range(r, len(a)) if a[i][column]), None)
        if p is None:
            continue
        a[p], a[r] = a[r], a[p]
        divisor = a[r][column]
        a[r] = [x / divisor for x in a[r]]
        for i in range(len(a)):
            if i != r and a[i][column]:
                factor = a[i][column]
                a[i] = [x - factor * y for x, y in zip(a[i], a[r])]
        pivots.append(column)
    return a, pivots


def rank(matrix, width):
    return len(reduced(matrix, width)[1])


def kernel(matrix, width):
    a, pivots = reduced(matrix, width)
    result = []
    for column in range(width):
        if column in pivots:
            continue
        vector = [Fraction(i == column) for i in range(width)]
        for row, pivot in enumerate(pivots):
            vector[pivot] = -a[row][column]
        result.append(vector)
    return result


def connecting_rank(kfaces, afaces, degree):
    relative, w = boundary(kfaces, afaces, degree)
    cycles = kernel(relative, w)
    rel_basis = ordered(kfaces - afaces, degree)
    ambient_basis = ordered(kfaces, degree)
    ambient_rows = ordered(kfaces, degree - 1)
    ambient_d, _ = boundary(kfaces, set(), degree)
    a_rows = ordered(afaces, degree - 1)
    columns = []
    for cycle in cycles:
        lifted = [cycle[rel_basis.index(s)] if s in rel_basis else Fraction(0)
                  for s in ambient_basis]
        image = [sum(x*y for x,y in zip(row,lifted)) for row in ambient_d]
        assert all(image[i] == 0 for i,s in enumerate(ambient_rows) if s not in afaces)
        columns.append([image[ambient_rows.index(s)] for s in a_rows])
    d_a, wa = boundary(afaces, set(), degree)
    combined = [row + [column[i] for column in columns] for i,row in enumerate(d_a)]
    return rank(combined, wa + len(columns)) - rank(d_a, wa)


def all_complexes(n):
    return [faces for mask in range(1 << ((1 << n) - 1))
            if closure(faces := {s for s in range(1, 1 << n) if mask & (1 << (s-1))}) == faces]


def facets(faces):
    return [vertices(f) for f in sorted(faces, key=vertices)
            if not any(f != g and f & g == f for g in faces)]


def determinant(matrix):
    if not matrix:
        return 1
    a = [row[:] for row in matrix]
    previous, sign = 1, 1
    for k in range(len(a)-1):
        p = next((i for i in range(k,len(a)) if a[i][k]), None)
        if p is None:
            return 0
        if p != k:
            a[p], a[k] = a[k], a[p]
            sign = -sign
        v = a[k][k]
        for i in range(k+1,len(a)):
            for j in range(k+1,len(a)):
                numerator = a[i][j]*v - a[i][k]*a[k][j]
                assert numerator % previous == 0
                a[i][j] = numerator // previous
            a[i][k] = 0
        previous = v
    return sign*a[-1][-1]


def divisor(matrix, width, r):
    """Gcd of all rank-r minors: index of the image in its saturation."""
    result = 0
    for rows in combinations(range(len(matrix)), r):
        for cols in combinations(range(width), r):
            result = gcd(result, determinant([[matrix[i][j] for j in cols] for i in rows]))
    return result


def torsion_oracles():
    k = closure(map(simplex, RP2))
    for a in [closure([simplex([0])]), closure([simplex([0,v]) for v in range(1,6)])]:
        b, w = boundary(k, a, 2)
        r = rank(b,w)
        assert r == 10
        assert divisor(b,w,r) == 2
        # Since d1*d2=0, coker(d2) -> image(d1) has free target. Thus
        # torsion(coker(d2)) equals torsion(H1), without a Smith computation.
        # The order two torsion product is prime: there is exactly Z/2.
    skeleton = {s for s in k if s.bit_count() <= 2}
    d2, w = boundary(k, set(), 2)
    # d2 has full column rank; the same maximal-minor index is the index of
    # its connecting image in the graph cycle lattice, which is saturated.
    assert w == 10 and divisor(d2,w,10) == 2
    assert len(ordered(skeleton,1)) - rank(*boundary(skeleton,set(),1)) == 10
    return 2


def arr(value):
    if isinstance(value, (tuple,list)):
        return '[' + ', '.join(arr(x) for x in value) + ']'
    return str(value)


def render():
    small = all_complexes(3)
    pairs = [(k,a) for k in small for a in small if a <= k]
    small_count = len(pairs)
    tetrahedron = set(range(1,16))
    pairs += [(tetrahedron,a) for a in all_complexes(4)]
    entries = []
    for k,a in pairs:
        matrices = [boundary(k,a,d) for d in range(5)]
        ranks = [rank(m,w) for m,w in matrices]
        free = [matrices[d][1]-ranks[d]-ranks[d+1] for d in range(4)]
        for d in range(4):
            da, wa = matrices[d]
            db, wb = matrices[d+1]
            assert len(db) == wa
            assert all(sum(da[i][r]*db[r][j] for r in range(wa)) == 0
                       for i in range(len(da)) for j in range(wb))
            # Torsion of H equals torsion of coker(B), because its quotient
            # image(A) is free. A maximal-minor gcd of one proves its absence.
            assert divisor(db, wb, ranks[d+1]) == 1
        connecting = [connecting_rank(k,a,d) for d in range(1,4)]
        entries.append('    (' + ', '.join([arr(facets(k)), arr(facets(a)), arr(free), arr(connecting),
                        arr([m for m,w in matrices[:4]]), arr([w for m,w in matrices[:4]])]) + '),')
    assert torsion_oracles() == 2
    curated = []
    rp = closure(map(simplex, RP2))
    for name, af in [('point', [[0]]), ('tree', [[0,v] for v in range(1,6)])]:
        a = closure(map(simplex, af))
        m, w = boundary(rp,a,2)
        curated += ['///|', f'test "independent RP2 relative {name} integer boundary has torsion product two" {{',
                    f'  let p = example({arr(RP2)}, {arr(af)})',
                    f'  assert_eq(rows(boundary(p, @oracle.nat(2)).unwrap()), {arr(m)})',
                    f'  assert_eq(@matrix.width(boundary(p, @oracle.nat(2)).unwrap()), @oracle.nat({w}))',
                    '  ignore(verify(p, 1, 0, [2]))', '}', '']
    return f'''// Generated by tools/generate_relativehomology_fixtures.py; do not edit.
// {small_count} pairs on three vertices; 167 subcomplexes of the full tetrahedron.
///|
fn independent_pairs() -> Array[(Array[Array[Int]], Array[Array[Int]], Array[Int], Array[Int], Array[Array[Array[Int]]], Array[Int])] {{
  [
{chr(10).join(entries)}
  ]
}}

///|
fn rational_rank(input : Array[Array[Int]], width : Int) -> Int {{
  let a = input.map(fn(row) {{ row.map(fn(x) {{ @oracle.rational(x, 1) }}) }})
  let mut r = 0
  for column in 0..<width {{
    let mut p = r
    while p < a.length() && @exact.rational_compare(a[p][column], @exact.rational_zero()) is Equal {{ p = p + 1 }}
    if p == a.length() {{ continue }}
    let row = a[r]
    a[r] = a[p]
    a[p] = row
    let divisor = a[r][column]
    a[r] = a[r].map(fn(x) {{ @exact.rational_divide(x, divisor).unwrap() }})
    for i in (r + 1)..<a.length() {{
      let factor = a[i][column]
      for j in column..<width {{
        a[i][j] = @exact.rational_subtract(a[i][j], @exact.rational_multiply(factor, a[r][j]))
      }}
    }}
    r = r + 1
  }}
  r
}}

///|
test "independent bitmask Fraction oracle checks all finite relative pairs and connecting ranks" {{
  for fixture in independent_pairs() {{
    let (kf, af, free, delta_rank, matrices, widths) = fixture
    let source = example(kf, af)
    for degree in 0..<4 {{
      ignore(verify(source, degree, free[degree], []))
      let d = boundary(source, @oracle.nat(degree)).unwrap()
      assert_eq(rows(d), matrices[degree])
      assert_eq(@matrix.width(d), @oracle.nat(widths[degree]))
      if degree > 0 {{
        let delta = connecting(source, degree)
        assert_eq(rational_rank(rows(delta.classes), @oracle.int_of_nat(@matrix.width(delta.classes))), delta_rank[degree - 1])
      }}
    }}
  }}
}}

{chr(10).join(curated)}'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check',action='store_true')
    args = parser.parse_args()
    formatter = ROOT / ".tools/moon/bin/moonfmt"
    executable = str(formatter) if formatter.exists() else shutil.which("moonfmt")
    if executable is None:
        raise SystemExit("moonfmt is required to canonicalize generated fixtures")
    text = subprocess.run([executable, "-"], input=render(), text=True,
                          check=True, capture_output=True).stdout
    if args.check:
        if OUTPUT.read_text() != text:
            raise SystemExit('relative fixtures are stale; regenerate them')
        print('Independent relative fixtures match bitmask/Fraction/minors oracle.')
    else:
        OUTPUT.write_text(text)
        print(f'Wrote {OUTPUT.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
