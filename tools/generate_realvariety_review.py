#!/usr/bin/env python3
"""Independent Fraction-only rational-root shape and norm review fixtures.

No SymPy, resultant, determinant, Groebner basis, or production executable is
used. Norms are products (z-h(r))^multiplicity at known rational parameter roots.
The original input rows are related to shape rows by invertible triangular
rational-polynomial row operations, so their ideal equality is constructive.
"""
from __future__ import annotations
from fractions import Fraction as F
from pathlib import Path
import argparse
import json
import re

ROOT=Path(__file__).resolve().parent.parent
OUTPUT=ROOT/'src/realvariety/fraction_review_fixtures_wbtest.mbt'
ARTIFACT=ROOT/'.tools/realvariety-review-20261116/fraction-oracle.json'


def trim(p):
 p=list(p)
 while p and not p[-1]: p.pop()
 return tuple(p)


def add(a,b):
 return trim([(a[i] if i<len(a) else F(0))+(b[i] if i<len(b) else F(0)) for i in range(max(len(a),len(b)))])


def multiply(a,b):
 if not a or not b:return ()
 out=[F(0)]*(len(a)+len(b)-1)
 for i,x in enumerate(a):
  for j,y in enumerate(b):out[i+j]+=x*y
 return trim(out)


def remainder(a,b):
 out=list(trim(a))
 while len(out)>=len(b) and out:
  shift=len(out)-len(b)
  scalar=out[-1]/b[-1]
  for j,c in enumerate(b):out[shift+j]-=scalar*c
  out=list(trim(out))
 return tuple(out)


def evaluate(p,r):
 out=F(0)
 for c in reversed(p):out=out*r+c
 return out


def norm(roots,multiplicities,h):
 out=(F(1),)
 for r,m in zip(roots,multiplicities):
  for _ in range(m):out=multiply(out,(-evaluate(h,r),F(1)))
 return out


def padd(a,b):
 out=dict(a)
 for mon,c in b.items():out[mon]=out.get(mon,F(0))+c
 return {mon:c for mon,c in out.items() if c}


def scale(p,c):return {mon:value*c for mon,value in p.items() if value*c}


def pmul(a,b):
 out={}
 for ma,ca in a.items():
  for mb,cb in b.items():
   mon=tuple(x+y for x,y in zip(ma,mb))
   out[mon]=out.get(mon,F(0))+ca*cb
 return {mon:c for mon,c in out.items() if c}


def embed(p,n):return {(0,)*(n-1)+(i,):c for i,c in enumerate(p) if c}


def pvalue(p,point):
 out=F(0)
 for mon,c in p.items():
  for x,degree in zip(point,mon):c*=x**degree
  out+=c
 return out


def rat(q):
 q=F(q)
 return f'rv_review_rat({str(q<0).lower()}, "{abs(q.numerator):x}", "{q.denominator:x}")'


def uni(p):return 'rv_review_u(['+', '.join(rat(q) for q in p)+'])'


def poly(p,n):
 return f'rv_review_p({n}, ['+', '.join('('+rat(c)+', '+str(list(mon))+')' for mon,c in sorted(p.items(),reverse=True))+'])'


def cases():
 return [
  ('three_fractions',[F(-2,3),F(1,5),F(7,4)],[1,1,1],[(F(1,7),F(-3,5),F(2,3))]),
  ('close_repeated_zero',[F(0),F(1,31),F(2,31)],[2,1,1],[(F(0),F(0),F(1))]),
  ('collision_and_reverse',[F(-1),F(0),F(1)],[2,1,1],[(F(0),F(0),F(1)),(F(2),F(-1))]),
  ('constant_and_zero',[F(-3,7),F(3,7)],[1,1],[(F(-5,13),),()]),
  ('single_repeated_parameter',[F(2,17)],[4],[(F(1,11),F(0),F(0),F(0),F(0),F(1))]),
  ('high_odd_power',[F(-1,2),F(1,2)],[2,2],[(F(1,5),F(0),F(0),F(-2,3),F(0),F(0),F(0),F(0),F(0),F(1))]),
  ('three_variable_mixed_rows',[F(-5,4),F(2,9),F(5,3)],[1,1,1],[(F(1,2),F(1)),(F(0),F(-1),F(0),F(1))]),
 ]


def generate():
 lines=['// Independent Fraction-only shape/norm oracle from tools/generate_realvariety_review.py.']
 records=[]
 for index,(name,roots,multiplicities,raw_h) in enumerate(cases()):
  n=len(raw_h)+1
  g=(F(1),)
  for r,m in zip(roots,multiplicities):
   for _ in range(m):g=multiply(g,(-r,F(1)))
  h=[remainder(p,g) for p in raw_h]+[(F(0),F(1))]
  base=[]
  for i,p in enumerate(raw_h):
   mon=tuple(int(j==i) for j in range(n))
   base.append(padd({mon:F(1)},scale(embed(p,n),F(-1))))
  g_row=embed(g,n)
  inputs=[]
  # Upper triangular row map with nonzero constant diagonal and polynomial
  # off-diagonal entries. Its inverse is again rational-polynomial triangular.
  for i,row in enumerate(base):
   transformed=scale(row,F(-(2+i),7+i))
   transformed=padd(transformed,pmul(embed((F(1,3),F(-1,5)),n),g_row))
   if i+1<len(base):transformed=padd(transformed,pmul(embed((F(1,2),F(1)),n),base[i+1]))
   inputs.append(transformed)
  inputs.append(scale(g_row,F(-3,11)))
  characteristic=[norm(roots,multiplicities,p) for p in h]
  values=[[evaluate(p,r) for p in h] for r in roots]
  for point in values:assert all(pvalue(row,point)==0 for row in inputs)
  for p,c in zip(h,characteristic):
   assert len(c)==len(g) and c[-1]==1
   for r in roots:assert evaluate(c,evaluate(p,r))==0
  lines+=['','///|',f'test "independent realvariety review fixture {index} {name}" {{','  rv_review_fixture(',
          f'    {n},','    ['+', '.join(poly(row,n) for row in inputs)+'],','    '+uni(g)+',',
          '    ['+', '.join(uni(p) for p in h)+'],','    ['+', '.join(rat(r) for r in roots)+'],',
          '    ['+', '.join(uni(c) for c in characteristic)+'],',
          '    ['+', '.join('['+', '.join(rat(value) for value in point)+']' for point in values)+'],','  )','}']
  records.append(dict(index=index,name=name,variables=n,roots=list(map(str,roots)),multiplicities=multiplicities,
                      degree=len(g)-1,eliminant=list(map(str,g)),coordinates=[list(map(str,p)) for p in h],
                      characteristic=[list(map(str,p)) for p in characteristic],values=[list(map(str,p)) for p in values]))
 return '\n'.join(lines)+'\n',records


def tokens(source):
 source=re.sub(r',\s*([\]\)])',r'\1',source)
 return re.findall(r'"(?:\\.|[^"\\])*"|\S',source)


def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--check',action='store_true');args=parser.parse_args()
 source,data=generate()
 if args.check:assert tokens(OUTPUT.read_text())==tokens(source),'realvariety review fixture drift'
 else:OUTPUT.write_text(source)
 ARTIFACT.parent.mkdir(parents=True,exist_ok=True)
 ARTIFACT.write_text(json.dumps(dict(oracle='Fraction factored rational roots; norm product with multiplicities; no CAS/determinant',cases=data),indent=2)+'\n')
 print(f"{'Checked' if args.check else 'Wrote'} {len(data)} Fraction shape systems and {sum(len(x['roots'])*x['variables'] for x in data)} point-coordinate checks.")


if __name__=='__main__':main()
