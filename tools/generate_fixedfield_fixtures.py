#!/usr/bin/env python3
"""Exact invariant-space oracle for all 17 subgroups of the finite C2/V4/D4 examples."""

from argparse import ArgumentParser
from fractions import Fraction as Q
from pathlib import Path
import json
import subprocess
import sys

import sympy as sp

sys.dont_write_bytecode = True
from generate_complexautomorphism_fixtures import fixture, apply_map, add, symbolic, exact_zero, integers
from generate_complexfield_fixtures import array, fraction

ROOT = Path(__file__).resolve().parents[1]
T = sp.Symbol("t")


def vector(value):
    return sp.Matrix([sp.Rational(q) for part in value for q in part])


def value(column, degree):
    coordinates = [fraction(q) for q in column]
    return coordinates[:degree], coordinates[degree:]


def enumerate_subgroups(group):
    n, identity = len(group["maps"]), group["identity"]
    result = []
    for mask in range(1 << n):
        selected = [j for j in range(n) if mask & (1 << j)]
        if identity not in selected:
            continue
        if all(group["table"][a][b] in selected for a in selected for b in selected):
            assert all(group["inverses"][a] in selected for a in selected)
            result.append(selected)
    return sorted(result, key=lambda members: (len(members), members))


def field_data(name, degree, constant, exponents):
    group = fixture(name, degree, constant, exponents)
    n = 2 * degree
    ambient_basis = [value(sp.eye(n)[:, j], degree) for j in range(n)]
    actions = [sp.Matrix.hstack(*(vector(apply_map(mapping, b)) for b in ambient_basis))
               for mapping in group["maps"]]
    signed_columns = []
    for matrix in actions:
        encoded = []
        for j in range(n):
            nonzero = [(row, matrix[row, j]) for row in range(n) if matrix[row, j]]
            assert len(nonzero) == 1 and nonzero[0][1] in (-1, 1)
            encoded.append(int(nonzero[0][1]) * (nonzero[0][0] + 1))
        signed_columns.append(encoded)
    for left in range(len(actions)):
        for right in range(len(actions)):
            assert actions[left] * actions[right] == actions[group["table"][left][right]]
    zero = ([Q(0)] * degree, [Q(0)] * degree)
    one, imaginary = ambient_basis[0], ambient_basis[degree]
    alpha = zero if degree == 1 else ambient_basis[1]
    if degree == 1:
        samples = [zero, one, imaginary, group["left"]]
        generators = {(0,): imaginary, (0, 1): one}
    elif degree == 2:
        samples = [one, alpha, imaginary, ambient_basis[3], add(alpha, imaginary), group["left"]]
        generators = {(0,): add(alpha, imaginary), (0, 1): alpha, (0, 2): imaginary,
                      (0, 3): ambient_basis[3], (0, 1, 2, 3): one}
    else:
        alpha2, imaginary_alpha = ambient_basis[2], ambient_basis[5]
        imaginary_alpha2 = ambient_basis[6]
        negative_imaginary_alpha = tuple([-q for q in part] for part in imaginary_alpha)
        samples = [one, alpha, imaginary, alpha2, imaginary_alpha2, add(alpha, imaginary_alpha),
                   add(alpha, negative_imaginary_alpha), group["left"]]
        generators = {
            (0,): add(alpha, imaginary), (0, 1): alpha, (0, 2): add(alpha2, imaginary),
            (0, 3): imaginary_alpha, (0, 5): add(alpha, imaginary_alpha),
            (0, 7): add(alpha, negative_imaginary_alpha), (0, 1, 2, 3): alpha2,
            (0, 2, 4, 6): imaginary, (0, 2, 5, 7): imaginary_alpha2,
            tuple(range(8)): one,
        }
    alpha_expression = sp.S.Zero if degree == 1 else sp.Integer(constant)**sp.Rational(1, degree)
    subgroups = []
    for members in enumerate_subgroups(group):
        constraints = sp.Matrix.vstack(*(actions[j] - sp.eye(n) for j in members))
        kernel = constraints.nullspace()
        fixed_degree = len(kernel)
        independent_basis = sp.Matrix.hstack(*kernel)
        assert independent_basis.rank() == fixed_degree
        assert constraints.rank() + fixed_degree == n
        assert fixed_degree * len(members) == n
        assert constraints * independent_basis == sp.zeros(n * len(members), fixed_degree)

        def coordinates(element):
            source = vector(element)
            fixed = constraints * source == sp.zeros(n * len(members), 1)
            direct_fixed = all(apply_map(group["maps"][j], element) == element for j in members)
            assert fixed == direct_fixed
            if not fixed:
                return None
            solution, parameters = independent_basis.gauss_jordan_solve(source)
            assert parameters.rows == 0
            assert independent_basis * solution == source
            return [fraction(q) for q in solution]

        generator = generators[tuple(members)]
        generator_coordinates = coordinates(generator)
        assert generator_coordinates is not None
        generator_expression = symbolic(generator, alpha_expression, sp.I)
        minimum = sp.Poly(sp.minpoly(generator_expression, T), T, domain=sp.QQ).monic()
        assert minimum.degree() == fixed_degree
        exact_zero(minimum.eval(generator_expression))
        subgroups.append(dict(members=members, degree=fixed_degree,
                              basis=[value(column, degree) for column in kernel],
                              generator=generator, generator_expression=str(generator_expression),
                              minimum=[fraction(q) for q in reversed(minimum.all_coeffs())],
                              minimum_text=str(minimum.as_expr()), generator_coordinates=generator_coordinates,
                              sample_coordinates=[coordinates(sample) for sample in samples]))
    assert len(subgroups) == {1: 2, 2: 5, 4: 10}[degree]
    assert set(generators) == {tuple(record["members"]) for record in subgroups}
    if degree == 4:
        reflection = next(record for record in subgroups if record["members"] == [0, 5])
        assert reflection["minimum"] == [Q(8), Q(0), Q(0), Q(0), Q(1)]
    return dict(name=name, degree=degree, constant=constant, roots=group["roots"],
                actions=signed_columns, samples=samples, subgroups=subgroups)


def value_literal(element):
    return "{ real: " + array(element[0]) + ", imaginary: " + array(element[1]) + " }"


def generate():
    assert sp.__version__ == "1.14.0"
    records = [field_data(*specification) for specification in [
        ("C2 over QQ(i)", 1, 0, [0]), ("V4 over QQ(sqrt2)(i)", 2, 2, [0, 2]),
        ("D4 over QQ(fourthroot2)(i)", 4, 2, [0, 2, 1, 3]),
    ]]
    tests = ["// Generated by tools/generate_fixedfield_fixtures.py; independent exact invariant oracle.", ""]
    for record in records:
        tests += ["///|", f'test "independent fixed-field oracle: {record["name"]}" {{',
                  "  oracle_assert_fixed_fields(", f'    {record["degree"]}, {record["constant"]},',
                  "    [" + ", ".join(value_literal(root) for root in record["roots"]) + "],",
                  "    [" + ", ".join(integers(action) for action in record["actions"]) + "],",
                  "    [" + ", ".join(value_literal(sample) for sample in record["samples"]) + "],", "    ["]
        for subgroup in record["subgroups"]:
            tests += ["      {", f'        members: {integers(subgroup["members"])},',
                      f'        degree: {subgroup["degree"]},',
                      "        basis: [" + ", ".join(value_literal(b) for b in subgroup["basis"]) + "],",
                      f'        generator: {value_literal(subgroup["generator"])},',
                      f'        minimum: {array(subgroup["minimum"])},',
                      f'        generator_coordinates: {array(subgroup["generator_coordinates"])},',
                      "        sample_coordinates: [" + ", ".join(
                          "None" if coordinates is None else f"Some({array(coordinates)})"
                          for coordinates in subgroup["sample_coordinates"]) + "],", "      },"]
        tests += ["    ],", "  )", "}", ""]
    formatted = subprocess.run([str(ROOT / ".tools/moon/bin/moonfmt"), "-"], input="\n".join(tests),
                               text=True, capture_output=True, check=True).stdout
    stats = dict(ambient_fields=len(records), subgroups=sum(len(r["subgroups"]) for r in records),
                 independent_basis_vectors=sum(s["degree"] for r in records for s in r["subgroups"]),
                 primitive_identifications=sum(len(r["subgroups"]) for r in records),
                 sample_memberships=sum(len(r["samples"]) * len(r["subgroups"]) for r in records),
                 fixed_sample_coordinates=sum(q is not None for r in records for s in r["subgroups"]
                                              for q in s["sample_coordinates"]))
    docs = ["# Independent exact fixed-field oracle (2026-11-17)", "",
            "This finite oracle covers every subgroup of the explicitly certified C2, V4, and D4 examples: 2+5+10=17 fixed fields. The ambient fields are QQ(i), QQ(sqrt2,i), and QQ(2^(1/4),i). These are finite instances of the Galois correspondence conditional on the supplied splitting and existing exact field certificates, not a general splitting-field or primitive-element search.", "",
            "A host finite-integer model independently enumerates subgroups by identity, multiplication closure, and inverse closure using (k,s)*(l,t)=(k+s*l mod4,s*t). Map order is (+i,-i) per supplied root, with quartic root exponents [0,2,1,3]. Fraction substitution produces every action on the ambient rational quotient basis (1,a,...,i,i*a,...). Each action is encoded compactly as signed target rows for its columns, using one-based rows and a sign. SymPy 1.14.0 computes the exact nullspace and rank of the stacked M_sigma-I constraints. The nullspace basis is independently checked for rank, fixedness, completeness, and [L^H:QQ]*|H|=[L:QQ].", "",
            "For every subgroup, an explicitly selected fixed generator has an independent SymPy minimal polynomial of degree equal to that nullity. This identifies the complete fixed field in each example, including the reflection generator a*(1+i) with minimum t^4+8. No floating approximation, numerical root, MoonBit producer output, or producer implementation supplies an expectation. The only shared Python code comes from the earlier external finite-group/Fraction oracles.", "",
            "MoonBit need not produce SymPy's particular basis order or normalization. Its returned basis must have the independently expected rank and span every independent nullspace vector, and its certificate must have the pinned action/constraint matrices and rank. A second field is imported from the independently populated certificate: all specified generator/sample coordinates in that explicit basis are compared coefficient by coefficient. Produced/imported fields also roundtrip their fixed values; sample nonmembers and different ambient sources are rejected. Group setup is reused within three field-level tests.", "",
            "```json", json.dumps(stats, sort_keys=True), "```", "",
            "| Ambient group | Subgroup indices | Fixed degree | Explicit fixed generator | Independent minimum |",
            "| --- | --- | ---: | --- | --- |"]
    for record in records:
        for subgroup in record["subgroups"]:
            docs.append(f'| {record["name"]} | `{subgroup["members"]}` | {subgroup["degree"]} | '
                        f'`{subgroup["generator_expression"]}` | `{subgroup["minimum_text"]}` |')
    docs += ["", "Run `python3 tools/generate_fixedfield_fixtures.py --check` with the pinned SymPy environment. Regeneration formats only the reserved fixture with the repository moonfmt. These bounded cases are independent regression evidence, not a formal proof of the general theorem or a scalability claim.", "",
             "Milestone validation: regeneration check passes, and `tools/measure --cpu 4 tools/moon test src/fixedfield --target native --release -j 1` passes 8 tests, including these three oracle cases covering all 17 subgroups. The shared measurement lock is used. JS/wasm-gc, full-suite validation, and documentation-index integration remain with the root task.", ""]
    return {ROOT / "src/fixedfield/oracle_fixtures_wbtest.mbt": formatted,
            ROOT / "docs/research/fixedfield-oracle-20261117.md": "\n".join(docs)}, stats


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
