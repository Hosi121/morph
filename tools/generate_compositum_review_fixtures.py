#!/usr/bin/env python3
"""Independent review oracle: Fraction arithmetic in Q(sqrt(d)); closed-form quartics.
Does not use worker fixtures, primitive_element, to_number_field or minimal_polynomial.
"""
from pathlib import Path
from fractions import Fraction as F
from functools import cmp_to_key
from argparse import ArgumentParser
import json,subprocess
import sympy as sp
ROOT=Path(__file__).resolve().parents[1]
t=sp.symbols('t')
def sgn(n):return (n>0)-(n<0)
def field_sign(p,d):
 a,b=p
 if not b:return sgn(a)
 if not a:return sgn(b)
 if sgn(a)==sgn(b):return sgn(a)
 return sgn(a)*sgn(a*a-d*b*b)
def plus(p,q):return (p[0]+q[0],p[1]+q[1])
def times(s,p):return (s*p[0],s*p[1])
def minus(p,q):return plus(p,times(-1,q))
def minimal(p,d):
 a,b=p
 return [-a,F(1)] if not b else [a*a-d*b*b,-2*a,F(1)]
def roots(p,extra):
 a,b=p;out=[(a,b)] if not b else [(a,abs(b)),(a,-abs(b))]
 if extra is not None:out.append((F(extra),F(0)))
 return out

def interval(p,d):
 a,b=p
 if not b:return (a-1,a)
 # Certified integer bracket via direct quadratic-field sign, no approximations.
 k=-32
 while field_sign(minus(p,(F(k+1),F(0))),d)>0:k+=1
 assert field_sign(minus(p,(F(k),F(0))),d)>0
 assert field_sign(minus((F(k+1),F(0)),p),d)>=0
 return (F(k),F(k+1))
def mulpoly(p,q):
 out=[F(0)]*(len(p)+len(q)-1)
 for i,a in enumerate(p):
  for j,b in enumerate(q):out[i+j]+=a*b
 return out
def data(p):return [[c.numerator,c.denominator] for c in p]
def arr(p):return '['+', '.join(f'({c.numerator}, {c.denominator})' for c in p)+']'
def pair(p):return '('+', '.join(map(str,p))+')'
def build():
 records=[]
 specs=[(2,(2,1),(-1,1),None,None),(2,(1,-1),(3,1),None,None),(3,(F(1,2),F(1,2)),(2,F(-1,3)),None,None),(2,(-2,2),(1,-1),None,None),(2,(3,0),(-1,1),None,None),(3,(0,-1),(0,0),None,None),(2,(0,0),(F(-7,3),0),None,None),(2,(F(2,5),0),(F(1,2),0),None,None),(2,(0,1),(0,-1),7,None),(2,(0,1),(2,1),None,-5)]
 for d,left,right,extra_l,extra_r in specs:
  left=tuple(map(F,left));right=tuple(map(F,right))
  lroots=roots(left,extra_l);rroots=roots(right,extra_r)
  cart=[(x,y) for x in lroots for y in rroots]
  for seed in range(6):
   images=[plus(x,times(seed,y)) for x,y in cart]
   if len(set(images))==len(cart):break
  else:raise AssertionError('seed')
  cart.sort(key=cmp_to_key(lambda p,q:field_sign(minus(plus(p[0],times(seed,p[1])),plus(q[0],times(seed,q[1]))),d)))
  theta=plus(left,times(seed,right));ta,tb=theta
  selected=cart.index((left,right))
  m=minimal(theta,d)
  if tb:
   hx=[left[0]-left[1]*ta/tb,left[1]/tb];hy=[right[0]-right[1]*ta/tb,right[1]/tb]
  else:hx=[left[0]];hy=[right[0]]
  def trim(p):
   while len(p)>1 and not p[-1]:p.pop()
   return p
  hx,hy=trim(hx),trim(hy)
  lp=minimal(left,d);rp=minimal(right,d)
  if extra_l is not None:lp=mulpoly(lp,[-F(extra_l),F(1)])
  if extra_r is not None:rp=mulpoly(rp,[-F(extra_r),F(1)])
  orders=[(field_sign(minus(x,left),d),field_sign(minus(y,right),d)) for x,y in cart]
  # Verify maps by direct quadratic-field affine substitution.
  assert plus((hx[0],F(0)),times(hx[1],theta) if len(hx)>1 else (F(0),F(0)))==left
  assert plus((hy[0],F(0)),times(hy[1],theta) if len(hy)>1 else (F(0),F(0)))==right
  records.append(dict(kind='Fraction Qsqrt direct affine arithmetic',d=d,left=data(left),right=data(right),left_definition=data(lp),right_definition=data(rp),left_interval=data(interval(left,d)),right_interval=data(interval(right,d)),seed=seed,selected=selected,orders=orders,minimal=data(m),hx=data(hx),hy=data(hy)))
 # Closed-form independent biquadratic identities, without primitive element routines.
 for d,e,la,ls,ra,rs in [(3,7,0,1,0,1),(3,7,0,-1,0,1),(2,5,1,1,-2,-1)]:
  alpha=la+ls*sp.sqrt(d);beta=ra+rs*sp.sqrt(e);seed=1;u=t-la-ra
  quartic=sp.Poly(sp.expand(u**4-2*(d+e)*u*u+(d-e)**2),t)
  hx=sp.Poly(sp.expand(la+((3*d+e)*u-u**3)/(2*(d-e))),t)
  hy=sp.Poly(sp.expand(ra+(u**3-(d+3*e)*u)/(2*(d-e))),t)
  theta=alpha+beta
  assert sp.simplify(quartic.as_expr().subs(t,theta))==0
  assert sp.simplify(hx.as_expr().subs(t,theta)-alpha)==0
  assert sp.simplify(hy.as_expr().subs(t,theta)-beta)==0
  cart=[(la+i*sp.sqrt(d),ra+j*sp.sqrt(e)) for i in [-1,1] for j in [-1,1]]
  cart.sort(key=cmp_to_key(lambda p,q:int(sp.sign(sp.simplify(sum(p)-sum(q))))))
  orders=[(int(sp.sign(sp.simplify(x-alpha))),int(sp.sign(sp.simplify(y-beta)))) for x,y in cart]
  def cs(p):return [F(c) for c in reversed(p.all_coeffs())]
  records.append(dict(kind='closed-form biquadratic elimination',d=d,left_expression=str(alpha),right_expression=str(beta),left_definition=data([F(la*la-d),F(-2*la),F(1)]),right_definition=data([F(ra*ra-e),F(-2*ra),F(1)]),left_interval=data(interval((F(la),F(ls)),d)),right_interval=data(interval((F(ra),F(rs)),e)),seed=seed,selected=cart.index((alpha,beta)),orders=orders,minimal=data(cs(quartic)),hx=data(cs(hx)),hy=data(cs(hy))))
 # Dependent quartic/quadratic input: Cartesian degree eight drops to four.
 # Derive relation and maps by direct arithmetic in basis 1,sqrt2,sqrt3,sqrt6.
 def vmul(p,q):
  out=[F(0)]*4
  for i,x in enumerate(p):
   for j,z in enumerate(q):out[i^j]+=x*z*(2 if i&j&1 else 1)*(3 if i&j&2 else 1)
  return out
 def solve(columns,rhs):
  rows=[[columns[j][i] for j in range(4)]+[rhs[i]] for i in range(4)]
  for j in range(4):
   k=next(i for i in range(j,4) if rows[i][j]);rows[j],rows[k]=rows[k],rows[j]
   scale=rows[j][j];rows[j]=[v/scale for v in rows[j]]
   for i in range(4):
    if i!=j:
     scale=rows[i][j];rows[i]=[x-scale*z for x,z in zip(rows[i],rows[j])]
  return [row[-1] for row in rows]
 for bs in [1,-1]:
  av=list(map(F,[0,1,1,0]));bv=list(map(F,[0,0,0,bs]));theta=[x+z for x,z in zip(av,bv)]
  powers=[list(map(F,[1,0,0,0]))]
  for _ in range(4):powers.append(vmul(powers[-1],theta))
  relation=solve(powers[:4],powers[4]);m=[-c for c in relation]+[F(1)]
  hx=solve(powers[:4],av);hy=solve(powers[:4],bv)
  while len(hx)>1 and not hx[-1]:hx.pop()
  while len(hy)>1 and not hy[-1]:hy.pop()
  alpha=sp.sqrt(2)+sp.sqrt(3);beta=bs*sp.sqrt(6)
  cart=[(i*sp.sqrt(2)+j*sp.sqrt(3),k*sp.sqrt(6)) for i in [-1,1] for j in [-1,1] for k in [-1,1]]
  cart.sort(key=cmp_to_key(lambda p,q:int(sp.sign(sp.simplify(sum(p)-sum(q))))))
  orders=[(int(sp.sign(sp.simplify(x-alpha))),int(sp.sign(sp.simplify(z-beta)))) for x,z in cart]
  expression=sum(sp.Rational(c.numerator,c.denominator)*t**i for i,c in enumerate(m))
  assert sp.simplify(expression.subs(t,alpha+beta))==0
  records.append(dict(kind='Fraction biquadratic multiplication and Gaussian dependence; Cartesian degree8 to field degree4',d=6,left_expression=str(alpha),right_expression=str(beta),left_definition=data(list(map(F,[1,0,-10,0,1]))),right_definition=data(list(map(F,[-6,0,1]))),left_interval=data([F(3),F(4)]),right_interval=data([F(2),F(3)] if bs==1 else [F(-3),F(-2)]),seed=1,selected=cart.index((alpha,beta)),orders=orders,minimal=data(m),hx=data(hx),hy=data(hy)))
 lines=['// Generated by independent Fraction/closed-form compositum review oracle.','']
 for i,r in enumerate(records):
  lines+=['///|',f'test "independent compositum review direct oracle {i}" {{',f'  review_fixture({arr([F(*c) for c in r["left_definition"]])}, {pair(r["left_interval"][0])}, {pair(r["left_interval"][1])},',f'    {arr([F(*c) for c in r["right_definition"]])}, {pair(r["right_interval"][0])}, {pair(r["right_interval"][1])},',f'    {r["seed"]}, {r["selected"]}, ['+', '.join(pair(o) for o in r['orders'])+'],',f'    {arr([F(*c) for c in r["minimal"]])}, {arr([F(*c) for c in r["hx"]])}, {arr([F(*c) for c in r["hy"]])})','}','']
 output=subprocess.run([str(ROOT/'.tools/moon/bin/moonfmt'),'-'],input='\n'.join(lines),text=True,capture_output=True,check=True).stdout
 stats=dict(cases=len(records),cartesian_comparisons=sum(len(r['orders']) for r in records),dependent=12,biquadratic=3,cartesian_degree8_to_field4=2)
 return {ROOT/'src/compositum/direct_review_wbtest.mbt':output,ROOT/'docs/research/compositum-review-20261116-fixtures.json':json.dumps(dict(sympy=sp.__version__,oracle='Fraction Qsqrt direct affine arithmetic; closed-form quartic and cubic residue identities; no primitive_element/to_number_field/minimal_polynomial',statistics=stats,cases=records),indent=2)+'\n'},stats

def main():
 p=ArgumentParser(description=__doc__);p.add_argument('--check',action='store_true');args=p.parse_args();files,stats=build()
 for path,text in files.items():
  if args.check:
   if not path.exists() or path.read_text()!=text:raise SystemExit(f'Stale: {path}')
  else:path.write_text(text)
 print(json.dumps(stats,sort_keys=True))
if __name__=='__main__':main()
