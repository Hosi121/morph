#!/usr/bin/env python3
"""Independent symbolic permutation full-Collins/product projection fixtures."""
from fractions import Fraction as F
from pathlib import Path
import argparse,json,re
import sympy as sp
from generate_elimination import mbpoly,rat,chain
from generate_elimination_principal import psc,fraction_gcd_degree,degree

ROOT=Path(__file__).resolve().parent.parent
OUTPUT=ROOT/'src/projection/oracle_wbtest.mbt'
ARTIFACT=ROOT/'.tools/projection-20261116/oracle.json'


def coeffs(p,y):
 p=sp.expand(p);d=0 if p==0 else sp.Poly(p,y).degree()
 return [p.coeff(y,j) for j in range(d,-1,-1)]


def principals(f,g,y,terminal_one=False):
 fc,gc=coeffs(f,y),coeffs(g,y)
 values=[sp.expand(psc(fc,gc,k)) for k in range(min(len(fc),len(gc)))]
 if terminal_one:values[-1]=sp.Integer(1)
 return values


def reducta(f,y):
 fc=coeffs(f,y);d=len(fc)-1
 return [sp.expand(sum(fc[i]*y**(d-i) for i in range(j,len(fc)))) for j,c in enumerate(fc) if c!=0]


def families():
 x,y=sp.symbols('x y')
 return [([],1),([sp.Integer(0)],1),([x,y+1],1),([y*y-x,y-1],1),
         ([(y-x)**2,y-x],1),([(x-1)*(y*y+1),(x+1)*(y-2)],1),
         ([sp.Rational(2,3),(y*y+x)/5,sp.Integer(0)],1),([y*y+x*y],1),
         ([(x*x-2)*y+x,y*y+1],1),([x*x-y,x-1],0),
         ([(x+y)**2,y*y-x*x],1),([y+x,y+x],1),
         ([x-2,x*x+1],1),([y**3+x*y+1,y-x],1)]


def generate():
 x,y=sp.symbols('x y');gens=[x,y];lines=['// Independent full Collins and product projection, direct permutation determinants.'];records=[]
 for i,(atoms,selected) in enumerate(families()):
  top=gens[selected];base=gens[1-selected];atoms=[sp.expand(p) for p in atoms]
  blocks=[reducta(p,top) for p in atoms]
  fullcoeff=[c for p in atoms for c in coeffs(p,top)]
  fullpsc=[]
  for j,block in enumerate(blocks):
   for p in block:fullpsc+=principals(p,sp.diff(p,top),top,True)
   for other in blocks[j+1:]:
    for p in block:
     for q in other:fullpsc+=principals(p,q,top,True)
  product=sp.prod(p for p in atoms if p!=0)
  product=sp.expand(product)
  productcoeff=coeffs(product,top);productpsc=principals(product,sp.diff(product,top),top)
  for mode,cc,pp,prod in [('CollinsProjection',fullcoeff,fullpsc,None),('ProductProjection',productcoeff,productpsc,product)]:
   encode=lambda ps:'@oracle.chain(['+', '.join(mbpoly(p,[base]) for p in ps)+'])'
   inputs='@oracle.chain(['+', '.join(mbpoly(p,gens) for p in atoms)+'])'
   product_arg='None' if prod is None else 'Some('+mbpoly(prod,gens)+')'
   samples=[];sample_records=[]
   if prod is not None:
    fc=coeffs(prod,top);gc=coeffs(sp.diff(prod,top),top)
    for point in map(F,[-2,-1,0,1,2]):
     specialized=lambda cs:[F(sp.expand(c).subs(base,sp.Rational(point.numerator,point.denominator))) for c in cs]
     ff,gg=specialized(fc),specialized(gc)
     expected=[psc(ff,gg,k) for k in range(min(len(ff),len(gg)))]
     assert expected==[F(v.subs(base,sp.Rational(point.numerator,point.denominator))) for v in pp]
     valid=len(ff)>1 and degree(ff)==len(ff)-1 and degree(gg)==len(gg)-1
     gcd=fraction_gcd_degree(ff,gg)
     if valid:assert next(k for k,v in enumerate(expected) if v)==gcd
     bound=f'Some(@oracle.nat({gcd}))' if valid else 'None'
     samples.append('('+rat(point)+', '+chain(expected)+', '+bound+')')
     sample_records.append(dict(point=str(point),principal=list(map(str,expected)),actual_degree=degree(ff),gcd_degree=gcd,eligible=valid))
   lines+=['','///|',f'test "projection independent {mode} family {i}" {{',
           f'  projection_fixture({mode}, {inputs}, {selected}, {encode(cc)}, {encode(pp)}, {product_arg}, ['+', '.join(samples)+'])','}']
   records.append(dict(family=i,mode=mode,selected=selected,atoms=list(map(str,atoms)),coefficients=list(map(str,cc)),principal=list(map(str,pp)),product=None if prod is None else str(prod),samples=sample_records))
 return '\n'.join(lines)+'\n',records


def tokens(source):
 source=re.sub(r',\s*([\]\)])',r'\1',source)
 return re.findall(r'"(?:\\.|[^"\\])*"|\S',source)


def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--check',action='store_true');args=parser.parse_args()
 source,data=generate()
 if args.check:assert tokens(OUTPUT.read_text())==tokens(source),'projection fixture drift'
 else:OUTPUT.write_text(source)
 ARTIFACT.parent.mkdir(parents=True,exist_ok=True);ARTIFACT.write_text(json.dumps(data,indent=2)+'\n')
 print(f"{'Checked' if args.check else 'Wrote'} {len(data)} independent projection plans and {sum(len(case['samples']) for case in data)} specialization checks.")


if __name__=='__main__':main()
