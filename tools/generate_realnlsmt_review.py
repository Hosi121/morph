#!/usr/bin/env python3
"""Finite independent nonlinear-SMT review with Z3 qfnra-nlsat.

All polynomial coefficients are Fraction values. Reference decisions must be
exact sat/unsat; unknown is a generation error. Z3 never runs inside MoonBit.
Use --probe first to freeze the three-case performance gate, then generate the
full finite corpus. --check permits moon fmt whitespace/trailing commas only.
"""
from __future__ import annotations
import argparse
from dataclasses import dataclass
from fractions import Fraction as F
import hashlib
import importlib.metadata
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent

@dataclass(frozen=True)
class P:
    n: int
    terms: tuple[tuple[tuple[int, ...], F], ...]
    @classmethod
    def make(cls, n, values):
        return cls(n, tuple(sorted(((e, F(c)) for e, c in values.items() if c), reverse=True)))
    @classmethod
    def const(cls, n, c): return cls.make(n, {(0,) * n: F(c)})
    def coerce(self, other): return other if isinstance(other, P) else P.const(self.n, other)
    def __add__(self, other):
        other=self.coerce(other); assert self.n == other.n
        values=dict(self.terms)
        for e,c in other.terms: values[e]=values.get(e,F(0))+c
        return P.make(self.n,values)
    __radd__=__add__
    def __neg__(self): return P.make(self.n,{e:-c for e,c in self.terms})
    def __sub__(self,other): return self+-self.coerce(other)
    def __rsub__(self,other): return self.coerce(other)+-self
    def __mul__(self,other):
        other=self.coerce(other); assert self.n == other.n
        values={}
        for a,u in self.terms:
            for b,v in other.terms:
                e=tuple(i+j for i,j in zip(a,b)); values[e]=values.get(e,F(0))+u*v
        return P.make(self.n,values)
    __rmul__=__mul__
    def __pow__(self,n):
        assert isinstance(n,int) and n>=0
        result=P.const(self.n,1)
        for _ in range(n): result=result*self
        return result

def variables(n):
    return [P.make(n,{tuple(int(i==j) for i in range(n)):F(1)}) for j in range(n)]
def A(p,rel='eq'): return ('atom',p,rel)
def AND(*values):
    assert values
    return values[0] if len(values)==1 else ('and',values[0],AND(*values[1:]))
def OR(*values):
    assert values
    return values[0] if len(values)==1 else ('or',values[0],OR(*values[1:]))
def NOT(value): return ('not',value)

@dataclass(frozen=True)
class Case:
    name: str
    n: int
    formula: tuple
    expected: bool
    proof: str


def corpus():
    cases=[]
    def add(name,n,source,expected,proof): cases.append(Case(name,n,source,expected,proof))
    x,y=variables(2)
    add('probe dependent irrational diagonal',2,AND(A(x*x-2),A(y-x)),True,'x=y=sqrt(2).')
    x,y,z=variables(3)
    add('probe nullified product fibre',3,AND(A(x),A(x*y),A(z*z-2)),True,'x=0, arbitrary y, z=sqrt(2).')
    x,y,z,w=variables(4); product=(x-y)*(z-w)
    add('probe four variable shared product contradiction',4,AND(A(product),A(product,'gt')),False,'The identical product cannot be zero and positive.')
    x,y=variables(2)
    add('bilinear nonzero product at zero factor',2,AND(A(x*y-1),A(x)),False,'x=0 forces x*y=0, contradicting x*y=1.')
    add('bilinear nullification with irrational other coordinate',2,AND(A(x*y),A(x),A(y*y-2)),True,'x=0,y=sqrt(2).')
    add('bilinear negative product of positives',2,AND(A(x*y+1),A(x,'gt'),A(y,'gt')),False,'A product of positive reals is positive, not -1.')
    add('bilinear negative branch Boolean alternative',2,AND(A(x*y-1),OR(A(x,'lt'),A(y,'lt'))),True,'x=y=-1.')
    add('dependent irrational product exact',2,AND(A(x*x-2),A(y-x),A(x*y-2)),True,'x=y=sqrt(2), so x*y=2.')
    add('dependent irrational product disequality',2,AND(A(x*x-2),A(y-x),A(x*y-2,'ne')),False,'y=x and x*x=2 imply x*y=2.')
    add('conjugate roots exhaustive alternatives',2,AND(A(x*x-2),A(y*y-2),OR(A(x-y),A(x+y))),True,'The pair x=y=sqrt(2) satisfies the first alternative.')
    add('conjugate roots neither alternative',2,AND(A(x*x-2),A(y*y-2),A(x-y,'ne'),A(x+y,'ne')),False,'Equal squares imply (x-y)*(x+y)=0 in a field.')
    add('square root over negative parent',2,AND(A(y*y-x),A(x+1)),False,'x=-1 would require y*y=-1.')
    add('repeated section excludes zero root',2,AND(A(y*y-x),A(x),A(y,'ne')),False,'x=0 implies y*y=0 and y=0.')
    add('nested positive fourth root',2,AND(A(x*x-2),A(y*y-x),A(x,'gt'),A(y,'gt')),True,'x=sqrt(2),y=positive fourth root of 2.')
    radius=x*x+y*y
    add('circle rational external threshold',2,AND(A(radius-1),A(x-F(3,2),'gt')),False,'x*x<=1 on the circle, so x cannot exceed 3/2.')
    add('circle rational endpoint section',2,AND(A(radius-1),A(x-1),A(y)),True,'x=1,y=0.')
    add('circle rational endpoint rejects off axis',2,AND(A(radius-1),A(x-1),A(y,'ne')),False,'x=1 on this circle forces y=0.')
    add('annulus rational open bounds',2,AND(A(radius-1,'lt'),A(radius-F(1,4),'gt')),True,'x=3/4,y=0 gives squared radius 9/16.')
    add('incompatible concentric open bounds',2,AND(A(radius-1,'lt'),A(radius-4,'gt')),False,'The same squared radius cannot be less than 1 and greater than 4.')
    product=x*y; circle=radius-1
    add('CNF nonlinear disjunction excludes both branches',2,AND(OR(A(product),A(circle)),A(product,'ne'),A(circle,'ne')),False,'The first disjunction contradicts the two disequalities.')
    add('CNF nonlinear surviving irrational branch',2,AND(OR(A(product),A(circle)),A(product,'ne')),True,'x=y=1/sqrt(2), so circle=0 and product=1/2.')
    p=x*x-1; q=y*y-1
    add('CNF separate nonlinear positive conflicts',2,AND(OR(A(p,'le'),A(q,'le')),A(p,'gt'),A(q,'gt')),False,'Both alternatives contradict the asserted strict positives.')
    add('CNF exactly one nonlinear boundary',2,AND(OR(A(p),A(q)),OR(A(p,'ne'),A(q,'ne'))),True,'x=1,y=0 makes exactly p zero.')
    add('CNF both nonlinear boundaries forbidden',2,AND(OR(A(p),A(q)),OR(A(p,'ne'),A(q,'ne')),A(p),A(q)),False,'The disequality disjunction contradicts p=q=0.')
    add('negated nonlinear conjunction surviving branch',2,AND(NOT(AND(A(p),A(q))),A(p)),True,'x=1,y=0 makes p=0 and q nonzero.')
    x,y,z=variables(3)
    add('trilinear graph at nullified first factor',3,AND(A(x*y-z),A(x),A(z-1)),False,'x=0 forces z=0 in z=x*y.')
    add('trilinear graph irrational nullification',3,AND(A(x*y-z),A(x),A(z),A(y*y-2)),True,'x=z=0,y=sqrt(2).')
    add('dependent three coordinate irrational diagonal',3,AND(A(x*x-2),A(y-x),A(z-y),A(z*z-2)),True,'x=y=z=sqrt(2).')
    add('dependent three coordinate inconsistent square',3,AND(A(x*x-2),A(y-x),A(z-y),A(z*z-2,'ne')),False,'All coordinates equal x, whose square is 2.')
    add('three squares zero with nonzero coordinate alternative',3,AND(A(x*x+y*y+z*z),OR(A(x,'ne'),A(y,'ne'),A(z,'ne'))),False,'A sum of real squares is zero only when all coordinates vanish.')
    add('three coordinate sphere diagonal plane',3,AND(A(x*x+y*y+z*z-2),A(x-y),A(z)),True,'x=y=1,z=0.')
    add('three products nullified middle factor',3,AND(A(x*y),A(y*z),A(x*z-1)),True,'x=z=1,y=0.')
    add('three products require middle factor nonzero',3,AND(A(x*y),A(y*z),A(x*z-1),A(y,'ne')),False,'y nonzero forces x=z=0, contradicting x*z=1.')
    x,y,z,w=variables(4); product=(x-y)*(z-w)
    add('four variable nullified factor with dependent irrational pair',4,AND(A(product),A(x-y),A(z*z-2),A(w-z)),True,'x=y=0,z=w=sqrt(2).')
    add('four variable nonzero product with zero factor',4,AND(A(product,'ne'),A(x-y)),False,'The asserted zero factor makes the product zero.')
    add('four variable nonzero product and both factors',4,AND(A(product,'ne'),A(x-y,'ne'),A(z-w,'ne')),True,'x=z=1,y=w=0.')
    add('four variable sum of products nullified coefficients',4,AND(A(x*y+z*w),A(x),A(z)),True,'x=z=0 and arbitrary y,w.')
    add('four variable affine product graph contradiction',4,AND(A(x*y+z*w-1),A(x),A(z)),False,'x=z=0 makes the sum of products zero, not one.')
    add('four coordinate irrational diagonal',4,AND(A(x-y),A(y-z),A(z-w),A(x*x-2)),True,'x=y=z=w=sqrt(2).')
    add('four coordinate irrational diagonal inconsistent square',4,AND(A(x-y),A(y-z),A(z-w),A(x*x-2),A(w*w-2,'ne')),False,'The diagonal equations make w*w=x*x=2.')
    add('four weighted squares zero excludes last coordinate',4,AND(A(x*x+2*y*y+3*z*z+F(1,2)*w*w),A(w,'ne')),False,'Every positive weighted square must vanish.')
    return cases


# Fixed after the finite native timing probe: these are performance stress
# inputs, never failures or UNSAT inferred from an exhausted execution budget.
STRESS_NAMES = {
    'dependent three coordinate irrational diagonal',
    'dependent three coordinate inconsistent square',
    'four coordinate irrational diagonal inconsistent square',
}

def zpoly(p,vs):
    result=z3.RealVal(0)
    for exponents,c in p.terms:
        term=z3.Q(c.numerator,c.denominator)
        for variable,power in zip(vs,exponents):
            for _ in range(power): term=term*variable
        result=result+term
    return result

def zformula(source,vs):
    kind=source[0]
    if kind=='atom':
        value=zpoly(source[1],vs)
        return {'eq':lambda:value==0,'ne':lambda:value!=0,'lt':lambda:value<0,
                'le':lambda:value<=0,'gt':lambda:value>0,'ge':lambda:value>=0}[source[2]]()
    if kind=='not': return z3.Not(zformula(source[1],vs))
    left,right=zformula(source[1],vs),zformula(source[2],vs)
    return z3.And(left,right) if kind=='and' else z3.Or(left,right)

def smtq(value):
    n=value.numerator; d=value.denominator
    numerator=str(n) if n>=0 else f'(- {-n})'
    return numerator if d==1 else f'(/ {numerator} {d})'
def smtpoly(p):
    terms=[]
    for exponents,c in p.terms:
        factors=[smtq(c)]
        factors += [f'x{i}' for i,power in enumerate(exponents) for _ in range(power)]
        terms.append(f'(* {" ".join(factors)})')
    return '0' if not terms else f'(+ {" ".join(terms)})'
def smtformula(source):
    if source[0]=='atom':
        op={'eq':'=','ne':'distinct','lt':'<','le':'<=','gt':'>','ge':'>='}[source[2]]
        return f'({op} {smtpoly(source[1])} 0)'
    if source[0]=='not': return f'(not {smtformula(source[1])})'
    return f'({source[0]} {smtformula(source[1])} {smtformula(source[2])})'

def moonpoly(p):
    values=', '.join(f'({c.numerator}, {c.denominator}, [{", ".join(map(str,e))}])' for e,c in p.terms)
    return f'review_polynomial({p.n}, [{values}])'
def moonformula(source):
    kind=source[0]
    if kind=='atom':
        relation={'eq':'EqualZero','ne':'NotZero','lt':'LessZero','le':'AtMostZero','gt':'GreaterZero','ge':'AtLeastZero'}[source[2]]
        return f'@qf.Atom({moonpoly(source[1])}, @qf.{relation})'
    if kind=='not': return f'@qf.Negation({moonformula(source[1])})'
    ctor='Conjunction' if kind=='and' else 'Disjunction'
    return f'@qf.{ctor}({moonformula(source[1])}, {moonformula(source[2])})'

def syntax(source):
    tokens=[t for t in re.findall(r'//[^\n]*|"(?:\\.|[^"\\])*"|[^\s]',source) if not t.startswith('//')]
    return [t for i,t in enumerate(tokens) if not(t==',' and i+1<len(tokens) and tokens[i+1] in ')]}')]

def main():
    global z3
    import z3
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--probe',action='store_true')
    parser.add_argument('--check',action='store_true')
    parser.add_argument('--stress',action='store_true',help='also emit the three documented dependent-square timing outliers')
    options=parser.parse_args()
    cases=corpus()
    if options.probe: cases=cases[:3]
    rows=['// Generated by tools/generate_realnlsmt_review.py; exact Z3 qfnra-nlsat reference.']
    evidence=[]
    for case in cases:
        vs=z3.Reals(' '.join(f'x{i}' for i in range(case.n)))
        solver=z3.Tactic('qfnra-nlsat').solver(); solver.set(timeout=30000)
        formula=zformula(case.formula,vs); solver.add(formula); result=solver.check()
        assert result in (z3.sat,z3.unsat),(case.name,result,solver.reason_unknown())
        assert (result==z3.sat)==case.expected,(case.name,result,case.expected)
        if result==z3.sat: assert z3.is_true(solver.model().eval(formula,model_completion=True))
        declarations='\n'.join(f'(declare-fun x{i} () Real)' for i in range(case.n))
        smt=f'(set-logic QF_NRA)\n{declarations}\n(assert {smtformula(case.formula)})\n(check-sat-using qfnra-nlsat)\n'
        # Independently parse the emitted exact QQ SMT-LIB to check its translation.
        replay=z3.Tactic('qfnra-nlsat').solver(); replay.set(timeout=30000)
        replay.from_string(smt[:smt.index('(check-sat-using')]); assert replay.check()==result
        evidence.append({'name':case.name,'arity':case.n,'expected':str(result),'hand_argument':case.proof,'smt2':smt,'sha256':hashlib.sha256(smt.encode()).hexdigest(),'default_case':case.name not in STRESS_NAMES})
        if options.stress or case.name not in STRESS_NAMES:
            rows+=['','///|',f'test "independent Z3 review {case.name}" {{',f'  let source = {moonformula(case.formula)}',f'  review_expect({case.n}, source, {str(case.expected).lower()})','}']
    output=ROOT/'src/realnlsmt/independent_review_z3_wbtest.mbt'
    source='\n'.join(rows)+'\n'
    library=Path(z3.__file__).parent/'lib/libz3.so'
    provenance={'reference':'Z3 qfnra-nlsat','z3_version':z3.get_full_version(),'wheel_version':importlib.metadata.version('z3-solver'),'libz3_sha256':hashlib.sha256(library.read_bytes()).hexdigest(),'input_coefficients':'Fraction/QQ only; no Float, approximation, evalf, or oracle call in the MoonBit kernel','scope':'three-case performance probe' if options.probe else 'finite independent nonlinear SMT corpus','cases':evidence}
    report=ROOT/'docs/measurements/realnlsmt-review-oracle-20261116.json'
    if options.check:
        assert output.exists() and syntax(output.read_text())==syntax(source),'generated fixture differs'
        assert json.loads(report.read_text())==provenance,'provenance differs'
    else:
        output.write_text(source); report.write_text(json.dumps(provenance,indent=2)+'\n')
    selected=[c for c in cases if options.stress or c.name not in STRESS_NAMES]
    print(('Verified' if options.check else 'Generated')+f' {len(selected)} default/emitted cases; external exact Z3 reference validates {len(cases)} candidates: '+str(sum(c.expected for c in cases))+' SAT, '+str(sum(not c.expected for c in cases))+' UNSAT.')

if __name__=='__main__': main()
