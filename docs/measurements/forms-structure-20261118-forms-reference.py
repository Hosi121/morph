#!/usr/bin/env python3
"""Independent Fraction/dictionary/permutation oracle for polynomial forms."""
from argparse import ArgumentParser
from fractions import Fraction as Q
from itertools import product, combinations, permutations
from pathlib import Path
from random import Random
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "src/forms/fraction_fixtures_wbtest.mbt"


def poly(entries):
    result = {}
    for q,e in entries:
        result[tuple(e)] = result.get(tuple(e),Q())+q
    return {e:q for e,q in result.items() if q}


def add_poly(a,b):
    return poly([(q,e) for p in (a,b) for e,q in p.items()])


def multiply_poly(a,b):
    return poly([(x*y,tuple(i+j for i,j in zip(e,f))) for e,x in a.items() for f,y in b.items()])


def differentiate_poly(a,index):
    result = []
    for e,q in a.items():
        if e[index]:
            f = list(e); f[index] -= 1
            result.append((q*e[index],f))
    return poly(result)


def normalize(raw):
    result = {}
    for coefficient,indices in raw:
        if len(set(indices)) != len(indices):
            continue
        inversions = sum(indices[i]>indices[j] for i in range(len(indices)) for j in range(i+1,len(indices)))
        coefficient = {e:q*(-1 if inversions%2 else 1) for e,q in coefficient.items()}
        key = tuple(sorted(indices))
        result[key] = add_poly(result.get(key,{}),coefficient)
    return {key:p for key,p in result.items() if p}


def exterior(a,n):
    return normalize([(differentiate_poly(p,i),(i,)+key) for key,p in a.items() for i in range(n)])


def wedge(a,b):
    return normalize([(multiply_poly(p,q),i+j) for i,p in a.items() for j,q in b.items()])


def contract(a,vector):
    return normalize([( {e:q*(-1 if position%2 else 1) for e,q in multiply_poly(p,vector[index]).items()},
                        key[:position]+key[position+1:])
                      for key,p in a.items() for position,index in enumerate(key)])


def lie_direct(a,vector,n):
    """Coordinate formula, independent of production Cartan d/i composition."""
    raw = []
    for key,p in a.items():
        directional = {}
        for i in range(n): directional = add_poly(directional,multiply_poly(vector[i],differentiate_poly(p,i)))
        raw.append((directional,key))
        for position,index in enumerate(key):
            for j in range(n):
                raw.append((multiply_poly(p,differentiate_poly(vector[index],j)),key[:position]+(j,)+key[position+1:]))
    return normalize(raw)


def one(n):
    return {(0,)*n:Q(1)}


def substitute(p,coordinates,m):
    result = {}
    for exponents,q in p.items():
        term = {(0,)*m:q}
        for exponent,coordinate in zip(exponents,coordinates):
            for _ in range(exponent): term = multiply_poly(term,coordinate)
        result = add_poly(result,term)
    return result


def determinant(matrix,n):
    """Polynomial Leibniz determinant; no production wedge or chain normalizer."""
    result = {}
    for permutation in permutations(range(len(matrix))):
        inversions = sum(permutation[i]>permutation[j] for i in range(len(matrix)) for j in range(i+1,len(matrix)))
        term = {(0,)*n:Q(-1 if inversions%2 else 1)}
        for i,j in enumerate(permutation): term = multiply_poly(term,matrix[i][j])
        result = add_poly(result,term)
    return result


def pullback(a,coordinates,m):
    jacobian = [[differentiate_poly(p,j) for j in range(m)] for p in coordinates]
    raw = []
    for key,p in a.items():
        coefficient = substitute(p,coordinates,m)
        for source_indices in combinations(range(m),len(key)):
            minor = [[jacobian[i][j] for j in source_indices] for i in key]
            raw.append((multiply_poly(coefficient,determinant(minor,m)),source_indices))
    return normalize(raw)


def homotopy_integral(a,n,k):
    """Pull back along F(t,x)=tx, select dt terms, and integrate t in [0,1].

    This does not use the production (r+k)^-1 Euler-contraction formula.
    """
    coordinates = []
    for i in range(n):
        exponent = [0]*(n+1); exponent[0] = exponent[i+1] = 1
        coordinates.append({tuple(exponent):Q(1)})
    extended = pullback(a,coordinates,n+1)
    raw = []
    for indices,p in extended.items():
        if not indices or indices[0] != 0: continue
        integrated = poly([(q/Q(exponent[0]+1),exponent[1:]) for exponent,q in p.items()])
        raw.append((integrated,tuple(i-1 for i in indices[1:])))
    return normalize(raw)


def render_poly(p):
    return "["+", ".join(f"({q.numerator}, {q.denominator}, {list(e)})" for e,q in sorted(p.items(),reverse=True))+"]"


def raw_text(raw):
    return "["+", ".join("("+render_poly(p)+", "+str(list(i))+")" for p,i in raw)+"]"


def form_text(a):
    return raw_text([(p,i) for i,p in sorted(a.items())])


def random_raw(rng,n,k,count=3):
    if k and not n:
        return []
    return [(poly([(Q(rng.randrange(-3,4),rng.choice([1,2,3,5])),[rng.randrange(3) for _ in range(n)])
                   for _ in range(rng.randrange(1,4))]),tuple(rng.randrange(n) for _ in range(k))) for _ in range(count)]


def render():
    rng = Random(20261118)
    lines = ["// Generated by tools/generate_forms_fixtures.py; independent Fraction sparse dictionaries and inversion signs.",""]
    cases = []
    for n in range(4):
        for k in range(n+2):
            for indices in product(range(n),repeat=k):
                cases.append((n,k,[(poly([(Q(2,3),[1]*n)]),indices)]))
    for n in range(5):
        for k in range(n+2):
            for _ in range(3): cases.append((n,k,random_raw(rng,n,k)))
    for index,(n,k,raw) in enumerate(cases):
        a = normalize(raw)
        lines += ["///|",f'test "Fraction form normalization and exterior derivative {index}" {{',
                  f"  fraction_form_fixture({n}, {k}, {raw_text(raw)}, {form_text(a)}, {form_text(exterior(a,n))})","}",""]
    wedge_count = 0
    for n in range(5):
        for p in range(min(n+1,3)):
            for q in range(min(n+1,3)):
                for _ in range(2):
                    a,b = random_raw(rng,n,p),random_raw(rng,n,q)
                    expected = wedge(normalize(a),normalize(b))
                    lines += ["///|",f'test "Fraction wedge and graded identities {wedge_count}" {{',
                              f"  fraction_wedge_fixture({n}, {p}, {q}, {raw_text(a)}, {raw_text(b)}, {form_text(expected)})","}",""]
                    wedge_count += 1
    cartan_count = 0
    for n in range(5):
        for k in range(n+2):
            for _ in range(3):
                raw = random_raw(rng,n,k)
                vector = [poly([(Q(rng.randrange(-3,4),rng.choice([1,2,3])),[rng.randrange(3) for _ in range(n)])
                                for _ in range(2)]) for _ in range(n)]
                a = normalize(raw)
                interior = "None" if not k else "Some("+form_text(contract(a,vector))+")"
                vector_source = "["+", ".join(render_poly(p) for p in vector)+"]"
                lines += ["///|",f'test "Fraction contraction and direct coordinate Lie {cartan_count}" {{',
                          f"  fraction_cartan_fixture({n}, {k}, {raw_text(raw)}, {vector_source}, {interior}, {form_text(lie_direct(a,vector,n))})","}",""]
                cartan_count += 1
    pullback_count = 0
    for m in range(4):
        for n in range(4):
            for k in range(n+2):
                for _ in range(2):
                    raw = random_raw(rng,n,k)
                    coordinates = [poly([(Q(rng.randrange(-2,3),rng.choice([1,2,3])),[rng.randrange(3) for _ in range(m)])
                                         for _ in range(2)]) for _ in range(n)]
                    expected = pullback(normalize(raw),coordinates,m)
                    coordinate_text = "["+", ".join(render_poly(p) for p in coordinates)+"]"
                    lines += ["///|",f'test "Fraction determinant pullback and d commute {pullback_count}" {{',
                              f"  fraction_pullback_fixture({m}, {n}, {k}, {coordinate_text}, {raw_text(raw)}, {form_text(expected)})","}",""]
                    pullback_count += 1
    homotopy_cases = [(n,k,random_raw(rng,n,k)) for n in range(5) for k in range(n+2) for _ in range(3)]
    for n in range(1,5):
        for k in range(1,n+1):
            for _ in range(3):
                closed_form = exterior(normalize(random_raw(rng,n,k-1)),n)
                homotopy_cases.append((n,k,[(p,i) for i,p in closed_form.items()]))
    for index,(n,k,raw) in enumerate(homotopy_cases):
        a = normalize(raw)
        expected = "None" if not k else "Some("+form_text(homotopy_integral(a,n,k))+")"
        remainder = {key:dict(p) for key,p in a.items()}
        if not k and () in remainder:
            remainder[()].pop((0,)*n,None)
            if not remainder[()]: remainder.pop(())
        closed = "true" if not exterior(a,n) else "false"
        lines += ["///|",f'test "Fraction integrated radial homotopy and primitive {index}" {{',
                  f"  fraction_homotopy_fixture({n}, {k}, {raw_text(raw)}, {expected}, {form_text(remainder)}, {closed})","}",""]
    return "\n".join(lines),len(cases),wedge_count,cartan_count,pullback_count,len(homotopy_cases)


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("--check",action="store_true")
    args = parser.parse_args()
    source,normalizations,wedges,cartan,pullbacks,homotopies = render()
    formatter = ROOT / ".tools/moon/bin/moonfmt"
    executable = str(formatter) if formatter.exists() else shutil.which("moonfmt")
    if executable is None: raise SystemExit("moonfmt required for reproducible fixtures")
    source = subprocess.run([executable,"-"],input=source,text=True,capture_output=True,check=True).stdout
    if args.check:
        if not OUTPUT.is_file() or OUTPUT.read_text()!=source: raise SystemExit("Forms Fraction fixture drift: "+str(OUTPUT))
    else:
        OUTPUT.parent.mkdir(parents=True,exist_ok=True); OUTPUT.write_text(source)
    print(f"{normalizations} normalizations/derivatives, {wedges} wedges, {cartan} contractions/Lie, {pullbacks} determinant pullbacks, {homotopies} integrated homotopies.")


if __name__ == "__main__": main()
