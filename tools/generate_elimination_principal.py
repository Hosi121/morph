#!/usr/bin/env python3
"""Independent truncated-Sylvester permutation PSCs and exact gcd oracles."""
from fractions import Fraction as F
from pathlib import Path
import argparse
import json
import re
import sympy as sp
from generate_elimination import cases,determinant,chain,rat,projection_cases,mbpoly

ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'src/elimination/principal_oracle_wbtest.mbt'
ART=ROOT/'.tools/elimination-principal-20261116/oracle.json'


def psc(f,g,k):
 n,m=len(f)-1,len(g)-1;size=n+m-2*k;width=size+k
 rows=[[F(0)]*i+list(f)+[F(0)]*(width-i-len(f)) for i in range(m-k)]+\
      [[F(0)]*i+list(g)+[F(0)]*(width-i-len(g)) for i in range(n-k)]
 return determinant([row[:size] for row in rows])


def degree(f):
 for i,c in enumerate(f):
  if c:return len(f)-i-1
 return -1


def fraction_gcd_degree(f,g):
 def trim(a):
  a=list(a)
  while a and not a[-1]:a.pop()
  return a
 a,b=trim(f[::-1]),trim(g[::-1])
 while b:
  r=list(a)
  while r and len(r)>=len(b):
   gap=len(r)-len(b);q=r[-1]/b[-1]
   for i,c in enumerate(b):r[i+gap]-=q*c
   r=trim(r)
  a,b=b,r
 return len(a)-1


def generate():
 records=[];lines=['// Independent Fraction permutations and Euclidean/SymPy gcd oracles.']
 pairs=cases()+[([F(1),F(0),F(-3),F(2)],[F(1),F(2),F(-3)]),
                ([F(2),F(4),F(2)],[F(6),F(12),F(6)]),
                ([F(0),F(0),F(2)],[F(0),F(0),F(3)]),
                ([F(1),F(0),F(1)],[F(0),F(0)])]
 y=sp.Symbol('y')
 for i,(f,g) in enumerate(pairs):
  values=[psc(f,g,k) for k in range(min(len(f),len(g)))]
  preserved=degree(f)==len(f)-1 and degree(g)==len(g)-1
  gcd=fraction_gcd_degree(f,g)
  sf=sum(sp.Rational(c.numerator,c.denominator)*y**j for j,c in enumerate(f[::-1]))
  sg=sum(sp.Rational(c.numerator,c.denominator)*y**j for j,c in enumerate(g[::-1]))
  sym_gcd=sp.Poly(sp.gcd(sf,sg),y).degree()
  assert gcd==sym_gcd or (gcd==-1 and sym_gcd is sp.S.NegativeInfinity)
  if preserved:assert next(k for k,c in enumerate(values) if c)==gcd
  want=f'Some(@oracle.nat({gcd}))' if preserved else 'None'
  lines+=['','///|',f'test "principal independent Fraction matrix and gcd {i}" {{',
          f'  principal_fixture({chain(f)}, {chain(g)}, {chain(values)}, {want})','}']
  records.append(dict(left=list(map(str,f)),right=list(map(str,g)),principal=list(map(str,values)),degrees_preserved=preserved,gcd_degree=gcd))
 projections=[]
 for i,(gens,selected,f,g,n,m) in enumerate(projection_cases()):
  y=gens[selected];others=[v for j,v in enumerate(gens) if j!=selected]
  fc=[sp.expand(f).coeff(y,j) for j in range(n,-1,-1)]
  gc=[sp.expand(g).coeff(y,j) for j in range(m,-1,-1)]
  values=[sp.expand(psc(fc,gc,k)) for k in range(min(n,m)+1)]
  encode=lambda ps:'@oracle.chain(['+', '.join(mbpoly(p,others) for p in ps)+'])'
  lines+=['','///|',f'test "principal independent QQ coefficient and PSC query {i}" {{',
          f'  principal_variable_fixture({mbpoly(f,gens)}, {mbpoly(g,gens)}, {selected}, {n}, {m}, {encode(fc)}, {encode(values)})','}']
  projections.append(dict(left=str(f),right=str(g),selected=selected,degrees=[n,m],coefficients=list(map(str,fc)),principal=list(map(str,values))))
 return '\n'.join(lines)+'\n',dict(pairs=records,projections=projections,sympy=sp.__version__)


def tokens(source):
 source=re.sub(r',\s*([\]\)])',r'\1',source)
 return re.findall(r'"(?:\\.|[^"\\])*"|\S',source)


def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--check',action='store_true');args=parser.parse_args()
 source,data=generate()
 if args.check:assert tokens(OUT.read_text())==tokens(source),'principal fixture drift'
 else:OUT.write_text(source)
 ART.parent.mkdir(parents=True,exist_ok=True);ART.write_text(json.dumps(data,indent=2)+'\n')
 print(f"{'Checked' if args.check else 'Wrote'} {len(data['pairs'])} Fraction PSC/gcd cases and {len(data['projections'])} QQ coefficient PSC queries.")


if __name__=='__main__':main()
