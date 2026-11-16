#!/usr/bin/env python3
"""Finite independent C1/C2/S3/D4 root-permutation and exact action oracle."""

from argparse import ArgumentParser
from collections import Counter
from fractions import Fraction as Q
from itertools import permutations
from math import factorial
from pathlib import Path
import json
import subprocess
import sys

import sympy as sp

sys.dont_write_bytecode = True
from generate_complexsubfield_fixtures import (
    Ambient, RADICAL_BOUNDS, T, array, arrays, coefficients,
)

ROOT = Path(__file__).resolve().parents[1]
C, R, J = sp.symbols("c r j")


def integers(values):
    return "[" + ", ".join(map(str, values)) + "]"


def integer_rows(values):
    return "[" + ", ".join(integers(row) for row in values) + "]"


def compose(left, right):
    return tuple(left[j] for j in right)


def cycle_type(permutation):
    unseen, lengths = set(range(len(permutation))), []
    while unseen:
        start = min(unseen)
        value, length = start, 0
        while value in unseen:
            unseen.remove(value)
            length += 1
            value = permutation[value]
        assert value == start
        lengths.append(length)
    return tuple(sorted(lengths))


def finite_group(accepted):
    accepted = sorted(set(tuple(p) for p in accepted))
    identity = tuple(range(len(accepted[0])))
    index = {p: j for j, p in enumerate(accepted)}
    table = [[index[compose(left, right)] for right in accepted] for left in accepted]
    unit = index[identity]
    inverses = [next(k for k in range(len(accepted)) if table[j][k] == table[k][j] == unit)
                for j in range(len(accepted))]
    for a in range(len(accepted)):
        assert sorted(table[a]) == list(range(len(accepted)))
        assert table[a][unit] == table[unit][a] == a
        for b in range(len(accepted)):
            for c in range(len(accepted)):
                assert table[table[a][b]][c] == table[a][table[b][c]]
    center = [a for a in range(len(accepted)) if all(table[a][b] == table[b][a] for b in range(len(accepted)))]
    derived = {unit}
    for a in range(len(accepted)):
        for b in range(len(accepted)):
            derived.add(table[table[table[a][b]][inverses[a]]][inverses[b]])
    while True:
        enlarged = derived | {table[a][b] for a in derived for b in derived}
        if enlarged == derived:
            break
        derived = enlarged
    return dict(permutations=accepted, table=table, identity=unit, inverses=inverses,
                center=len(center), derived=len(derived),
                cycles=dict(Counter(str(cycle_type(p)) for p in accepted)))


def fixture(name, ambient, minimum, abstract_roots, model, mode, samples, excluded=(), root_sign=1):
    cube, sqrt3 = sp.real_root(2, 3), sp.sqrt(3)
    base_c = cube if ambient.degree == 6 else (sp.S.Zero if ambient.degree == 1 else ambient.alpha)
    base = {C: base_c, R: sqrt3, J: sp.I}
    alpha_abstract = C + R if ambient.degree == 6 else C
    roots = [sp.expand(root.subs(base, simultaneous=True)) for root in abstract_roots]
    root_vectors = [ambient.vector(root) for root in roots]
    assert len(set(roots)) == len(roots)
    assert sp.Poly(sp.expand(sp.prod(T-root for root in roots)), T).monic() == sp.Poly(minimum, T).monic()
    group = finite_group([p for p, _ in model])
    all_permutations = set(permutations(range(len(roots))))
    assert set(group["permutations"]) <= all_permutations
    substitutions = {tuple(p): images for p, images in model}
    sample_expressions = [sp.expand(sample.subs(base, simultaneous=True)) for sample in samples]
    sample_vectors = [ambient.vector(value) for value in sample_expressions]
    total = [a+b for a, b in zip(*sample_vectors)]
    product = ambient.multiply(*sample_vectors)
    actions, image_samples = [], []
    for permutation in group["permutations"]:
        images = substitutions[permutation]
        alpha_image = ambient.vector(sp.expand(alpha_abstract.subs(images, simultaneous=True)))
        imaginary_image = ambient.vector(images[J])
        columns = [ambient.power(alpha_image, j) for j in range(ambient.degree)]
        columns += [ambient.multiply(imaginary_image, column) for column in columns]
        matrix = sp.Matrix.hstack(*(sp.Matrix(column) for column in columns))
        assert matrix.det() != 0
        for j, vector in enumerate(root_vectors):
            assert list(matrix * sp.Matrix(vector)) == root_vectors[permutation[j]]
            direct = ambient.vector(sp.expand(abstract_roots[j].subs(images, simultaneous=True)))
            assert direct == root_vectors[permutation[j]]
        expected = [[Q(q) for q in matrix * sp.Matrix(vector)] for vector in [*sample_vectors, total, product]]
        for j, abstract in enumerate(samples):
            assert ambient.vector(sp.expand(abstract.subs(images, simultaneous=True))) == expected[j]
        assert expected[2] == [a+b for a, b in zip(expected[0], expected[1])]
        assert expected[3] == ambient.multiply(expected[0], expected[1])
        actions.append([[Q(q) for q in row] for row in matrix.tolist()])
        image_samples.append(expected)
    # The ambient extensions agree with the root-permutation group law. For
    # S3 and real C2 the chosen extension fixes i; their minimal fields omit it.
    for a, left in enumerate(actions):
        for b, right in enumerate(actions):
            assert sp.Matrix(left) * sp.Matrix(right) == sp.Matrix(actions[group["table"][a][b]])
    return dict(name=name, ambient=ambient, minimum=coefficients(sp.Poly(minimum, T)),
                roots=root_vectors, mode=mode, samples=sample_vectors, actions=actions,
                images=image_samples, excluded=[ambient.vector(value) for value in excluded],
                root_sign=root_sign, **group)


def literal(record):
    ambient = record["ambient"]
    fields = [f'mode: {record["mode"]}', f'real_root_sign: {record["root_sign"]}',
              f'real_minimum: {array(ambient.modulus)}',
              f'lower: @oracle.rational({ambient.interval[0]}, 1)',
              f'upper: @oracle.rational({ambient.interval[1]}, 1)',
              f'polynomial: {array(record["minimum"])}', f'roots: {arrays(record["roots"])}',
              f'degree: {len(record["permutations"])}',
              f'permutations: {integer_rows(record["permutations"])}',
              f'table: {integer_rows(record["table"])}', f'identity: {record["identity"]}',
              f'inverses: {integers(record["inverses"])}',
              'actions: [' + ", ".join(arrays(matrix) for matrix in record["actions"]) + ']',
              f'samples: {arrays(record["samples"])}',
              'images: [' + ", ".join(arrays(images) for images in record["images"]) + ']',
              f'excluded: {arrays(record["excluded"])}']
    return "{\n" + ",\n".join(fields) + ",\n}"


def generate():
    assert sp.__version__ == "1.14.0"
    cube, sqrt3, fourth = sp.real_root(2, 3), sp.sqrt(3), sp.root(2, 4)
    RADICAL_BOUNDS[fourth] = (4, 2, Q(1), Q(2))
    gaussian = Ambient("QQ(i)", sp.S.Zero, (-1, 0), [])
    quadratic = Ambient("QQ(sqrt2,i)", sp.sqrt(2), (1, 2), [sp.sqrt(2)])
    cubic = Ambient("QQ(cbrt2,sqrt3,i)", cube + sqrt3, (2, 3), [cube, sqrt3])
    quartic = Ambient("QQ(fourthroot2,i)", fourth, (1, 2), [fourth])
    identity = {C: 0, R: sqrt3, J: sp.I}
    records = [
        fixture("constant C1", gaussian, 1, [], [((), identity)], 0,
                [sp.Rational(2, 3), sp.Rational(-5, 7)], [sp.I]),
        fixture("linear C1", gaussian, T-2, [sp.Integer(2)], [((0,), identity)], 1,
                [sp.Rational(2, 3), sp.Rational(-5, 7)], [sp.I]),
        fixture("real quadratic C2", quadratic, T**2-2, [C, -C],
                [((0, 1), {C: sp.sqrt(2), R: sqrt3, J: sp.I}),
                 ((1, 0), {C: -sp.sqrt(2), R: sqrt3, J: sp.I})], 2,
                [C+sp.Rational(1, 3), sp.Rational(2, 5)-sp.Rational(3, 2)*C], [sp.I]),
        fixture("Gaussian C2", gaussian, T**2+1, [J, -J],
                [((0, 1), identity), ((1, 0), {C: 0, R: sqrt3, J: -sp.I})], 1,
                [sp.Rational(2, 3)-sp.Rational(3, 5)*J, sp.Rational(1, 2)+sp.Rational(2, 7)*J]),
    ]
    omega = (-1+J*R)/2
    for sign in [1, -1]:
        model = []
        for k in range(3):
            for s in [1, -1]:
                permutation = tuple((k+s*j) % 3 for j in range(3))
                images = {C: cube*((-1+sp.I*sqrt3)/2)**k, R: s*sqrt3, J: sp.I}
                model.append((permutation, images))
        records.append(fixture(f'S3 for t^3{"-2" if sign == 1 else "+2"}', cubic,
                               T**3-2*sign, [sign*C*omega**j for j in range(3)], model, 3,
                               [C+sp.Rational(2, 3)*omega, C*omega-sp.Rational(1, 2)*C**2],
                               [sp.I, sqrt3], sign))
    exponents = [0, 2, 1, 3]
    indices = {e: j for j, e in enumerate(exponents)}
    model = [(tuple(indices[(k+s*e) % 4] for e in exponents), {C: sp.I**k*fourth, R: sqrt3, J: s*sp.I})
             for k in range(4) for s in [1, -1]]
    records.append(fixture("quartic D4", quartic, T**4-2, [C*J**e for e in exponents], model, 0,
                           [sp.Rational(2, 3)-C/2+C**2/5-2*C**3/7+J*(-sp.Rational(3, 5)+2*C/3-C**2/7+C**3/2),
                            sp.Rational(1, 2)+C/3-2*C**2/5+C**3/7+J*(-sp.Rational(2, 3)-C/5+3*C**2/7-C**3/2)]))
    assert [(r["center"], r["derived"]) for r in records[-3:]] == [(1, 3), (1, 3), (2, 2)]
    tests = ["// Generated by tools/generate_splittinggalois_fixtures.py; independent exact oracle.", ""]
    for record in records:
        tests += ["///|", f'test "independent splitting Galois oracle: {record["name"]}" {{',
                  f'  oracle_assert_galois({literal(record)})', "}", ""]
    formatted = subprocess.run([str(ROOT / ".tools/moon/bin/moonfmt"), "-"],
                               input="\n".join(tests), text=True, capture_output=True, check=True).stdout
    stats = dict(cases=len(records), orders=sorted({len(r["permutations"]) for r in records}),
                 accepted_permutations=sum(len(r["permutations"]) for r in records),
                 compositions=sum(len(r["permutations"])**2 for r in records),
                 inverses=sum(len(r["permutations"]) for r in records),
                 root_actions=sum(len(r["roots"])*len(r["permutations"]) for r in records),
                 sample_images=4*sum(len(r["permutations"]) for r in records))
    docs = ["# Independent finite splitting-field Galois oracle (2026-11-17)", "",
            "This oracle fixes finite root-permutation groups using pure host integer permutations, independent of the MoonBit traversal, map order, root order, primitive choice, or producer certificates. It reuses the independent SymPy 1.14.0/Fraction ambient model of generate_complexsubfield_fixtures.py for exact field coordinates. Rational-power inequalities bind each selected real source; no floating approximation or producer output supplies an expectation.", "",
            "C1 covers constant and rational linear polynomials. C2 covers real and Gaussian quadratics. Each cubic t^3-2 and t^3+2 has all six permutations: on roots c*omega^j, the affine actions j -> k+s*j modulo 3, k=0,1,2 and s=+1,-1, are exactly S3. The quartic root order [a,-a,i*a,-i*a] has phase exponents [0,2,1,3]. Exactly eight of its 24 permutations are the D4 affine actions e -> k+s*e modulo 4. The complete accepted permutation SET is compared after reindexing returned roots to these independent canonical values.", "",
            "Composition is left after right, computed directly as left[right[j]]. Python independently derives every table entry and inverse, then checks group laws using integer arithmetic. Cycle types, center sizes, and derived-subgroup sizes below are independently computed finite diagnostics. Exact ambient action matrices substitute c->c*omega^k, sqrt3->s*sqrt3, i->i for S3, and a->i^k*a, i->s*i for D4. Each matrix is checked on every root and by Fraction products; exact SymPy substitution independently checks sample images. The selected S3 extensions fix i in the degree-12 ambient, while apply must reject i and sqrt3 because neither belongs to the minimal degree-6 splitting field.", "",
            "MoonBit obtains linear/quadratic/cubic Splitting handles through solve, and supplies the four exact quartic roots to solve_from_roots. For cubic sources it reconstructs positive cbrt(2) and sqrt3 from the actual ordered roots using exact sign realization and division, yielding the independent real primitive a=cbrt(2)+sqrt3 even if the producer selected another real generator. An exact rational change of coordinates expresses any returned primitive in this independent ambient basis. Applying the external action matrix then pins generator_image without assuming a producer candidate or basis order. Independently populated MapCertificates and the host table are imported as a separate full group certificate. Every map's root action, inverse, composition, sum/product preservation, and externally fixed sample images are checked. Source/result binding and zero-budget pause/resume are included.", "",
            "```json", json.dumps(stats, sort_keys=True), "```", "",
            "| Case | Splitting degree / group order | All root permutations | Accepted | Center order | Derived order | Cycle-type counts |",
            "| --- | ---: | ---: | ---: | ---: | ---: | --- |"]
    for record in records:
        docs.append(f'| {record["name"]} | {len(record["permutations"])} | {factorial(len(record["roots"]))} | {len(record["permutations"])} | {record["center"]} | {record["derived"]} | `{record["cycles"]}` |')
    docs += ["", "Regenerate with `python3 tools/generate_splittinggalois_fixtures.py`, or pass `--check` for exact reproduction. The source math and previously validated generated-field oracles support these bounded fixtures; this is finite regression evidence, not an arbitrary-field proof or a scalability result. Root owns JS/wasm-gc, full-suite validation and cleanup.", ""]
    docs += ["Milestone validation: exact regeneration passes, and `tools/measure --cpu 4 tools/moon test src/splittinggalois --target native --release -j 1 --deny-warn` passes all seven independent oracle fixtures. Scoped fmt/check/info and the repository purity gate pass. Native tests and fixture generation use the shared measurement lock.", ""]
    return {ROOT / "src/splittinggalois/oracle_fixtures_wbtest.mbt": formatted,
            ROOT / "docs/research/splittinggalois-oracle-20261117.md": "\n".join(docs)}, stats


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
