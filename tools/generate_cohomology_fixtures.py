#!/usr/bin/env python3
"""Independent GF(2) set-span oracle; deliberately no Gaussian elimination.

Kernel membership enumerates bitmasks and evaluates simplex boundary sets.
Images/quotients use finite XOR-set closure. Cup tensors are assembled by
joining pairs of supported faces, rather than walking output simplices.
"""
from itertools import combinations
from pathlib import Path
import argparse
import json
import shutil
import subprocess

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / 'src/cohomology/fixtures_wbtest.mbt'
SUMMARY = ROOT / 'src/cohomology/fixtures.json'


def closure(facets):
    return sorted({face for facet in facets for n in range(1, len(facet) + 1)
                   for face in combinations(facet, n)})


def span(vectors):
    values = {0}
    for vector in vectors:
        values |= {value ^ vector for value in values}
    return values


def image_generators(lower, upper):
    return [sum(1 << j for j, simplex in enumerate(upper)
                if set(face) < set(simplex)) for face in lower]


def group(faces, degree):
    here = [s for s in faces if len(s) == degree + 1]
    lower = [s for s in faces if len(s) == degree] if degree else []
    upper = [s for s in faces if len(s) == degree + 2]
    constraints = [sum(1 << i for i, face in enumerate(here)
                       if set(face) < set(simplex)) for simplex in upper]
    cycles = [value for value in range(1 << len(here))
              if all((value & row).bit_count() % 2 == 0 for row in constraints)]
    boundaries = span(image_generators(lower, here))
    assert boundaries <= set(cycles)
    representatives = []
    classes = {value: 0 for value in boundaries}
    for value in cycles:
        if value not in classes:
            bit = 1 << len(representatives)
            representatives.append(value)
            classes.update({old ^ value: coordinate ^ bit
                            for old, coordinate in list(classes.items())})
    assert set(classes) == set(cycles)
    assert len(cycles) == len(boundaries) * (1 << len(representatives))
    return {'width': len(here), 'boundaries': sorted(boundaries),
            'representatives': representatives,
            'cycles': [[value, classes[value]] for value in cycles]}


def tensor(faces, p, q):
    left = [s for s in faces if len(s) == p + 1]
    right = [s for s in faces if len(s) == q + 1]
    output = [s for s in faces if len(s) == p + q + 1]
    lookup = {simplex: i for i, simplex in enumerate(output)}
    entries = []
    for i, a in enumerate(left):
        for j, b in enumerate(right):
            if a[-1] == b[0] and set(a) & set(b) == {a[-1]}:
                joined = a + b[1:]
                if joined in lookup:
                    entries.append([i, j, lookup[joined]])
    return entries


def cup_mask(entries, a, b):
    value = 0
    for i, j, k in entries:
        if (a >> i) & (b >> j) & 1:
            value ^= 1 << k
    return value


def fixture(name, facets, exhaustive):
    faces = closure(facets)
    top = max((len(s) - 1 for s in faces), default=0)
    groups = [group(faces, d) for d in range(top + 2)]
    tensors = [[tensor(faces, p, q) for q in range(top + 2)] for p in range(top + 2)]
    class_maps = [dict(g['cycles']) for g in groups]
    products = []
    for p in range(top + 1):
        for i, a in enumerate(groups[p]['representatives']):
            for q in range(top + 1):
                for j, b in enumerate(groups[q]['representatives']):
                    raw = cup_mask(tensors[p][q], a, b)
                    value = class_maps[p + q][raw] if p + q < len(groups) else 0
                    products.append([p, i, q, j, value])
    return {'name': name, 'facets': facets, 'groups': groups, 'tensors': tensors,
            'products': products, 'exhaustive': exhaustive}


def small_complexes():
    universe = [s for n in range(1, 5) for s in combinations(range(4), n)]
    result = []
    for mask in range(1 << len(universe)):
        chosen = [s for i, s in enumerate(universe) if mask >> i & 1]
        if set(chosen) != set(closure(chosen)):
            continue
        facets = [list(s) for s in chosen if not any(set(s) < set(t) for t in chosen)]
        result.append(fixture('all_four_vertices_' + str(len(result)), facets, True))
    assert len(result) == 167
    return result


def focused():
    torus = [[0, 1, 2], [1, 2, 4], [1, 3, 4], [1, 3, 6], [0, 1, 5],
             [1, 5, 6], [2, 3, 5], [2, 4, 5], [2, 3, 6], [0, 2, 6],
             [0, 3, 4], [0, 3, 5], [4, 5, 6], [0, 4, 6]]
    plane = [[0, 1, 2], [0, 2, 3], [0, 1, 5], [0, 4, 5], [0, 3, 4],
             [1, 2, 4], [1, 3, 4], [1, 3, 5], [2, 3, 5], [2, 4, 5]]
    wedge = [[0, 1], [1, 2], [0, 2], [0, 3], [3, 4], [0, 4],
             [0, 5, 6], [0, 5, 7], [0, 6, 7], [5, 6, 7]]
    out = [fixture('torus', torus, False), fixture('projective_plane', plane, False),
           fixture('wedge_two_circles_sphere', wedge, False),
           fixture('disjoint_circles', [[0, 1], [0, 2], [1, 2], [3, 4], [3, 5], [4, 5]], True)]
    for f in out[:3]:
        ranks = [len(g['representatives']) for g in f['groups'][:3]]
        assert ranks == ([1, 1, 1] if f['name'] == 'projective_plane' else [1, 2, 1])
        positive = [row for row in f['products'] if row[0] == row[2] == 1]
        if f['name'] == 'torus':
            assert [row[-1] for row in positive] == [0, 1, 1, 0]
        elif f['name'] == 'projective_plane':
            assert [row[-1] for row in positive] == [1]
        else:
            assert not any(row[-1] for row in positive)
    return out


def mb(value):
    if isinstance(value, bool):
        return str(value).lower()
    if isinstance(value, list):
        return '[' + ', '.join(mb(x) for x in value) + ']'
    return str(value)


def generate():
    fixtures = small_complexes() + focused()
    lines = ['// Generated by tools/generate_cohomology_fixtures.py; do not edit.\n']
    for f in fixtures:
        groups = f['groups']
        cycle_groups = []
        for d, g in enumerate(groups):
            if len(g['cycles']) <= 512:
                cycle_groups.append(mb(g['cycles']))
                continue
            calls = []
            for index, start in enumerate(range(0, len(g['cycles']), 512)):
                name = f'fixture_cycles_{f["name"]}_{d}_{index}'
                calls.append('..' + name + '()')
                lines += ['///|', f'fn {name}() -> Array[Array[Int]] {{',
                          '  ' + mb(g['cycles'][start:start + 512]), '}', '']
            cycle_groups.append('[' + ', '.join(calls) + ']')
        lines += ['///|', f'test "independent set-span oracle {f["name"]}" {{',
                  '  verify_oracle_fixture(',
                  '    ' + mb(f['facets']) + ',',
                  '    ' + mb([g['width'] for g in groups]) + ',',
                  '    ' + mb([g['boundaries'] for g in groups]) + ',',
                  '    ' + mb([g['representatives'] for g in groups]) + ',',
                  '    [' + ', '.join(cycle_groups) + '],',
                  '    ' + mb(f['tensors']) + ',',
                  '    ' + mb(f['products']) + ',',
                  '    ' + mb(f['exhaustive']) + ',', '  )', '}', '']
    summary = {'complexes_on_four_vertices': 167, 'focused_examples': 4,
               'cochain_membership_cases': sum(sum(1 << g['width'] for g in f['groups'])
                                               for f in fixtures if f['exhaustive']),
               'kernel_vectors': sum(sum(len(g['cycles']) for g in f['groups']) for f in fixtures),
               'ordered_basis_products': sum(len(f['products']) for f in fixtures),
               'exhaustive_cocycle_pairs': sum(sum(len(a['cycles']) * len(b['cycles'])
                                                  for a in f['groups'] for b in f['groups'])
                                             for f in fixtures if f['exhaustive']),
               'exhaustive_cochain_cup_pairs': sum(sum(1 << g['width'] for g in f['groups']) ** 2
                                                  for f in fixtures if f['exhaustive']),
               'leibniz_basis_pairs': sum(sum(g['width'] for g in f['groups']) ** 2 for f in fixtures)}
    return '\n'.join(lines), json.dumps(summary, indent=2) + '\n'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    code, summary = generate()
    formatter = ROOT / '.tools/moon/bin/moonfmt'
    executable = str(formatter) if formatter.exists() else shutil.which('moonfmt')
    if executable is None:
        raise SystemExit('moonfmt is required to canonicalize generated fixtures')
    code = subprocess.run([executable, '-'], input=code, text=True,
                          check=True, capture_output=True).stdout
    if args.check:
        assert OUTPUT.read_text() == code, 'cohomology fixtures are stale'
        assert SUMMARY.read_text() == summary, 'cohomology summary is stale'
    else:
        OUTPUT.write_text(code)
        SUMMARY.write_text(summary)
    print(summary, end='')


if __name__ == '__main__':
    main()
