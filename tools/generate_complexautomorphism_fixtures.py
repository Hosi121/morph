#!/usr/bin/env python3
"""Finite exact C2/V4/D4 oracle for explicitly split K(i), not a Galois search."""

from argparse import ArgumentParser
from fractions import Fraction as Q
from pathlib import Path
import json
import subprocess
import sys

import sympy as sp

sys.dont_write_bytecode = True
from generate_complexfield_fixtures import array, coefficients, mul_base

ROOT = Path(__file__).resolve().parents[1]
A, J, Z = sp.symbols("a j z")


def integers(values):
    return "[" + ", ".join(map(str, values)) + "]"


def phase(value, exponent):
    real, imaginary = value
    exponent %= 4
    if exponent == 0:
        return list(real), list(imaginary)
    if exponent == 1:
        return [-q for q in imaginary], list(real)
    if exponent == 2:
        return [-q for q in real], [-q for q in imaginary]
    return list(imaginary), [-q for q in real]


def add(left, right):
    return tuple([a+b for a, b in zip(x, y)] for x, y in zip(left, right))


def multiply(left, right, degree, constant):
    a, b = left
    c, d = right
    ac, bd = mul_base(a, c, degree, constant), mul_base(b, d, degree, constant)
    ad, bc = mul_base(a, d, degree, constant), mul_base(b, c, degree, constant)
    return [x-y for x, y in zip(ac, bd)], [x+y for x, y in zip(ad, bc)]


def apply_map(mapping, value):
    """Substitute a->i^k*a, i->s*i using only rational coefficients and phases."""
    k, sign = mapping
    real, imaginary = value
    degree = len(real)
    out = ([Q(0)] * degree, [Q(0)] * degree)
    for exponent, (a, b) in enumerate(zip(real, imaginary)):
        monomial = [Q(0)] * degree
        monomial[exponent] = a
        out = add(out, phase((monomial, [Q(0)] * degree), k * exponent))
        monomial = [Q(0)] * degree
        monomial[exponent] = sign * b
        out = add(out, phase(([Q(0)] * degree, monomial), k * exponent))
    return out


def symbolic(value, alpha=A, imaginary=J):
    real, imag = value
    return sp.expand(sum(sp.Rational(q) * alpha**j for j, q in enumerate(real))
                     + imaginary * sum(sp.Rational(q) * alpha**j for j, q in enumerate(imag)))


def exact_zero(expression):
    assert not expression.atoms(sp.Float)
    assert sp.simplify(sp.expand_complex(expression)) == 0, expression


def fixture(name, degree, constant, exponents):
    alpha = sp.S.Zero if degree == 1 else sp.Integer(constant)**sp.Rational(1, degree)
    alpha_value = ([Q(0)] * degree, [Q(0)] * degree)
    alpha_value[0][0 if degree == 1 else 1] = Q(constant if degree == 1 else 1)
    root_values = [phase(alpha_value, k) for k in exponents]
    maps = [(k, sign) for k in exponents for sign in (1, -1)]
    assert len(set(maps)) == 2 * degree
    index = {mapping: j for j, mapping in enumerate(maps)}
    compose = lambda left, right: ((left[0] + left[1] * right[0]) % 4, left[1] * right[1])
    table = [[index[compose(left, right)] for right in maps] for left in maps]
    inverses = [index[((-sign*k) % 4, sign)] for k, sign in maps]
    identity, conjugation = index[(0, 1)], index[(0, -1)]
    root_index = {k: j for j, k in enumerate(exponents)}
    actions = [[root_index[(k + sign*root) % 4] for root in exponents] for k, sign in maps]
    n = len(maps)
    for left in range(n):
        assert sorted(table[left]) == list(range(n))
        assert table[left][identity] == table[identity][left] == left
        assert table[left][inverses[left]] == table[inverses[left]][left] == identity
        assert sorted(actions[left]) == list(range(degree))
        for right in range(n):
            product = table[left][right]
            assert actions[product] == [actions[left][j] for j in actions[right]]
            assert all(table[product][last] == table[left][table[right][last]] for last in range(n))
        assert [actions[inverses[left]][j] for j in actions[left]] == list(range(degree))
    # The root action alone has a kernel in C2/V4. Include the image of i to
    # distinguish every map, and require the quartic root action to be faithful.
    assert len({(tuple(row), mapping[1]) for row, mapping in zip(actions, maps)}) == n
    if degree == 4:
        assert len({tuple(row) for row in actions}) == n
        rotation = index[(1, 1)]
        r2 = table[rotation][rotation]
        assert table[r2][r2] == table[conjugation][conjugation] == identity
        assert table[table[conjugation][rotation]][conjugation] == inverses[rotation]
        assert any(table[a][b] != table[b][a] for a in range(n) for b in range(n))
    else:
        assert all(table[a][b] == table[b][a] for a in range(n) for b in range(n))
    roots = [symbolic(value, alpha, sp.I) for value in root_values]
    assert len(set(roots)) == degree
    exact_zero(sp.prod(Z-root for root in roots) - (Z**degree - constant))
    left = ([Q(2, 3), Q(-1, 2), Q(1, 5), Q(-2, 7)][:degree],
            [Q(-3, 5), Q(2, 3), Q(-1, 7), Q(1, 2)][:degree])
    right = ([Q(1, 2), Q(1, 3), Q(-2, 5), Q(1, 7)][:degree],
             [Q(-2, 3), Q(-1, 5), Q(3, 7), Q(-1, 2)][:degree])
    total = add(left, right)
    product = multiply(left, right, degree, constant)
    images = []
    for mapping in maps:
        expected = [apply_map(mapping, value) for value in [left, right, total, product]]
        assert expected[2] == add(expected[0], expected[1])
        assert expected[3] == multiply(expected[0], expected[1], degree, constant)
        k, sign = mapping
        for value, image in zip([left, right, total, product], expected):
            # A fresh symbolic generator pair keeps substitution simultaneous;
            # no field-kernel output or floating value enters this crosscheck.
            substituted = symbolic(value).subs({A: sp.I**k * alpha, J: sign * sp.I}, simultaneous=True)
            actual_real, actual_imaginary = sp.expand_complex(substituted).as_real_imag()
            assert (coefficients(actual_real, alpha, degree), coefficients(actual_imaginary, alpha, degree)) == image
            exact_zero(substituted - symbolic(image, alpha, sp.I))
        for j, root in enumerate(root_values):
            assert apply_map(mapping, root) == root_values[actions[len(images)][j]]
        images.append(expected)
    return dict(name=name, degree=degree, constant=constant, exponents=exponents,
                roots=root_values, maps=maps, table=table, inverses=inverses,
                identity=identity, conjugation=conjugation, actions=actions,
                left=left, right=right, images=images)


def value_literal(value):
    return "{ real: " + array(value[0]) + ", imaginary: " + array(value[1]) + " }"


def generate():
    assert sp.__version__ == "1.14.0"
    records = [fixture(*specification) for specification in [
        ("C2 over QQ(i)", 1, 0, [0]),
        ("V4 over QQ(sqrt2)(i)", 2, 2, [0, 2]),
        ("D4 over QQ(fourthroot2)(i)", 4, 2, [0, 2, 1, 3]),
        ("D4 with permuted root order", 4, 2, [1, 2, 3, 0]),
    ]]
    assert records[-1]["identity"] == 6 and records[-1]["conjugation"] == 7
    tests = ["// Generated by tools/generate_complexautomorphism_fixtures.py; independent finite oracle.", ""]
    for record in records:
        tests += ["///|", f'test "independent split automorphism oracle: {record["name"]}" {{',
                  "  oracle_assert_group_fixture(", f'    {record["degree"]}, {record["constant"]},',
                  "    [" + ", ".join(value_literal(value) for value in record["roots"]) + "],",
                  "    [" + ", ".join(integers(row) for row in record["table"]) + "],",
                  f'    {record["identity"]}, {record["conjugation"]},',
                  f'    {integers(record["inverses"])},',
                  "    [" + ", ".join(integers(row) for row in record["actions"]) + "],",
                  f'    {value_literal(record["left"])},', f'    {value_literal(record["right"])},', "    ["]
        for mapping, images in zip(record["maps"], record["images"]):
            tests += [f'      // alpha -> i^{mapping[0]} alpha; i -> {mapping[1]} i', "      {",
                      *[f"        {label}: {value_literal(value)}," for label, value in zip(["left", "right", "sum", "product"], images)],
                      "      },"]
        tests += ["    ],", "  )", "}", ""]
    formatted = subprocess.run([str(ROOT / ".tools/moon/bin/moonfmt"), "-"], input="\n".join(tests),
                               text=True, capture_output=True, check=True).stdout
    stats = dict(fixtures=len(records), group_orders=sorted({len(r["maps"]) for r in records}),
                 compositions=sum(len(r["maps"])**2 for r in records),
                 inverses=sum(len(r["maps"]) for r in records),
                 root_actions=sum(len(r["maps"]) * r["degree"] for r in records),
                 sample_images=4 * sum(len(r["maps"]) for r in records))
    docs = ["# Independent finite split-field automorphism oracle (2026-11-17)", "",
            "The oracle fixes C2 for QQ(i), V4 for QQ(sqrt2,i), and D4 for QQ(2^(1/4),i), plus one D4 root-order permutation. These are conditional full automorphism groups of explicitly split K(i); this is not a generic QQ Galois-group or splitting-field search. For each degree-d real base, all d distinct roots of the real minimum are supplied inside K(i), and the two choices for the image of i produce the 2d maps.", "",
            "Write a map as (k,s), with alpha -> i^k*alpha and i -> s*i. Map order is interleaved (+i,-i) for each supplied root. Left-after-right composition is (k,s)*(l,t)=(k+s*l mod 4,s*t), inverse=(-s*k mod 4,s), and a root with exponent q maps to exponent k+s*q mod 4. The standard quartic root order [a,-a,i*a,-i*a] has exponents [0,2,1,3]. The shuffled order [i*a,-a,-i*a,a] has exponents [1,2,3,0], so identity and conjugation occur at indices 6 and 7.", "",
            "Python derives every table entry, inverse, and root-action index using finite integer arithmetic. It checks Latin rows, associativity, both inverse laws, permutation composition/inverses, and D4's rotation/conjugation relations. The root action is faithful for D4; for C2/V4 the image of i distinguishes maps in the root-action kernel. Rational sample images are independently computed by Fraction arithmetic in the quotient basis (1,a,...,i,i*a,...), with multiplication reduced modulo a^d-c and i^2+1. SymPy 1.14.0 exact simultaneous substitution crosschecks all sample images and the supplied splitting. No floats, numerical roots, MoonBit output, or producer implementation determine expected values. Shared external-oracle helpers provide only coordinate extraction, literal formatting, and Fraction base multiplication.", "",
            "MoonBit compares all composition-table entries, compose results, inverses, generator images, root actions, and pinned sample sums/products. An independently populated certificate is checked and imported; source/result binding is checked against a different exact real field. The suite uses only the frozen public API despite residing in white-box test files.", "",
            "```json", json.dumps(stats, sort_keys=True), "```", "",
            "| Fixture | Root exponents | Order | Identity | Conjugation | Inverse indices |",
            "| --- | --- | ---: | ---: | ---: | --- |"]
    for record in records:
        docs.append(f'| {record["name"]} | `{record["exponents"]}` | {len(record["maps"])} | '
                    f'{record["identity"]} | {record["conjugation"]} | `{record["inverses"]}` |')
    for record in records[2:]:
        docs += ["", f'The full table for {record["name"]} (row after column):', "",
                 "| left/right | " + " | ".join(str(j) for j in range(8)) + " |",
                 "| --- | " + " | ".join(["---:"] * 8) + " |"]
        docs += ["| " + str(j) + " | " + " | ".join(map(str, row)) + " |" for j, row in enumerate(record["table"])]
    docs += ["", "Run `python3 tools/generate_complexautomorphism_fixtures.py --check` with the pinned SymPy environment. Regeneration formats only the reserved generated fixture through the repository moonfmt. The small deterministic fields and samples are independent regression evidence, not a general field-theoretic proof or scalability claim.", "",
             "Milestone validation: regeneration check passes, and `tools/measure --cpu 4 tools/moon test src/complexautomorphism --target native --release -j 1` passes 10 tests, including these four oracle cases. The shared measurement lock is used. JS and wasm-gc validation remains with the integrating root task.", ""]
    return {ROOT / "src/complexautomorphism/oracle_fixtures_wbtest.mbt": formatted,
            ROOT / "docs/research/complexautomorphism-oracle-20261117.md": "\n".join(docs)}, stats


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
