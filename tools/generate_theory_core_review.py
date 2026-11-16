#!/usr/bin/env python3
"""Independent exact whole/subset CAD-cover review; Z3 never runs in the kernel."""
from __future__ import annotations
import argparse
from dataclasses import dataclass
from fractions import Fraction as F
import hashlib
import importlib.metadata
import json
from pathlib import Path
import generate_realnlsmt_review as transport
from generate_realnlsmt_review import P,A,AND,OR,NOT,variables

ROOT=Path(__file__).resolve().parent.parent

@dataclass(frozen=True)
class Pair:
    name: str
    n: int
    whole: tuple
    subset: tuple
    subset_sat: bool
    pruned: bool
    reusable: bool
    reason: str


def corpus():
    rows=[]
    def add(name,n,whole,subset,sat,reusable=True,pruned=False,reason=''):
        rows.append(Pair(name,n,whole,subset,sat,pruned,reusable,reason))
    x,=variables(1)
    clash=AND(A(x),A(x,'ne'))
    add('zero equality weakening is satisfiable',1,clash,A(x),True,False,reason='x=0.')
    add('zero disequality weakening is satisfiable',1,clash,A(x,'ne'),True,False,reason='x=1.')
    p=x*x+1
    add('positive square with redundant fixed point',1,AND(A(p,'lt'),A(x-3)),A(p,'lt'),False,reason='x^2+1 is positive for every real x; x=3 is a redundant conjunct.')
    scale=AND(A(-3*x,'ge'),A(x,'gt'))
    add('negative scaling cannot refute a positive weakening',1,scale,A(x,'gt'),True,False,reason='x=1 satisfies the target; the dropped negative-scale bound was essential.')
    add('negative scaling joint conflict remains',1,scale,scale,False,reason='-3x>=0 implies x<=0, incompatible with x>0.')
    endpoint=AND(A(x-2),A(x*x-4,'ne'),A(x,'ge'))
    add('closed endpoint core shares auxiliary projection',1,endpoint,AND(A(x-2),A(x*x-4,'ne')),False,reason='x=2 forces x^2-4=0.')
    add('endpoint disequality alone has models',1,endpoint,A(x*x-4,'ne'),True,False,reason='x=0 is a target model.')
    add('negated equality target remains satisfiable',1,AND(NOT(A(x)),A(x)),NOT(A(x)),True,False,reason='x=1 is a target model.')
    hidden=AND(('truth',False),A(p,'lt'))
    add('genuine UNSAT subset hidden by old shortened leaf',1,hidden,A(p,'lt'),False,False,True,reason='The target is UNSAT, but the source stops at a depth-zero false leaf before signs of x^2+1 are observed. Safe producer refusal is expected.')
    add('false target can discard the old tree',1,hidden,('truth',False),False,True,True,reason='False is independent of all coordinates and needs no old subtree.')
    x,y=variables(2);d=x*x-2
    irr=AND(A(d),A(d*y,'gt'),A(y-3))
    add('irrational section reduced conflict',2,irr,AND(A(d),A(d*y,'gt')),False,reason='Both roots of x^2-2 nullify the coefficient of y, making d*y zero.')
    add('irrational source does not forbid an independent suffix',2,irr,A(y-3),True,False,reason='Any x with y=3 is a target model.')
    bilinear=AND(A(x),A(x*y-1),A(y,'ge'))
    add('bilinear zero-factor core',2,bilinear,AND(A(x),A(x*y-1)),False,reason='x=0 forces xy-1=-1.')
    add('bilinear graph alone has a model',2,bilinear,A(x*y-1),True,False,reason='x=y=1.')
    boundary=AND(A(x,'ge'),A(x,'le'),A(x*y,'gt'))
    add('closed boundary keeps both required bounds',2,boundary,AND(A(x,'ge'),A(x,'le')),True,False,reason='x=0,y=0 satisfies both bounds; strict-product conjunct caused the conflict.')
    helper=OR(A(y-x),NOT(A(y-x)))
    add('tautological helper only partitions geometry',2,AND(A(x*x+1,'lt'),helper),A(x*x+1,'lt'),False,True,True,reason='The target positive-square contradiction is uniform in y; y-x is a geometric helper, not an assumption.')
    rational=AND(A(x-F(2,3)),A((3*x-2)*y-1),A(y-1))
    add('exact rational nullification core',2,rational,AND(A(x-F(2,3)),A((3*x-2)*y-1)),False,reason='x=2/3 nullifies 3x-2 and leaves -1.')
    false_atom=A(P.const(0,1),'lt');true_atom=A(P.const(0,0))
    add('zero dimensional true target is not a refutation',0,AND(false_atom,true_atom),true_atom,True,False,reason='The unique empty coordinate tuple satisfies 0=0.')
    return rows


def zformula(value,vs,z3):
    kind=value[0]
    if kind=='truth':return z3.BoolVal(value[1])
    if kind=='atom':
        p=transport.zpoly(value[1],vs)
        return {'eq':lambda:p==0,'ne':lambda:p!=0,'lt':lambda:p<0,'le':lambda:p<=0,'gt':lambda:p>0,'ge':lambda:p>=0}[value[2]]()
    if kind=='not':return z3.Not(zformula(value[1],vs,z3))
    left,right=zformula(value[1],vs,z3),zformula(value[2],vs,z3)
    return z3.And(left,right) if kind=='and' else z3.Or(left,right)


def smtformula(value):
    if value[0]=='truth':return str(value[1]).lower()
    if value[0]=='atom':return transport.smtformula(value)
    if value[0]=='not':return '(not '+smtformula(value[1])+')'
    return '('+value[0]+' '+smtformula(value[1])+' '+smtformula(value[2])+')'


def moonformula(value):
    if value[0]=='truth':return '@qf.Truth('+str(value[1]).lower()+')'
    if value[0]=='atom':return transport.moonformula(value).replace('review_polynomial','core_review_polynomial')
    if value[0]=='not':return '@qf.Negation('+moonformula(value[1])+')'
    constructor='Conjunction' if value[0]=='and' else 'Disjunction'
    return '@qf.'+constructor+'('+moonformula(value[1])+', '+moonformula(value[2])+')'


def main():
    import z3
    transport.z3=z3
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--check',action='store_true');args=parser.parse_args()
    lines=['// Generated by tools/generate_theory_core_review.py; exact Z3 whole/subset decisions.'];evidence=[]
    for pair in corpus():
        vs=z3.Reals(' '.join(f'x{i}' for i in range(pair.n))) if pair.n else []
        queries=[]
        for label,formula,expected in [('whole',pair.whole,False),('subset',pair.subset,pair.subset_sat)]:
            solver=z3.Tactic('qfnra-nlsat').solver();solver.set(timeout=10000)
            term=zformula(formula,vs,z3);solver.add(term);outcome=solver.check()
            assert outcome in (z3.sat,z3.unsat),(pair.name,label,outcome)
            assert (outcome==z3.sat)==expected,(pair.name,label,outcome,expected)
            model=solver.model() if expected else None
            if model is not None:assert z3.is_true(model.eval(term,model_completion=True))
            decl='\n'.join(f'(declare-fun x{i} () Real)' for i in range(pair.n))
            smt='(set-logic QF_NRA)\n'+decl+'\n(assert '+smtformula(formula)+')\n(check-sat-using qfnra-nlsat)\n'
            replay=z3.Tactic('qfnra-nlsat').solver();replay.set(timeout=10000);replay.from_string(smt[:smt.index('(check-sat-using')]);assert replay.check()==outcome
            queries.append({'kind':label,'expected':str(outcome),'smt2':smt,'sha256':hashlib.sha256(smt.encode()).hexdigest(),'model':model.sexpr() if model is not None else None})
        evidence.append({'name':pair.name,'arity':pair.n,'source_cover':'pruned' if pair.pruned else 'full','expected_refute_on_cover':pair.reusable,'subset_satisfiable':pair.subset_sat,'reason':pair.reason,'queries':queries})
        lines+=['','///|',f'test "independent core cover Z3 {pair.name}" {{',f'  let whole = {moonformula(pair.whole)}',f'  let subset = {moonformula(pair.subset)}',f'  core_review_pair({pair.n}, whole, subset, {str(pair.subset_sat).lower()}, {str(pair.pruned).lower()}, {str(pair.reusable).lower()})','}']
    source='\n'.join(lines)+'\n'
    library=Path(z3.__file__).parent/'lib/libz3.so'
    report={'reference':'Z3 qfnra-nlsat with independent exact SMT-LIB replay','z3_version':z3.get_full_version(),'wheel_version':importlib.metadata.version('z3-solver'),'libz3_sha256':hashlib.sha256(library.read_bytes()).hexdigest(),'transport_source_sha256':hashlib.sha256(Path(transport.__file__).read_bytes()).hexdigest(),'reviewed_source_commit':'5e33f3a','pair_count':len(evidence),'exact_queries':len(evidence)*2,'subset_sat':sum(p.subset_sat for p in corpus()),'subset_unsat':sum(not p.subset_sat for p in corpus()),'scope':'Finite whole/subset pairs; target SAT must never be refuted; incomplete shortened covers can conservatively refuse a genuine UNSAT target. Extra projection polynomials are helpers, never assumptions.','cases':evidence}
    output=ROOT/'src/cad/independent_core_z3_wbtest.mbt';provenance=ROOT/'docs/measurements/theory-core-review-oracle-20261117.json'
    if args.check:
        assert transport.syntax(output.read_text())==transport.syntax(source),'generated fixtures differ'
        assert json.loads(provenance.read_text())==report,'oracle provenance differs'
    else:output.write_text(source);provenance.write_text(json.dumps(report,indent=2)+'\n')
    print(('Verified' if args.check else 'Generated')+f' {len(evidence)} whole/subset pairs, {len(evidence)*2} exact Z3 queries; {report["subset_sat"]} SAT / {report["subset_unsat"]} UNSAT targets.')


if __name__=='__main__':main()
