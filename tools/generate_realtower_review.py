#!/usr/bin/env python3
"""Adversarial realtower oracle: independent Fraction fields and exact SymPy roots."""
from fractions import Fraction as F
from pathlib import Path
from random import Random
import argparse
import json
import re
import sympy as sp

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT/'src/realtower/independent_review_oracle_wbtest.mbt'
ART = ROOT/'.tools/cadprojection-20261116/realtower-review-oracle.json'


def q(n):
    n=F(n)
    return f'@oracle.rational({n.numerator}, {n.denominator})'


def qs(values):
    return '['+', '.join(map(q,values))+']'


def order(n):
    return '@core.'+{-1:'Less',0:'Equal',1:'Greater'}[int(n)]


def sign(n):
    return (n>0)-(n<0)


def pair_add(u,v):
    return (u[0]+v[0],u[1]+v[1])


def pair_neg(u):
    return (-u[0],-u[1])


def pair_mul(u,v):
    return (u[0]*v[0]+2*u[1]*v[1],u[0]*v[1]+u[1]*v[0])


def pair_inv(u):
    norm=u[0]*u[0]-2*u[1]*u[1]
    assert norm
    return (u[0]/norm,-u[1]/norm)


def pair_sign(u,embedding):
    a,b=u[0],u[1]*embedding
    if not b:return sign(a)
    if not a:return sign(b)
    if sign(a)==sign(b):return sign(a)
    return sign(a)*sign(a*a-2*b*b)


def pair_eval(cs):
    out=(F(0),F(0))
    for c in reversed(cs):out=pair_add((F(c),F(0)),pair_mul((F(0),F(1)),out))
    return out


def eval_q(cs,x):
    out=F(0)
    for c in reversed(cs):out=c+x*out
    return out


def poly_mul(a,b):
    out=[F(0)]*(len(a)+len(b)-1)
    for i,x in enumerate(a):
        for j,y in enumerate(b):out[i+j]+=x*y
    return out


def coeffs(expr,x):
    return [sp.expand(expr).coeff(x,i) for i in range(sp.degree(expr,x)+1)]


def generate():
    lines=['// Independent Fraction arithmetic and exact SymPy count_roots; no Float oracle.']
    rational_records=[];quadratic_records=[];query_records=[];count_records=[]
    roots=list(map(F,[-2,0,1]))+[F(3,2)]
    modulus=[F(1)]
    for root in roots:modulus=poly_mul(modulus,[-root,F(1)])
    for i,root in enumerate(roots):
        lower=(roots[i-1]+root)/2 if i else root-1
        span=f'@sturm.Interval::{{ lower: {q(lower)}, upper: {q(root)} }}'
        for j,(num,den) in enumerate([([F(2),F(-3),F(1)],[-roots[(i+1)%len(roots)],F(1)]),
                                    ([F(5,3),F(-7,2),F(2),F(1,5)],[-roots[(i+2)%len(roots)],F(1)])]):
            want=eval_q(num,root)/eval_q(den,root)
            lines+=['','///|',f'test "independent reducible rational component {i} expression {j}" {{',
                    f'  review_rational_fixture({qs(modulus)}, {span}, {qs(num)}, {qs(den)}, {q(want)}, {order(sign(want))})','}']
            rational_records.append(dict(root=str(root),modulus=list(map(str,modulus)),interval=[str(lower),str(root)],numerator=list(map(str,num)),denominator=list(map(str,den)),value=str(want)))
    rng=Random(0x7A113E)
    inputs=[([F(-1),F(0),F(1)],[F(1),F(1)]),
            ([F(-2),F(0),F(1)],[F(3),F(-2)]),
            ([F(0),F(3),F(1),F(-1)],[F(2),F(1)]),
            ([F(5,7),F(-2,3),F(0),F(1,5),F(1,11)],[F(-3,2),F(1,4),F(2,7)])]
    for _ in range(4):
        inputs.append(([F(rng.randrange(-4,5),rng.choice([1,3,5])) for _ in range(4)],
                       [F(rng.randrange(-4,5),rng.choice([1,3])) for _ in range(3)]))
    for embedding in [1,-1]:
        for i,(num,den) in enumerate(inputs):
            a,b=pair_eval(num),pair_eval(den)
            want=pair_mul(a,pair_inv(b))
            sy=sp.sqrt(2)*embedding
            actual=sp.cancel(sum(sp.Rational(c.numerator,c.denominator)*sy**j for j,c in enumerate(num))/sum(sp.Rational(c.numerator,c.denominator)*sy**j for j,c in enumerate(den)))
            expected=sp.Rational(want[0].numerator,want[0].denominator)+sp.Rational(want[1].numerator,want[1].denominator)*sy
            assert sp.simplify(actual-expected)==0
            assert int(sp.sign(expected))==pair_sign(want,embedding)
            lines+=['','///|',f'test "independent quadratic field embedding {embedding} expression {i}" {{',
                    f'  review_quadratic_fixture({str(embedding>0).lower()}, {qs(num)}, {qs(den)}, {q(want[0])}, {q(want[1])}, {order(pair_sign(want,embedding))})','}']
            quadratic_records.append(dict(embedding=embedding,numerator=list(map(str,num)),denominator=list(map(str,den)),value=list(map(str,want)),sign=pair_sign(want,embedding)))
    # Direct Sturm-Tarski queries: distinct rational roots, repeated factors,
    # a common query root, and Taylor jets at the included/excluded endpoints.
    t=sp.Symbol('t')
    for i,(rs,query) in enumerate([([(-1,2),(0,3),(1,1)],t),
                                  ([(0,1),(1,2),(2,2)],(t-1)**2),
                                  ([(-2,1),(-1,1),(1,1),(2,1)],(t*t-1)*(t+2)),
                                  ([(0,3),(1,2)],-t*t*(t-1))]):
        source=sp.prod((t-r)**m for r,m in rs)
        for j,(lo,hi) in enumerate([(-2,-1),(-1,0),(0,1),(1,2),(-3,3)]):
            expected=sum(sign(F(query.subs(t,r))) for r,m in rs if lo<r<=hi)
            lines+=['','///|',f'test "independent Tarski repeated endpoint query {i} span {j}" {{',
                    f'  review_query_fixture({qs(map(F,coeffs(source,t)))}, {qs(map(F,coeffs(query,t)))}, @sturm.Interval::{{lower: {q(lo)}, upper: {q(hi)}}}, {expected})','}']
            query_records.append(dict(source=str(source),query=str(query),interval=[lo,hi],expected=expected))
    # Independent exact symbolic real-root counts over the selected embeddings.
    a=sp.sqrt(2); b=sp.root(2,4)
    exprs=[(1,True,(t-a)*(t+1)*(t-2)),(1,False,(t+a)*(t+1)*(t-2)),
           (1,True,(t*t+a)*(t-a)),(1,False,(t*t-a)*(t+a)),
           (1,True,(t*t-a)*(t*t+a-1)),(1,False,(t*t+a)*(t*t-a-1)),
           (2,True,(t*t-b)*(t-1)),(2,True,(t*t-b)*(t*t+a))]
    for i,(depth,positive,source) in enumerate(exprs):
        source=sp.expand(source)
        gen=a if depth==1 else b
        P=sp.Poly(source,t,extension=gen)
        values=[]
        for c in coeffs(source,t):
            # Represent coefficients in 1, generator, ..., generator^(2^depth-1).
            rep=sp.to_number_field(c,gen).native_coeffs()
            rep=[sp.Rational(v) for v in rep][::-1]
            if depth==1 and not positive:rep=[v*((-1)**k) for k,v in enumerate(rep)]
            values.append(rep)
        spans=[]
        for lo,hi in [(-3,-1),(-1,0),(0,1),(1,2),(-3,3)]:
            count=int(P.count_roots(lo,hi))-int(P.eval(lo)==0)
            assert not source.atoms(sp.Float)
            spans.append((lo,hi,count))
        encoded='['+', '.join(qs(map(F,cs)) for cs in values)+']'
        expected='['+', '.join(f'(@sturm.Interval::{{lower: {q(lo)}, upper: {q(hi)}}}, {count})' for lo,hi,count in spans)+']'
        lines+=['','///|',f'test "independent exact irrational relative degree {sp.degree(source,t)} source {i}" {{',
                f'  review_relative_count_fixture({depth}, {str(positive).lower()}, {encoded}, {expected})','}']
        count_records.append(dict(depth=depth,positive_embedding=positive,source=str(source),ascending_coefficients=[list(map(str,cs)) for cs in values],spans=spans))
    shifted_records=[]
    shifted=[]
    for h,k in [(F(1),F(1)),(F(-3,2),F(1,2)),(F(2,3),F(2,3))]:
        for embedding in [1,-1]:
            span=(h,h+2*k) if embedding>0 else (h-2*k,h)
            shifted.append(([h*h-2*k*k,-2*h,F(1)],span,(h,k*embedding),None))
    for h,r in [(F(1),F(2)),(F(2,3),F(3,2))]:
        shifted.append(([h*h-r*r,-2*h,F(1)],(h-r,h+r),(h+r,F(0)),h+r))
        shifted.append(([h*h-r*r,-2*h,F(1)],(h-r-1,h),(h-r,F(0)),h-r))
    # A repeated root makes the squarefree definition linear; this exercises the
    # same public API without assuming that every quadratic stays degree two.
    shifted.append(([F(4),F(-4),F(1)],(F(1),F(2)),(F(2),F(0)),F(2)))
    for i,(modulus,span,root_pair,rational_root) in enumerate(shifted):
        h= -modulus[1]/2
        queries=[(F(0),F(0)),(F(1),F(0)),(F(-1),F(0)),(-h,F(1)),(h,F(-1))]
        if rational_root is None:
            for near in [F(239,169),F(577,408),F(1393,985),F(19601,13860)]:
                queries.append((-h-root_pair[1]*near,F(1)))
            a=F(-7,5)
            queries.append((-a*h-a*root_pair[1]*F(239,169),a))
        else:
            queries += [(-rational_root,F(1)),(rational_root,F(-1)),
                        (-rational_root+F(1,1048576),F(1)),
                        (-rational_root-F(1,1048576),F(1))]
        expected=[pair_sign(pair_add((d,F(0)),pair_mul((a,F(0)),root_pair)),1) for d,a in queries]
        encoded='['+', '.join(f'({q(d)}, {q(a)}, {order(s)})' for (d,a),s in zip(queries,expected))+']'
        lines+=['','///|',f'test "independent shifted quadratic branch and cancellation {i}" {{',
                f'  review_shifted_quadratic_fixture({qs(modulus)}, @sturm.Interval::{{lower: {q(span[0])}, upper: {q(span[1])}}}, {encoded})','}']
        shifted_records.append(dict(modulus=list(map(str,modulus)),interval=list(map(str,span)),root_pair=list(map(str,root_pair)),
                                    queries=[dict(constant=str(d),linear=str(a),expected=s) for (d,a),s in zip(queries,expected)]))
    irrational_shifted=[]
    for branch in [1,-1]:
        root=(F(branch),F(1))
        queries=[((F(0),F(0)),(F(0),F(0))),((F(1),F(0)),(F(0),F(0))),
                 ((F(0),F(-1)),(F(1),F(0))),((F(-branch),F(-1)),(F(1),F(0))),
                 ((F(branch),F(1)),(F(-1),F(0))),((F(-2),F(-branch)),(F(0),F(1))),
                 ((-F(branch)-F(239,169),F(0)),(F(1),F(0))),
                 ((-F(branch)-F(577,408),F(0)),(F(1),F(0))),
                 ((F(-2),F(0)),(F(0),F(1)))]
        expected=[pair_sign(pair_add(d,pair_mul(a,root)),1) for d,a in queries]
        encoded='['+', '.join(f'({qs(d)}, {qs(a)}, {order(s)})' for (d,a),s in zip(queries,expected))+']'
        lines+=['','///|',f'test "independent shifted irrational parent quadratic branch {branch}" {{',
                f'  review_irrational_shift_fixture({str(branch>0).lower()}, {encoded})','}']
        irrational_shifted.append(dict(parent_root='sqrt(2)',modulus='beta^2-2*alpha*beta+1',branch=branch,
                                        root_pair=list(map(str,root)),queries=[dict(constant=list(map(str,d)),linear=list(map(str,a)),expected=s) for (d,a),s in zip(queries,expected)]))
    return '\n'.join(lines)+'\n',dict(sympy=sp.__version__,no_float=True,rational=rational_records,quadratic=quadratic_records,tarski=query_records,relative_count=count_records,shifted_quadratic=shifted_records,irrational_shifted_quadratic=irrational_shifted)


def tokens(source):
    return re.findall(r'"(?:\\.|[^"\\])*"|\S',re.sub(r',\s*([\]\)}])',r'\1',source))


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check',action='store_true')
    args=parser.parse_args()
    source,data=generate()
    if args.check:assert tokens(OUT.read_text())==tokens(source),'realtower independent review fixture drift'
    else:OUT.write_text(source)
    ART.parent.mkdir(parents=True,exist_ok=True)
    ART.write_text(json.dumps(data,indent=2)+'\n')
    print(f"{'Checked' if args.check else 'Wrote'} {sum(len(data[k]) for k in ['rational','quadratic','tarski','relative_count','shifted_quadratic','irrational_shifted_quadratic'])} independent review tests: Fraction rational/quadratic, repeated endpoint Tarski, exact SymPy relative counts, and shifted quadratic cancellation.")


if __name__=='__main__':main()
