#!/usr/bin/env python3
"""Fraction permutation/small and independent Gaussian/large determinant oracle."""
from fractions import Fraction as F
from itertools import permutations,product
from pathlib import Path
import argparse,json,random,re,math

ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'src/bareiss/oracle_wbtest.mbt';BENCH=ROOT/'src/bareiss/cohort_bench_wbtest.mbt'
ART=ROOT/'.tools/bareiss-20261116/oracle.json'


def perm(a):
 n=len(a);out=F(0)
 for p in permutations(range(n)):
  value=F((-1)**sum(p[i]>p[j] for i in range(n) for j in range(i+1,n)))
  for i,j in enumerate(p):value*=a[i][j]
  out+=value
 return out


def gaussian(a):
 a=[list(map(F,row)) for row in a];out=F(1);n=len(a)
 for k in range(n):
  pivot=next((i for i in range(k,n) if a[i][k]),None)
  if pivot is None:return F(0)
  if pivot!=k:a[k],a[pivot]=a[pivot],a[k];out=-out
  c=a[k][k];out*=c
  for i in range(k+1,n):
   q=a[i][k]/c
   for j in range(k+1,n):a[i][j]-=q*a[k][j]
 return out


def rat(q):
 q=F(q);return f'bareiss_rat({str(q<0).lower()}, "{abs(q.numerator):x}", "{q.denominator:x}")'


def matrix(a):return 'bareiss_matrix(['+', '.join('['+', '.join(map(rat,row))+']' for row in a)+'])'


def data():
 rng=random.Random(0xBAE155)
 cohorts={name:[] for name in ['small','integer6','integer8','rational6','rational8','singular8','pivot8','earlyzero8']}
 cohorts['small']=[[[F(2),F(3)],[F(5),F(7)]],[[F(1),F(1),F(0)],[F(1),F(1),F(1)],[F(0),F(1),F(1)]]]
 for n in [6,8]:
  for rational in [False,True]:
   name=('rational' if rational else 'integer')+str(n)
   while len(cohorts[name])<3:
    a=[[F(rng.randrange(-7,8),rng.choice([2,3,5,7]) if rational else 1) for _ in range(n)] for _ in range(n)]
    if gaussian(a):cohorts[name].append(a)
 for i in range(3):
  a=[list(row) for row in cohorts['integer8'][i]];a[-1]=list(a[0]);cohorts['singular8'].append(a)
  a=[list(row) for row in cohorts['integer8'][i]];a[0][0]=F(0);cohorts['pivot8'].append(a)
  a=[list(row) for row in cohorts['rational8'][i]]
  for row in a:row[0]=F(0)
  cohorts['earlyzero8'].append(a)
 cases=[[],[[F(0)]],[[F(-7,13)]]]
 cases+=[[[F(v[0]),F(v[1])],[F(v[2]),F(v[3])]] for v in product([-1,0,1],repeat=4)]
 for n in [3,4,5]:
  for _ in range(8):cases.append([[F(rng.randrange(-5,6),rng.choice([1,3,7])) for _ in range(n)] for _ in range(n)])
 cases+=[a for group in cohorts.values() for a in group]
 # A row cycle requires two adjacent interchanges at the first pivot.
 cases.append([[F(0),F(1),F(0)],[F(0),F(0),F(1)],[F(1),F(0),F(0)]])
 return cohorts,cases


def generate():
 cohorts,cases=data();lines=['// Independent Fraction permutation/Gaussian determinant oracle.'];records=[]
 for i,a in enumerate(cases):
  value=gaussian(a)
  if len(a)<=5:assert value==perm(a)
  scales=[math.lcm(*(q.denominator for q in row)) for row in a]
  lines+=['','///|',f'test "Bareiss independent Fraction determinant {i}" {{',f'  bareiss_fixture({matrix(a)}, {rat(value)}, '+str(all(q.denominator==1 for row in a for q in row)).lower()+')','}']
  records.append(dict(matrix=[[str(q) for q in row] for row in a],determinant=str(value),oracle='permutation+Gaussian' if len(a)<=5 else 'Fraction Gaussian',row_lcm=scales))
 rng=random.Random(0x128256)
 for n,bits,rational in [(4,128,False),(4,256,False),(6,128,False),(6,256,False),(4,128,True),(6,256,True)]:
  common=(1<<(bits-1))-19
  a=[[F((rng.getrandbits(bits-1)+(1<<(bits-1)))*rng.choice([-1,1]),common*rng.choice([3,5,7]) if rational else 1) for _ in range(n)] for _ in range(n)]
  expected=gaussian(a)
  if n==4:assert expected==perm(a)
  lines+=['','///|',f'test "Bareiss wide {n}x{n} {bits}bit '+('rational' if rational else 'integer')+'" {',f'  bareiss_fixture({matrix(a)}, {rat(expected)}, '+str(not rational).lower()+')','}']
  records.append(dict(matrix=[[str(q) for q in row] for row in a],determinant=str(expected),oracle='wide Fraction Gaussian'+(' + permutation' if n==4 else ''),coefficient_bits=bits,rational=rational))
 bench=['// Frozen same-artifact reference and Bareiss cohorts.','///|','fn bareiss_cohort(kind : Int32) -> Array[@matrix.Matrix[@exact.Rational]] {','  match kind {']
 for i,(name,matrices) in enumerate(cohorts.items()):bench.append(f'    {i} => ['+', '.join(matrix(a) for a in matrices)+']')
 bench+=['    _ => []','  }','}']
 for i,name in enumerate(cohorts):
  for candidate in [False,True]:
   label=('Bareiss' if candidate else 'reference')+'_'+name
   call='determinant(matrix)' if candidate else 'bareiss_frozen_reference(matrix)'
   bench+=['','///|',f'test "{label}" (b : @bench.T) {{',f'  let matrices = bareiss_cohort({i})',f'  b.bench(name="{label}", count=5, fn() {{ for matrix in matrices {{ b.keep({call}) }} }})','}']
 return '\n'.join(lines)+'\n','\n'.join(bench)+'\n',dict(cases=records,cohorts={name:len(xs) for name,xs in cohorts.items()})


def tokens(source):
 source=re.sub(r',\s*([\]\)])',r'\1',source)
 return re.findall(r'"(?:\\.|[^"\\])*"|\S',source)


def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--check',action='store_true');args=parser.parse_args()
 source,bench,data=generate()
 if args.check:
  assert tokens(OUT.read_text())==tokens(source),'Bareiss fixture drift'
  assert tokens(BENCH.read_text())==tokens(bench),'Bareiss cohort drift'
 else:OUT.write_text(source);BENCH.write_text(bench)
 ART.parent.mkdir(parents=True,exist_ok=True);ART.write_text(json.dumps(data,indent=2)+'\n')
 print(f"{'Checked' if args.check else 'Wrote'} {len(data['cases'])} independent determinants and {len(data['cohorts'])} paired cohorts.")


if __name__=='__main__':main()
