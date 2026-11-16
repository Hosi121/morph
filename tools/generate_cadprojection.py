#!/usr/bin/env python3
"""Independent SymPy-matrix Collins/derivative hierarchy fixtures (QQ, arity 0..4)."""
from pathlib import Path
import argparse
import json
import re
import sympy as sp
from generate_elimination import mbpoly
from generate_elimination_principal import psc as permutation_psc

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'src/cadprojection/oracle_wbtest.mbt'
ART = ROOT / '.tools/cadprojection-20261116/oracle.json'


def coefficients(p, x):
    p = sp.expand(p)
    d = 0 if p == 0 else sp.Poly(p, x).degree()
    return [p.coeff(x, k) for k in range(d, -1, -1)]


def reducta(p, x):
    cs = coefficients(p, x)
    return [sp.expand(sum(c*x**(len(cs)-i-1) for i, c in enumerate(cs[j:], j)))
            for j, c in enumerate(cs) if c != 0]


def principals(f, g, x):
    a, b = coefficients(f, x), coefficients(g, x)
    n, m = len(a)-1, len(b)-1
    values = []
    for k in range(min(n, m)):
        size = n+m-2*k
        width = size+k
        rows = [[sp.Integer(0)]*j+a+[sp.Integer(0)]*(width-j-len(a)) for j in range(m-k)]
        rows += [[sp.Integer(0)]*j+b+[sp.Integer(0)]*(width-j-len(b)) for j in range(n-k)]
        value = sp.expand(sp.Matrix([row[:size] for row in rows]).det(method='domain-ge'))
        assert sp.expand(value-permutation_psc(a, b, k)) == 0
        values.append(value)
    return values+[sp.Integer(1)]


def projection(atoms, gens):
    x = gens[-1]
    blocks = [reducta(p, x) for p in atoms]
    rows = []
    for i, block in enumerate(blocks):
        for p in block:
            rows.append((p, sp.diff(p, x), principals(p, sp.diff(p, x), x)))
        for other in blocks[i+1:]:
            for p in block:
                for q in other:
                    rows.append((p, q, principals(p, q, x)))
    return dict(arity=len(gens), atoms=atoms,
                coefficients=[c for p in atoms for c in coefficients(p, x)],
                reducta=blocks, principal=rows)


def prune(ps):
    out = []
    for p in map(sp.expand, ps):
        if p.free_symbols and p not in out:
            out.append(p)
    return out


def binding(p, family):
    p = sp.expand(p)
    return ('Member', family.index(p)) if p.free_symbols else ('Constant', sp.sign(p))


def hierarchy(atoms, gens):
    if not gens:
        return [dict(arity=0, source=atoms, family=[], bindings=[binding(p, []) for p in atoms],
                     derivatives=[], projection=None)]
    x = gens[-1]
    originals = prune(atoms)
    ds = []
    for p in originals:
        while True:
            p = sp.diff(p, x)
            if not p.free_symbols:
                break
            ds.append(p)
    family = prune(originals+ds)
    proof = projection(family, gens)
    lower = prune(proof['coefficients']+[v for _, _, vs in proof['principal'] for v in vs])
    return hierarchy(lower, gens[:-1])+[dict(arity=len(gens), source=atoms, family=family,
                bindings=[binding(p, family) for p in atoms],
                derivatives=[binding(sp.diff(p, x), family) for p in family], projection=proof)]


def cchain(items):
    return '@oracle.chain(['+', '.join(items)+'])'


def polys(ps, gens):
    return cchain([mbpoly(p, gens) for p in ps])


def mbprojection(data, gens):
    rows = cchain(['PrincipalRow::{ left: '+mbpoly(f, gens)+', right: '+mbpoly(g, gens)+
                   ', values: '+polys(vs, gens[:-1])+' }' for f, g, vs in data['principal']])
    return 'ProjectionCertificate::{ arity: @oracle.nat('+str(len(gens))+'), atoms: '+polys(data['atoms'], gens)+\
        ', coefficients: '+polys(data['coefficients'], gens[:-1])+', reducta: '+\
        cchain([polys(block, gens) for block in data['reducta']])+', principal: '+rows+' }'


def mbbinding(value):
    kind, index = value
    return 'Member(@oracle.nat('+str(index)+'))' if kind == 'Member' else \
        'Constant(@core.'+{-1: 'Less', 0: 'Equal', 1: 'Greater'}[int(index)]+')'


def mblevel(data, gens):
    proof = 'None' if data['projection'] is None else 'Some('+mbprojection(data['projection'], gens)+')'
    return 'Level::{ arity: @oracle.nat('+str(len(gens))+'), source: '+polys(data['source'], gens)+\
        ', family: '+polys(data['family'], gens)+', bindings: '+cchain(list(map(mbbinding, data['bindings'])))+\
        ', derivatives: '+cchain(list(map(mbbinding, data['derivatives'])))+', projection: '+proof+' }'


def cases():
    x, y, z, w = sp.symbols('x y z w')
    return [([x], []), ([x], [sp.Integer(0), sp.Rational(-2, 3)]),
            ([x, y], [y*y-x, y-1]), ([x, y], [y*(y-x-1), y*(y-2*x-3), y]),
            ([x, y], [(x-1)*(y*y+1), (x+1)*(y-2)]),
            ([x, y], [y**3+x*y, y-x]),
            ([x, y, z], []), ([x, y, z], [sp.Integer(0), x, sp.Rational(2, 3)]),
            ([x, y, z], [z*z+x*z+y, z-x]),
            ([x, y, z], [(x-1)*(z*z+y), (y-2)*(z+1)]),
            ([x, y, z], [z*(z-x-y), z*(z-2*x-y-1)]),
            ([x, y, z, w], []),
            ([x, y, z, w], [w*w+x*w+y+z, w-z]),
            ([x, y, z, w], [(x-y)*w*w+(y-z)*w, w+z]),
            ([x, y, z, w], [sp.Rational(2, 5)*w**3+(x+y)*w+z, w-x])]


def generate():
    lines = ['// Generated independent SymPy Matrix.det and permutation-determinant oracle.']
    records = []
    for i, (gens, atoms) in enumerate(cases()):
        atoms = list(map(sp.expand, atoms))
        data = projection(atoms, gens)
        lines += ['', '///|', f'test "arbitrary arity independent full Collins {i}" {{',
                  '  one_step_fixture(@oracle.nat('+str(len(gens))+'), '+polys(atoms, gens)+', '+mbprojection(data, gens)+')', '}']
        records.append(dict(case=i, arity=len(gens), atoms=list(map(str, atoms)),
                            coefficients=list(map(str, data['coefficients'])),
                            reducta=[[str(p) for p in block] for block in data['reducta']],
                            principal=[dict(left=str(f), right=str(g), values=list(map(str, vs))) for f, g, vs in data['principal']]))
    x, y, z, w = sp.symbols('x y z w')
    hierarchies = [([], [sp.Integer(0), sp.Rational(-2, 3), sp.Integer(7)]),
                   ([x], []), ([x], [x**3-x]), ([x], [(x-1)**2, x-1, sp.Integer(0), (x-1)**2]),
                   ([x, y], [y*y-x]), ([x, y], [y*(y-x-1), y*(y-2*x-3), y]),
                   ([x, y, z], [z*z+x+y]),
                   ([x, y, z], [(x-1)*z+y]),
                   ([x, y, z, w], [w+x+y+z]),
                   ([x, y, z, w], [])]
    hrecords = []
    for i, (gens, atoms) in enumerate(hierarchies):
        atoms = list(map(sp.expand, atoms))
        levels = hierarchy(atoms, gens)
        lines += ['', '///|', f'test "independent derivative hierarchy {i}" {{',
                  '  hierarchy_fixture(@oracle.nat('+str(len(gens))+'), '+polys(atoms, gens)+', '+
                  cchain([mblevel(data, gens[:data['arity']]) for data in levels])+')', '}']
        hrecords.append(dict(case=i, arity=len(gens), atoms=list(map(str, atoms)),
                             levels=[dict(arity=d['arity'], source=list(map(str, d['source'])), family=list(map(str, d['family'])),
                                          bindings=[(k, int(v)) for k, v in d['bindings']], derivatives=[(k, int(v)) for k, v in d['derivatives']]) for d in levels]))
    return '\n'.join(lines)+'\n', dict(sympy=sp.__version__, one_step=records, hierarchies=hrecords)


def tokens(source):
    return re.findall(r'"(?:\\.|[^"\\])*"|\S', re.sub(r',\s*([\]\)}])', r'\1', source))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    source, data = generate()
    if args.check:
        assert tokens(OUT.read_text()) == tokens(source), 'cadprojection fixture drift'
    else:
        OUT.write_text(source)
    ART.parent.mkdir(parents=True, exist_ok=True)
    ART.write_text(json.dumps(data, indent=2)+'\n')
    print(f"{'Checked' if args.check else 'Wrote'} {len(data['one_step'])} full Collins and {len(data['hierarchies'])} derivative-closed hierarchies; SymPy {sp.__version__}.")


if __name__ == '__main__':
    main()
