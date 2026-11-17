#!/usr/bin/env python3
from fractions import Fraction as Q
from pathlib import Path
import argparse,json,re
ROOT=Path(__file__).resolve().parents[2]
def product(a,b):
 out={}
 for an,ad,ae in a:
  for bn,bd,be in b:
   e=tuple(x+y for x,y in zip(ae,be));out[e]=out.get(e,Q(0))+Q(an,ad)*Q(bn,bd)
 return [(out[e].numerator,out[e].denominator,list(e)) for e in sorted(out,reverse=True) if out[e]]
def mb(ts):return '['+', '.join(f'({n}, {d}, ['+', '.join(map(str,e))+'])' for n,d,e in ts)+']'
large=[(i%5-2,(i%3)+1,[i,i%4,(i*3)%5]) for i in range(28)]
specs=[{'name':'unit-plus','n':3,'a':[(1,1,[0,0,0])],'b':large,'iterations':15000},{'name':'unit-minus','n':3,'a':[(-1,1,[0,0,0])],'b':large,'iterations':15000},{'name':'nonunit-controls','n':3,'a':[(2,3,[0,0,0])],'b':large,'iterations':5000},{'name':'dense-control','n':2,'a':[(i%5-2,1,[i%6,i//6]) for i in range(24)],'b':[(j%7-3,1,[j%6,j//6]) for j in range(18)],'iterations':500}]
for s in specs:s['expected']=product(s['a'],s['b'])
cases=[]
for n in [0,1,2,3]:
 for sign in [-1,1]:
  for size in [0,1,12]:
   a=[(sign,1,[0]*n)];b=[(i%5-2,(i%3)+1,[(i*(k+1)+k)%5 for k in range(n)]) for i in range(size)]
   b+= [(1,3,[0]*n),(-1,3,[0]*n),(0,1,[0]*n)];b=list(reversed(b))
   cases.append((n,a,b,product(a,b)))
  a=[(2*sign,2,[0]*n),(5,3,[0]*n),(-5,3,[0]*n)];b=[(2,3,[0]*n)];cases.append((n,a,b,product(a,b)))
for s in specs:cases.append((s['n'],s['a'],s['b'],s['expected']))
# Coefficient +1 on a nonconstant monomial must not trigger identity sharing.
a=[(1,1,[0,1,0])];cases.append((3,a,large,product(a,large)))
lines=['// Independent Python Fraction full convolution, including normalized unit constructors.','///|','fn unit_fixture(n : Int32,data : Array[(Int32,Int32,Array[Int32])]) -> Polynomial { polynomial(@oracle.nat(n),@oracle.chain(data.map(fn(t) { Term::{ coefficient:@oracle.rational(t.0,t.1),exponents:@oracle.chain(t.2.map(@oracle.nat)), } }))).unwrap() }','///|','fn unit_generic_oracle(a : Polynomial,b : Polynomial) -> Result[Polynomial,PolyError] { match @core.compare(a.variables,b.variables) { Equal=>Ok({variables:a.variables,terms:balanced_product_terms(a.terms,b.terms),}); _=>Err(DimensionMismatch) } }','///|','fn unit_sequential_oracle(a : Polynomial,b : Polynomial) -> Result[Polynomial,PolyError] { match @core.compare(a.variables,b.variables) { Equal=>Ok({variables:a.variables,terms:@core.fold_left(a.terms,Nil,fn(found,term) {merge_terms(found,term_times(term,b.terms))}),}); _=>Err(DimensionMismatch) } }']
for i,(n,a,b,w) in enumerate(cases):
 lines+=['///|',f'test "unit sharing independent Fraction fixture {i}" {{',f'let a=unit_fixture({n},{mb(a)})',f'let b=unit_fixture({n},{mb(b)})',f'let expected=unit_fixture({n},{mb(w)})','assert_eq(multiply(a,b),Ok(expected))','assert_eq(multiply(b,a),Ok(expected))','assert_eq(multiply(a,b),unit_generic_oracle(a,b))','assert_eq(multiply(a,b),unit_sequential_oracle(a,b))','}']
lines+=['///|','test "unit multiplication dimensions precede empty and unit checks" {','let zero=zero(@oracle.nat(2))','let one=unit_fixture(0,[(1,1,[])])','assert_eq(multiply(zero,one),Err(DimensionMismatch))','assert_eq(multiply(one,zero),Err(DimensionMismatch))','}']
out='\n\n'.join(lines)+'\n';test=ROOT/'src/polynomial/unit_fraction_20261117_wbtest.mbt';data=ROOT/'docs/research/late-poly-unit-20261117-oracle-cases.json'
p=argparse.ArgumentParser();p.add_argument('--check',action='store_true');args=p.parse_args()
def tokens(s):return re.sub(r',(?=[\]\)}])','',''.join(s.split())).replace(';','')
if args.check:
 assert tokens(test.read_text())==tokens(out)
 assert json.loads(data.read_text())==json.loads(json.dumps(specs))
else:test.write_text(out);data.write_text(json.dumps(specs,indent=2)+'\n')
print(f'{len(cases)} independent unit/full-product fixtures '+('checked' if args.check else 'generated'))
