#!/usr/bin/env python3
"""Independent finite GF(2) persistence fixtures, without persistence reduction.

For EVERY pair of prefixes P <= Q and each tested dimension, construct Z(P)
by row-RREF nullspaces and B(Q) from actual boundary vectors in common final
simplex coordinates. Compute rho(P,Q)=rank([Z(P), B(Q)])-rank(B(Q)), equivalently
dim Z(P)-dim(Z(P) intersection B(Q)). Recover intervals by differences of rho.
No MoonBit invocation, sparse column persistence reduction, or external library.
"""

from __future__ import annotations

import argparse
from fractions import Fraction
from itertools import combinations
from pathlib import Path
import random
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "src/persistence/fixtures_wbtest.mbt"

# Sage's six-vertex RealProjectivePlane triangulation (see research note).
RP2 = [(0, 1, 2), (0, 2, 3), (0, 1, 5), (0, 4, 5), (0, 3, 4),
       (1, 2, 4), (1, 3, 4), (1, 3, 5), (2, 3, 5), (2, 4, 5)]


def closure(facets):
    return {s for f in facets for k in range(1, len(f) + 1)
            for s in combinations(f, k)}


def facets_of(simplex):
    return [simplex[:i] + simplex[i + 1:] for i in range(len(simplex))
            if len(simplex) > 1]


def rref(rows, width):
    rows = list(rows)
    pivots = []
    for column in range(width):
        found = next((i for i in range(len(pivots), len(rows))
                      if rows[i] & (1 << column)), None)
        if found is None:
            continue
        pivot = len(pivots)
        rows[pivot], rows[found] = rows[found], rows[pivot]
        for i in range(len(rows)):
            if i != pivot and rows[i] & (1 << column):
                rows[i] ^= rows[pivot]
        pivots.append(column)
    return rows[:len(pivots)], pivots


def nullspace(rows, width):
    reduced, pivots = rref(rows, width)
    result = []
    for free in range(width):
        if free in pivots:
            continue
        vector = 1 << free
        for row, pivot in zip(reduced, pivots):
            if row & (1 << free):
                vector |= 1 << pivot
        assert all((row & vector).bit_count() % 2 == 0 for row in rows)
        result.append(vector)
    return result


def rank(vectors, ambient):
    # Treat the vectors as rows, independent of the filtration's column order.
    return len(rref(vectors, ambient)[1])


def invariant(simplices, degree):
    ambient = [s for s in simplices if len(s) == degree + 1]
    coordinates = {s: i for i, s in enumerate(ambient)}
    lower = [s for s in simplices if len(s) == degree] if degree else []
    cycles, boundaries = [], []
    for prefix in range(len(simplices) + 1):
        active = [s for s in simplices[:prefix] if len(s) == degree + 1]
        rows = [sum(1 << j for j, s in enumerate(active)
                    if face in facets_of(s)) for face in lower]
        local = nullspace(rows, len(active))
        cycles.append([sum(1 << coordinates[s] for j, s in enumerate(active)
                           if vector & (1 << j)) for vector in local])
        boundaries.append([sum(1 << coordinates[face] for face in facets_of(s))
                           for s in simplices[:prefix] if len(s) == degree + 2])
    rho = {}
    for p in range(len(simplices) + 1):
        for q in range(p, len(simplices) + 1):
            b = boundaries[q]
            rho[p, q] = rank(cycles[p] + b, len(ambient)) - rank(b, len(ambient))
            assert 0 <= rho[p, q] <= len(cycles[p])
    return rho


def intervals(simplices, ranks):
    n = len(simplices)
    result = []
    for birth, simplex in enumerate(simplices):
        k = len(simplex) - 1
        rho = ranks[k]
        for death in range(birth + 1, n):
            count = (rho[birth + 1, death] - rho[birth, death]
                     - rho[birth + 1, death + 1] + rho[birth, death + 1])
            assert count in (0, 1)
            result.extend([(k, birth, death)] * count)
        count = rho[birth + 1, n] - rho[birth, n]
        assert count in (0, 1)
        result.extend([(k, birth, -1)] * count)
    for k, rho in enumerate(ranks):
        for (p, q), expected in rho.items():
            assert sum(1 for dim, b, d in result
                       if dim == k and b < p and (d < 0 or q <= d)) == expected
    return result


def legal_orders(simplices):
    def walk(prefix, rest):
        if not rest:
            yield prefix
        else:
            for simplex in sorted(rest):
                if all(face in prefix for face in facets_of(simplex)):
                    yield from walk(prefix + [simplex], rest - {simplex})
    return walk([], set(simplices))


def fixtures():
    possible = [s for k in range(1, 5) for s in combinations(range(4), k)]
    small = []
    for mask in range(1 << len(possible)):
        faces = {s for i, s in enumerate(possible) if mask & (1 << i)}
        if closure(faces) == faces:
            small.append(sorted(faces, key=lambda s: (len(s), s)))
    assert len(small) == 167
    result = [(s, [Fraction(2 * i - 3, 3) for i in range(len(s))]) for s in small]
    # All linear extensions of the full triangle, with ties that collapse
    # selected simplex intervals. These include interleaved dimensions.
    triangle = closure([(0, 1, 2)])
    orders = list(legal_orders(triangle))
    assert len(orders) == 48
    result.extend((s, [Fraction(i // 3, 2) for i in range(len(s))]) for s in orders)
    tetrahedron = closure([(0, 1, 2, 3)])
    for seed in range(12):
        rng, order, rest = random.Random(seed), [], set(tetrahedron)
        while rest:
            ready = sorted(s for s in rest if all(f in order for f in facets_of(s)))
            simplex = rng.choice(ready)
            order.append(simplex)
            rest.remove(simplex)
        result.append((order, [Fraction(i // 4 - 1, 3) for i in range(len(order))]))
    rp = sorted(closure(RP2), key=lambda s: (len(s), s))
    result.append((rp, [Fraction(len(s) - 1, 2) for s in rp]))
    result.append((rp, [Fraction(i, 5) for i in range(len(rp))]))
    result.append((sorted(triangle, key=lambda s: (len(s), s)), [Fraction(0)] * 7))
    return result


def array(value):
    if isinstance(value, (list, tuple)):
        return "[" + ", ".join(array(v) for v in value) + "]"
    return str(value)


def render():
    records, comparisons = [], 0
    for simplices, grades in fixtures():
        degrees = max((len(s) for s in simplices), default=0) + 1
        ranks = [invariant(simplices, k) for k in range(degrees)]
        spans = intervals(simplices, ranks)
        if simplices == sorted(closure(RP2), key=lambda s: (len(s), s)):
            assert [sum(1 for k, _, d in spans if k == dim and d < 0)
                    for dim in range(3)] == [1, 1, 1]
        flat = [rho[p, q] for rho in ranks
                for p in range(len(simplices) + 1)
                for q in range(p, len(simplices) + 1)]
        comparisons += len(flat)
        span_text = "[" + ", ".join(f"({k}, {b}, {d})" for k, b, d in spans) + "]"
        grade_text = "[" + ", ".join(f"({g.numerator}, {g.denominator})" for g in grades) + "]"
        records.append(f"    ({array(simplices)}, {grade_text}, {degrees}, "
                       f"{array(flat)}, {span_text}),")
    return ("// Generated by tools/generate_persistence_fixtures.py; do not edit.\n"
            f"// {len(records)} filtrations; {comparisons} degree/prefix-pair rank comparisons.\n\n"
            "///|\nfn persistence_fixtures() -> Array[(Array[Array[Int32]], Array[(Int32, Int32)], Int32, Array[Int32], Array[(Int32, Int32, Int32)])] {\n"
            "  [\n" + "\n".join(records) + "\n  ]\n}\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    formatter = ROOT / ".tools/moon/bin/moonfmt"
    executable = str(formatter) if formatter.exists() else shutil.which("moonfmt")
    if executable is None:
        raise SystemExit("moonfmt is required to canonicalize generated MoonBit fixtures")
    content = subprocess.run([executable, "-"], input=render(), text=True,
                             check=True, capture_output=True).stdout
    if args.check:
        if OUTPUT.read_text() != content:
            raise SystemExit("persistence fixtures differ; regenerate and format the generated file")
        print(content.splitlines()[1])
    else:
        OUTPUT.write_text(content)
        print(content.splitlines()[1])


if __name__ == "__main__":
    main()
