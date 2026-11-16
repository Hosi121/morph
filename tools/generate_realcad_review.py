#!/usr/bin/env python3
"""Independent Fraction/Q(sqrt(d)) sign-cell review fixtures, without SymPy/Sturm.

Every real root is supplied by factor construction. Exact signs in one quadratic
field use integer comparisons of squared rational magnitudes. Positive quadratic
and quartic factors are known to have no real roots. No root isolation routine,
Euclidean/Sturm sequence, or production executable is used by this oracle.
"""
from __future__ import annotations
from dataclasses import dataclass
from fractions import Fraction as F
from functools import cmp_to_key
from pathlib import Path
import argparse
import json
import re

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / 'src/realcad/independent_review_fixtures_wbtest.mbt'
ARTIFACT = ROOT / '.tools/realcad-review-20261116/fraction-oracle.json'
RELATIONS = ['LessZero', 'AtMostZero', 'EqualZero', 'NotZero', 'AtLeastZero', 'GreaterZero']


@dataclass(frozen=True)
class Surd:
    a: F
    b: F = F(0)
    d: int = 2

    def __add__(self, other):
        if not isinstance(other, Surd): other = Surd(F(other), F(0), self.d)
        assert self.d == other.d
        return Surd(self.a+other.a, self.b+other.b, self.d)

    def __neg__(self):
        return Surd(-self.a, -self.b, self.d)

    def __sub__(self, other): return self + -other

    def __mul__(self, other):
        if not isinstance(other, Surd): other = Surd(F(other), F(0), self.d)
        assert self.d == other.d
        return Surd(self.a*other.a+self.d*self.b*other.b,
                    self.a*other.b+self.b*other.a, self.d)

    def sign(self):
        sign = lambda q: (q > 0) - (q < 0)
        if not self.a: return sign(self.b)
        if not self.b: return sign(self.a)
        if sign(self.a) == sign(self.b): return sign(self.a)
        comparison = sign(self.a*self.a - self.d*self.b*self.b)
        return comparison*sign(self.a)


def multiply(a, b):
    out = [F(0)]*(len(a)+len(b)-1)
    for i, x in enumerate(a):
        for j, y in enumerate(b): out[i+j] += x*y
    while out and not out[-1]: out.pop()
    return tuple(out)


def polynomial(scale, factors):
    out = (F(scale),)
    for factor, multiplicity in factors:
        for _ in range(multiplicity): out = multiply(out, factor)
    return out


def linear(root): return (-F(root), F(1))

def quadratic(shift, d): return (F(shift)**2-d, -2*F(shift), F(1))


def evaluate(poly, x):
    out = Surd(F(0), F(0), x.d)
    for coefficient in reversed(poly): out = out*x+coefficient
    return out


def collect(formula):
    if formula[0] == 'atom': return [formula[1]]
    if formula[0] == 'truth': return []
    out = []
    for child in formula[1:]:
        for p in collect(child):
            if p not in out: out.append(p)
    return out


def holds(formula, point):
    kind = formula[0]
    if kind == 'truth': return formula[1]
    if kind == 'not': return not holds(formula[1], point)
    if kind == 'and': return holds(formula[1], point) and holds(formula[2], point)
    if kind == 'or': return holds(formula[1], point) or holds(formula[2], point)
    s = evaluate(formula[1], point).sign()
    return {'LessZero':s<0, 'AtMostZero':s<=0, 'EqualZero':s==0,
            'NotZero':s!=0, 'AtLeastZero':s>=0, 'GreaterZero':s>0}[formula[2]]


def rational_literal(q):
    q = F(q)
    return f'review_ratio({str(q<0).lower()}, "{abs(q.numerator):x}", "{q.denominator:x}")'


def poly_literal(p): return 'review_polynomial(['+', '.join(rational_literal(q) for q in p)+'])'


def moon_formula(formula):
    kind = formula[0]
    if kind == 'truth': return f'Truth({str(formula[1]).lower()})'
    if kind == 'atom': return f'Atom({poly_literal(formula[1])}, {formula[2]})'
    if kind == 'not': return f'Negation({moon_formula(formula[1])})'
    return ('Conjunction' if kind == 'and' else 'Disjunction')+'('+moon_formula(formula[1])+', '+moon_formula(formula[2])+')'


def formulas(p, q, r):
    atom = lambda p, relation: ('atom', p, relation)
    conj = lambda a,b: ('and',a,b)
    disj = lambda a,b: ('or',a,b)
    neg = lambda a: ('not',a)
    z, c = (), (F(-2,13),)
    return [
        conj(disj(conj(atom(p,'AtMostZero'),atom(q,'NotZero')),
                  conj(atom(r,'EqualZero'),neg(disj(atom(p,'LessZero'),atom(c,'GreaterZero'))))), atom(z,'EqualZero')),
        conj(neg(conj(atom(p,'GreaterZero'),disj(atom(q,'AtMostZero'),neg(atom(r,'EqualZero'))))),disj(atom(c,'LessZero'),atom(z,'NotZero'))),
        conj(conj(disj(atom(p,'EqualZero'),atom(p,'NotZero')),disj(atom(q,'AtMostZero'),atom(q,'GreaterZero'))),
             conj(disj(atom(r,'AtLeastZero'),atom(r,'LessZero')),disj(atom(z,'EqualZero'),atom(c,'GreaterZero')))),
        disj(disj(conj(atom(p,'EqualZero'),atom(p,'NotZero')),conj(atom(q,'GreaterZero'),atom(q,'AtMostZero'))),
             disj(conj(atom(r,'LessZero'),atom(r,'AtLeastZero')),conj(atom(z,'NotZero'),atom(c,'LessZero')))),
    ]


def families():
    out=[]
    positive=(F(1),F(0),F(1))
    for label, roots in [
        ('rational_denominators',[F(-7,3),F(-1,5),F(0),F(2,7),F(11,4)]),
        ('near_zero_31',[F(-1),F(0),F(1,31),F(2,31),F(3,31)]),
        ('close_257',[F(-1,3),F(0),F(1,257),F(2,257),F(1,2)]),
        ('close_translated',[F(-3,7),F(3,7),F(3,7)+F(1,127),F(3,7)+F(2,127),F(2)]),
    ]:
        p=polynomial(F(-3,5),[(linear(roots[0]),2),(linear(roots[2]),2)])
        q=polynomial(F(7,11),[(linear(roots[1]),1),(linear(roots[2]),1),(linear(roots[3]),1)])
        r=polynomial(F(-5,7),[(linear(roots[4]),3)])
        out.append((label,p,q,r,[Surd(root) for root in roots]))
    # Real roots are generated by exact factors in a single quadratic field.
    for label,d,shift,ratios in [
        ('sqrt2_close_shift',2,F(1,17),[F(1,3),F(7,5)]),
        ('sqrt3_shared_even',3,F(-1,13),[F(-2,3),F(12,7)]),
        ('sqrt5_close_shift',5,F(1,31),[F(9,4),F(-11,5)]),
    ]:
        base=quadratic(F(0),d)
        shifted=quadratic(shift,d)
        p=polynomial(F(-5,9),[(base,2)])
        q=polynomial(F(13,17),[(base,1),(shifted,1)])
        r=polynomial(F(-7,11),[(linear(ratios[0]),2),(linear(ratios[1]),1)])
        roots=[Surd(F(0),F(-1),d),Surd(F(0),F(1),d),
               Surd(shift,F(-1),d),Surd(shift,F(1),d)]+[Surd(root,F(0),d) for root in ratios]
        out.append((label,p,q,r,roots))
    # Degree10 atom with only three distinct real roots and positive no-root factors.
    roots=[F(-5,6),F(1,19),F(8,3)]
    p=polynomial(F(-11,23),[(linear(roots[0]),4),(linear(roots[1]),2),(positive,2)])
    q=polynomial(F(17,29),[(linear(roots[1]),3),(linear(roots[2]),2)])
    r=(F(1),F(0),F(1),F(0),F(1))
    out.append(('degree10_even_shared_positive',p,q,r,[Surd(root) for root in roots]))
    return out


def generate():
    lines=['// Independent Fraction/Q(sqrt(d)) oracle from tools/generate_realcad_review.py.']
    data=[]
    for label,p,q,r,roots in families():
        roots=sorted(set(roots),key=cmp_to_key(lambda a,b:(a-b).sign()))
        for formula in formulas(p,q,r):
            polys=collect(formula)
            d=roots[0].d
            samples=[roots[0]+F(-1)]
            for i,root in enumerate(roots):
                samples += [root, (root+roots[i+1])*F(1,2) if i+1<len(roots) else root+1]
            signs=[[evaluate(poly,point).sign() for poly in polys] for point in samples]
            truth=[holds(formula,point) for point in samples]
            index=len(data)
            root_literal='['+', '.join('('+rational_literal(root.a)+', '+rational_literal(root.b)+', '+str(root.d)+')' for root in roots)+']'
            lines += ['', '///|',f'test "independent realcad review fixture {index} {label}" {{','  review_assert_fixture(',
                      '    '+moon_formula(formula)+',','    '+root_literal+',','    '+json.dumps(signs)+',',
                      '    ['+', '.join(str(t).lower() for t in truth)+'],','  )','}']
            data.append(dict(index=index,family=label,max_atom_degree=max(len(p)-1 for p in polys),
                             product_degree=sum(max(0,len(p)-1) for p in polys),
                             roots=[dict(a=str(root.a),b=str(root.b),d=root.d) for root in roots],
                             signs=signs,truth=truth,
                             polynomials=[[str(c) for c in p] for p in polys]))
    return '\n'.join(lines)+'\n',data


def tokens(source):
    source=re.sub(r',\s*([\]\)])',r'\1',source)
    return re.findall(r'"(?:\\.|[^"\\])*"|\S',source)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check',action='store_true')
    args=parser.parse_args()
    source,data=generate()
    if args.check: assert tokens(OUTPUT.read_text())==tokens(source),'realcad review fixture drift'
    else: OUTPUT.write_text(source)
    ARTIFACT.parent.mkdir(parents=True,exist_ok=True)
    ARTIFACT.write_text(json.dumps(dict(oracle='Fraction plus exact quadratic-field predicates; no SymPy/Sturm',cases=data),indent=2)+'\n')
    print(f"{'Checked' if args.check else 'Wrote'} {len(data)} independent Fraction/surd sign-cell review fixtures.")


if __name__=='__main__': main()
