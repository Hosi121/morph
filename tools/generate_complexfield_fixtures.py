#!/usr/bin/env python3
"""Independent exact K(i) oracle: Fraction coordinates and SymPy algebraic roots."""
from argparse import ArgumentParser
from fractions import Fraction as Q
from pathlib import Path
import json
import subprocess
import sympy as sp

ROOT = Path(__file__).resolve().parents[1]
T = sp.Symbol("t")


def fraction(value):
    value = sp.Rational(value)
    return Q(int(value.p), int(value.q))


def literal(value):
    value = Q(value)
    assert abs(value.numerator) < 2**31 and value.denominator < 2**31
    return f"({value.numerator}, {value.denominator})"


def array(values):
    return "[" + ", ".join(map(literal, values)) + "]"


def mul_base(a, b, degree, constant):
    out = [Q(0)] * degree
    for i, x in enumerate(a):
        for j, y in enumerate(b):
            power = i+j
            out[power % degree] += x*y*(constant if power >= degree else 1)
    return out


def determinant(matrix):
    values = [list(row) for row in matrix]
    result = Q(1)
    for index in range(len(values)):
        selected = next((j for j in range(index, len(values)) if values[j][index]), None)
        if selected is None:
            return Q(0)
        if selected != index:
            values[index], values[selected] = values[selected], values[index]
            result = -result
        pivot = values[index][index]
        result *= pivot
        for row in range(index+1, len(values)):
            factor = values[row][index]/pivot
            for column in range(index+1, len(values)):
                values[row][column] -= factor*values[index][column]
    return result


def coefficients(value, alpha, degree):
    value = sp.expand(sp.radsimp(value))
    if degree == 1:
        return [fraction(value)]
    result = [fraction(value.coeff(alpha, j)) for j in range(1, degree)]
    remainder = sp.simplify(value-sum(sp.Rational(x)*alpha**j for j, x in enumerate(result, 1)))
    return [fraction(remainder), *result]


def data(name, degree, constant, real, imaginary):
    real, imaginary = list(map(Q, real)), list(map(Q, imaginary))
    assert len(real) == len(imaginary) == degree
    alpha = sp.S.Zero if degree == 1 else sp.Integer(constant)**sp.Rational(1, degree)
    a = sum(sp.Rational(q)*alpha**j for j, q in enumerate(real))
    b = sum(sp.Rational(q)*alpha**j for j, q in enumerate(imaginary))
    value = sp.expand(a+sp.I*b)
    basis = [alpha**j for j in range(degree)]
    # Build columns from symbolic algebraic multiplication, not block formulas.
    columns = []
    for source in basis + [sp.I*v for v in basis]:
        x, y = sp.expand_complex(value*source).as_real_imag()
        columns.append(coefficients(x, alpha, degree)+coefficients(y, alpha, degree))
    matrix = [list(row) for row in zip(*columns)]
    symbolic = sp.Matrix([[sp.Rational(q) for q in row] for row in matrix])
    trace = sum(matrix[j][j] for j in range(2*degree))
    norm = determinant(matrix)
    assert fraction(symbolic.trace()) == trace
    assert fraction(symbolic.det()) == norm
    minimum = sp.Poly(sp.minpoly(value, T), T, domain=sp.QQ).monic()
    assert sp.simplify(sp.expand_complex(minimum.eval(value))) == 0
    characteristic = sp.Poly(symbolic.charpoly(T).as_expr(), T, domain=sp.QQ)
    assert 2*degree % minimum.degree() == 0
    assert characteristic == minimum**(2*degree//minimum.degree())
    conjugate = sp.conjugate(value)
    relative_trace = coefficients(sp.simplify(value+conjugate), alpha, degree)
    relative_norm = coefficients(sp.simplify(value*conjugate), alpha, degree)
    rr, ii = mul_base(real, real, degree, constant), mul_base(imaginary, imaginary, degree, constant)
    assert relative_trace == [2*q for q in real]
    assert relative_norm == [x+y for x,y in zip(rr,ii)]
    inverse = None
    if value != 0:
        vector = symbolic.inv()*sp.Matrix([1]+[0]*(2*degree-1))
        inverse = ([fraction(q) for q in vector[:degree]],
                   [fraction(q) for q in vector[degree:]])
        c, d = inverse
        selected_inverse = sum(sp.Rational(q)*alpha**j for j,q in enumerate(c)) + sp.I*sum(sp.Rational(q)*alpha**j for j,q in enumerate(d))
        assert sp.simplify(sp.expand_complex(value*selected_inverse-1)) == 0
        ac, bd = mul_base(real,c,degree,constant), mul_base(imaginary,d,degree,constant)
        ad, bc = mul_base(real,d,degree,constant), mul_base(imaginary,c,degree,constant)
        assert [x-y for x,y in zip(ac,bd)] == [Q(1)]+[Q(0)]*(degree-1)
        assert [x+y for x,y in zip(ad,bc)] == [Q(0)]*degree
    return dict(name=name, degree=degree, constant=constant, real=real, imaginary=imaginary,
                expression=str(value), trace=trace, norm=norm,
                minimum=[fraction(q) for q in reversed(minimum.all_coeffs())],
                minimum_text=str(minimum.as_expr()), matrix=matrix,
                relative_trace=relative_trace, relative_norm=relative_norm, inverse=inverse)


def generate():
    assert sp.__version__ == "1.14.0"
    specifications = [
        ("Gaussian unit", 1, 0, [0], [1]),
        ("Gaussian rational", 1, 0, [Q(1,2)], [Q(-2,3)]),
        ("rational subfield", 1, 0, [Q(2,3)], [0]),
        ("Gaussian zero", 1, 0, [0], [0]),
        ("sqrt2 plus i", 2, 2, [0,1], [1,0]),
        ("sqrt2 real subfield", 2, 2, [0,1], [0,0]),
        ("imaginary sqrt2 subfield", 2, 2, [0,0], [0,1]),
        ("sqrt2 fractions", 2, 2, [Q(3,2),Q(-1,3)], [Q(-5,2),Q(2,3)]),
        ("sqrt2 eighth power", 2, 2, [17,0], [0,-56]),
        ("cube root of unity", 2, 3, [Q(-1,2),0], [0,Q(1,2)]),
        ("conjugate cube root of unity", 2, 3, [Q(-1,2),0], [0,Q(-1,2)]),
        ("sqrt3 plus i", 2, 3, [0,1], [1,0]),
        ("sqrt5 mixed", 2, 5, [1,2], [3,-1]),
        ("nontrivial field zero", 2, 5, [0,0], [0,0]),
        ("rational in quartic ambient", 2, 2, [Q(-7,5),0], [0,0]),
        ("cubic real base plus i", 3, 2, [0,1,0], [1,0,0]),
        ("cubic real subfield", 3, 2, [0,1,0], [0,0,0]),
        ("quartic real base plus i unit", 4, 2, [0,1,0,0], [1,0,0,0]),
    ]
    records = [data(*specification) for specification in specifications]
    tests = ["// Generated by tools/generate_complexfield_fixtures.py; independent exact oracle.", ""]
    for record in records:
        inverse = record["inverse"]
        inverse_text = "None" if inverse is None else f"Some(({array(inverse[0])}, {array(inverse[1])}))"
        tests += ["///|", f'test "independent K(i) oracle: {record["name"]}" {{',
                  "  assert_complexfield_fixture(", f'    {record["degree"]}, {record["constant"]},',
                  f'    {array(record["real"])}, {array(record["imaginary"])},',
                  f'    {literal(record["trace"])}, {literal(record["norm"])},',
                  f'    {array(record["minimum"])},',
                  "    ["+", ".join(array(row) for row in record["matrix"])+"],",
                  f'    {array(record["relative_trace"])}, {array(record["relative_norm"])},',
                  f"    {inverse_text},", "  )", "}", ""]
    formatted = subprocess.run([str(ROOT/".tools/moon/bin/moonfmt"), "-"],
                               input="\n".join(tests), text=True,capture_output=True,check=True).stdout
    stats = dict(cases=len(records), ambient_degrees=sorted({2*r["degree"] for r in records}),
                 smaller_minimum_cases=sum(len(r["minimum"])-1 < 2*r["degree"] for r in records))
    docs = ["# Independent exact K(i) oracle (2026-11-17)", "",
            "The oracle uses SymPy 1.14.0 algebraic expressions and independent Fraction arithmetic. No producer code, floating approximation, numerical root, or field-kernel output is an expectation.", "",
            "For K=QQ(a), a^d=c with the selected positive real root (or QQ when d=1,c=0), the QQ basis is 1,a,...,a^(d-1),i,i*a,...,i*a^(d-1). Columns come from symbolic multiplication by each basis element. Fraction Gaussian determinants and SymPy determinants agree; conjugation gives relative trace/norm. SymPy minimal polynomials annihilate the exact value, and the characteristic polynomial is their ambient-degree power. Exact inverse coordinates satisfy the product identity under Fraction reduction modulo a^d-c.", "",
            "Trace and norm below belong to the ambient K(i), not necessarily QQ(element). A primitive cube root of unity has minimum degree2 inside ambient degree4, with ambient trace-2 and norm1. The cubic and quartic real bases also exercise ambient degrees6 and8.", "",
            "```json", json.dumps(stats,sort_keys=True), "```", "",
            "| Case | Ambient QQ degree | Exact value | Trace | Norm | Minimum |",
            "| --- | ---: | --- | --- | --- | --- |"]
    for record in records:
        docs.append(f'| {record["name"]} | {2*record["degree"]} | `{record["expression"]}` | `{record["trace"]}` | `{record["norm"]}` | `{record["minimum_text"]}` |')
    a=sp.Integer(2)**sp.Rational(1,4)
    z=sp.Symbol("z")
    assert sp.simplify(sp.prod(z-r for r in [a,-a,sp.I*a,-sp.I*a])-(z**4-2))==0
    docs += ["", "The explicit quartic example has a=2^(1/4). K(i) contains a,-a,i*a,-i*a, whose monic product is z^4-2. Conversely those roots generate a and i=(i*a)/a, so this chosen ambient degree8 field is the splitting field of that example. This is an explicit construction, not a generic splitting-field algorithm.", "",
             "Run `python3 tools/generate_complexfield_fixtures.py --check` with the pinned SymPy environment. Regeneration formats only the generated fixture using the repository's moonfmt. These finite cases are independent regression evidence, not a proof of the whole MoonBit kernel or a scalability claim.", ""]
    return {ROOT/"src/complexfield/oracle_fixtures_wbtest.mbt":formatted,
            ROOT/"docs/research/complexfield-oracle-20261117.md":"\n".join(docs)}, stats


def main():
    parser=ArgumentParser(description=__doc__)
    parser.add_argument("--check",action="store_true")
    args=parser.parse_args()
    artifacts,stats=generate()
    for path,content in artifacts.items():
        if args.check:
            if not path.exists() or path.read_text()!=content:
                raise SystemExit(f"Stale oracle: {path.relative_to(ROOT)}")
        else:
            path.parent.mkdir(parents=True,exist_ok=True)
            path.write_text(content)
    print(json.dumps(stats,sort_keys=True))


if __name__=="__main__":
    main()
