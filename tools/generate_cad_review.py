#!/usr/bin/env python3
"""Independent closed-form CAD/QE fixtures and old-CAD2 semantic comparison runner."""
from pathlib import Path
from fractions import Fraction as F
import argparse,json,re
import sympy as sp

ROOT=Path(__file__).resolve().parent.parent
CAD=ROOT/'src/cad/independent_review_oracle_wbtest.mbt'
FO=ROOT/'src/realclosed/independent_review_oracle_wbtest.mbt'
ART=ROOT/'.tools/cad-review-20261116'
x,y,z,w=sp.symbols('x y z w')


def chain(xs):return '@oracle.chain(['+', '.join(xs)+'])'
def rat(q):
 q=F(q);return f'@oracle.rational({q.numerator}, {q.denominator})'
def poly(expr,gens):
 terms=[] if sp.expand(expr)==0 else sp.Poly(sp.expand(expr),*gens).terms()
 return 'review_poly('+str(len(gens))+', ['+', '.join('('+str(F(c).numerator)+', '+str(F(c).denominator)+', '+str(list(e))+')' for e,c in terms)+'])'
def atom(expr,relation,gens):return '@qf.Atom('+poly(expr,gens)+', @qf.'+relation+')'
def conj(*fs):
 out=fs[-1]
 for f in fs[-2::-1]:out='@qf.Conjunction('+f+', '+out+')'
 return out
def disj(*fs):
 out=fs[-1]
 for f in fs[-2::-1]:out='@qf.Disjunction('+f+', '+out+')'
 return out

def cases():
 g=[x,y];h=y*y-x;g3=[x,y,z];g4=[x,y,z,w]
 return [
 ('inverse',g,1,['Exists'],atom(x*y-1,'EqualZero',g),lambda p:p[0]!=0,'x != 0'),
 ('scaled_square',g,1,['Exists'],atom(x*y*y-1,'EqualZero',g),lambda p:p[0]>0,'x > 0'),
 ('degree_drop_eq',g,1,['Exists'],atom(x*y*y+y+1,'EqualZero',g),lambda p:p[0]<=F(1,4),'x <= 1/4'),
 ('degree_drop_strict',g,1,['Exists'],atom(x*y*y+y+1,'LessZero',g),lambda p:p[0]<F(1,4),'x < 1/4'),
 ('square_forall',g,1,['Forall'],atom((y-x)**2,'AtLeastZero',g),lambda p:True,'true'),
 ('square_strict_forall',g,1,['Forall'],atom((y-x)**2,'GreaterZero',g),lambda p:False,'false'),
 ('punctured_square',g,1,['Exists'],conj(atom(y*y-x,'EqualZero',g),atom(y,'NotZero',g)),lambda p:p[0]>0,'x > 0'),
 ('negative_root_order',g,1,['Exists'],conj(atom(y*y-x,'EqualZero',g),atom(y-x,'LessZero',g)),lambda p:p[0]>0,'x > 0'),
 ('shared_zero_guard',g,1,['Exists'],conj(atom(y*(y-1),'EqualZero',g),atom(y*(y-x),'EqualZero',g),atom(y,'NotZero',g)),lambda p:p[0]==1,'x = 1'),
 ('root_implication',g,1,['Forall'],disj(atom(y*y-x,'NotZero',g),atom(y,'AtLeastZero',g)),lambda p:p[0]<=0,'x <= 0'),
 ('irrational_holes',g,1,['Exists'],atom((x*x-2)*y-1,'EqualZero',g),lambda p:p[0]*p[0]!=2,'x^2 != 2'),
 ('universal_coefficient',g,1,['Forall'],atom((x*x-2)*y*y,'AtLeastZero',g),lambda p:p[0]*p[0]>=2,'x^2 >= 2'),
 ('irrational_nullification_forall',g3,1,['Exists','Forall'],atom((x*x-2)*z+y,'EqualZero',g3),lambda p:p[0]*p[0]==2,'x^2 = 2'),
 ('nonlinear_shared_content',g3,2,['Exists'],conj(atom(h*(z-1),'EqualZero',g3),atom(h*(z+1),'EqualZero',g3)),lambda p:p[1]*p[1]==p[0],'y^2 = x'),
 ('nonlinear_shared_guard',g3,2,['Exists'],conj(atom(h*(z-1),'EqualZero',g3),atom(h*(z+1),'EqualZero',g3),atom(h,'NotZero',g3)),lambda p:False,'false'),
 ('nonlinear_shared_forall',g3,2,['Forall'],disj(atom(h*(z-1),'EqualZero',g3),atom(h*(z+1),'EqualZero',g3)),lambda p:p[1]*p[1]==p[0],'y^2 = x'),
 ('four_variable_degenerate',g4,1,['Exists','Exists','Forall'],atom((x*y-1)*w+z,'EqualZero',g4),lambda p:p[0]!=0,'x != 0'),
 ('four_variable_parabola',g4,2,['Exists','Forall'],atom((x*x-y)*w+z,'EqualZero',g4),lambda p:p[0]*p[0]==p[1],'y = x^2'),
 ('shared_factor_higher_psc',g,1,['Exists'],conj(atom(y*(y-x-1),'EqualZero',g),atom(y*(y-2*x-3),'EqualZero',g),atom(y,'NotZero',g)),lambda p:p[0]==-2,'x = -2; common zero factor alone is insufficient'),
 ]

def points(free):
 if free==1:return [(q,) for q in map(F,[-3,-2,-1,0,1,2,3])]+[(F(1,4),),(F(-1,4),),(F(1,2),),(F(3,2),),(F(-3,2),)]
 return [(F(a,2),F(b,2)) for a in [-4,-2,0,1,2,4] for b in [-2,-1,0,1,2]]

def encoded_points(free,predicate):
 ps=points(free)
 return '['+', '.join('('+str([(q.numerator,q.denominator) for q in p])+', '+str(bool(predicate(p))).lower()+')' for p in ps)+']'

def fo_cases():
 # Replace QF constructors with the corresponding scoped AST constructors.
 def a(expr,rel,gens):return '@logic.Atom('+poly(expr,gens)+', @qf.'+rel+')'
 def exists(f):return '@logic.Formula::Exists('+f+')'
 def forall(f):return '@logic.Formula::Forall('+f+')'
 return [
 ('inverse_universal',1,exists(forall(a((x*y-1)*z,'EqualZero',[x,y,z]))),lambda p:p[0]!=0,'x != 0'),
 ('negated_square',1,'@logic.Negation('+exists(a(y*y-x,'EqualZero',[x,y]))+')',lambda p:p[0]<0,'x < 0'),
 ('nonlinear_sibling_scopes',1,'@logic.Conjunction('+exists(a(y*y-x,'EqualZero',[x,y]))+', @logic.Negation('+exists(a(y*y+x,'EqualZero',[x,y]))+'))',lambda p:p[0]>0,'x > 0'),
 ('inverse_implication',0,forall('@logic.Disjunction('+a(x,'EqualZero',[x])+', '+exists(a(x*y-1,'EqualZero',[x,y]))+')'),lambda p:True,'true'),
 ('constant_forall_impossible',0,exists(forall(a((y*y+1)*x-1,'EqualZero',[x,y]))),lambda p:False,'false'),
 ('negated_universal_inverse',0,'@logic.Negation('+forall(exists(a(x*y-1,'EqualZero',[x,y])))+')',lambda p:True,'true'),
 ]

def runner_source(selected):
 prelude='''import {
  "Hosi121/morph/core",
  "Hosi121/morph/cad" @cad,
  "Hosi121/morph/cad2" @old,
  "Hosi121/morph/realcad" @qf,
  "Hosi121/morph/realformula" @logic,
  "Hosi121/morph/polynomial" @poly,
  "Hosi121/morph/exact",
  "Hosi121/morph/testsupport" @oracle,
}

fn review_poly(n : Int, terms : Array[(Int, Int, Array[Int])]) -> @poly.Polynomial {
  @poly.polynomial(@oracle.nat(n), @oracle.chain(terms.map(fn(t) { @poly.Term::{coefficient:@oracle.rational(t.0,t.1),exponents:@oracle.chain(t.2.map(@oracle.nat))} }))).unwrap()
}
fn budget() -> @old.Budget {
 {primes:@oracle.chain([2,3,5,7,11,13,17,19,23,29,31].map(@oracle.binary)),lifting:@oracle.nat(80),subsets:@oracle.nat(4096),verification:@oracle.nat(8192)}
}
fn compare(formula : @qf.Formula, expected : Array[Bool]) -> Unit raise {
 let old_problem=@old.prepare(formula).unwrap()
 let old=match @old.run(@old.start(old_problem,budget()),@oracle.nat(20000)).unwrap() {Complete(v)=>v; _=>fail("old CAD2 budget")}
 let problem=@cad.prepare(@oracle.nat(2),formula).unwrap()
 let value=match @cad.run(@cad.start(problem),@oracle.nat(50000)).unwrap() {Complete(v)=>v; _=>fail("CAD budget")}
 let qs=[@old.Quantifier::Exists,@old.Quantifier::Forall]
 let ns=[@logic.Quantifier::Exists,@logic.Quantifier::Forall]
 for i in 0..<2 {
  let qe=@cad.eliminate(value,@oracle.nat(1),@oracle.chain([ns[i]])).unwrap()
  let answers=@oracle.array(@old.eliminate_y(old,qs[i]))
  let cells=@oracle.array(@old.certificate(old).base.cells)
  assert_eq(cells.length(),answers.length())
  for j in 0..<cells.length() {
    let coordinate=match cells[j].sample {
      RationalPoint(q)=>q
      AlgebraicPoint(span)=>{
        let candidates=[@oracle.rational(0,1),@oracle.rational(1,4)]
        let found=candidates.filter(fn(q) {
          @exact.rational_compare(q,span.lower)==@core.Greater && @exact.rational_compare(q,span.upper)!=@core.Greater &&
          @poly.evaluate(@qf.root_polynomial(@old.base_problem(old_problem)),@oracle.chain([q]))==Some(@exact.rational_zero())
        })
        assert_eq(found.length(),1)
        found[0]
      }
    }
    assert_eq(@cad.evaluate_formula(@cad.rational_point(@oracle.chain([coordinate])),@cad.quantifier_free(qe)).unwrap(),answers[j])
  }
  for j in 0..<2 {
   let actual=@cad.sentence(value,@oracle.chain([ns[i],ns[j]])).unwrap()
   assert_eq(actual,@old.sentence(old,qs[i],qs[j]))
   assert_eq(actual,expected[i*2+j])
  }
 }
 assert_true(@cad.check_result(problem,value,@cad.certificate(value)))
 assert_true(@old.check(old_problem,@old.certificate(old),@oracle.nat(8192)) is Some(_))
}
fn main raise {
'''
 calls=[]
 for case,wants in selected:
  calls.append('  compare('+case[4]+', '+str(wants).lower()+')')
 return prelude+'\n'.join(calls)+'\n  println("Compared 4 independent bivariate families: all old base-cell quantifications and all 4 closed quantifier pairs.")\n}\n'


def generate():
 lines=['// Independent closed-form oracle, exact Fraction grid; generated by tools/generate_cad_review.py.'];records=[]
 cs=cases()
 for i,(name,gens,free,qs,matrix,pred,closed) in enumerate(cs):
  lines+=['','///|',f'test "independent CAD closed form {i} {name}" {{',
          f'  review_qe_fixture({len(gens)}, {free}, {matrix}, '+chain(['@logic.Quantifier::'+q for q in qs])+', '+encoded_points(free,pred)+')','}']
  records.append(dict(case=i,name=name,arity=len(gens),free=free,quantifiers=qs,closed_form=closed,samples=[dict(point=list(map(str,p)),expected=bool(pred(p))) for p in points(free)]))
 flines=['// Independent scoped first-order closed-form oracle; exact rational output evaluation.'];frecords=[]
 for i,(name,free,source,pred,closed) in enumerate(fo_cases()):
  ps=[()] if free==0 else points(free)
  expected='['+', '.join('('+str([(q.numerator,q.denominator) for q in p])+', '+str(bool(pred(p))).lower()+')' for p in ps)+']'
  flines+=['','///|',f'test "independent FO closed form {i} {name}" {{',f'  review_fo_fixture({free}, {source}, {expected})','}']
  frecords.append(dict(case=i,name=name,free=free,source=source,closed_form=closed,samples=[dict(point=list(map(str,p)),expected=bool(pred(p))) for p in ps]))
 runner=runner_source([(cs[0],[True,False,False,False]),(cs[1],[True,False,False,False]),(cs[2],[True,False,False,False]),(cs[9],[True,True,True,False])])
 return '\n'.join(lines)+'\n','\n'.join(flines)+'\n',runner,dict(cad=records,first_order=frecords,old_cad2_cases=[0,1,2,9],oracle='Exact Fraction evaluation of independently derived closed forms; old CAD2 comparisons over complete old base cells')


def tokens(source):return re.findall(r'"(?:\\.|[^"\\])*"|\S',re.sub(r',\s*([\]\)}])',r'\1',source))
def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--check',action='store_true');args=parser.parse_args()
 cad,fo,runner,data=generate()
 for path,source in [(CAD,cad),(FO,fo)]:
  if args.check:assert tokens(path.read_text())==tokens(source),str(path)+' fixture drift'
  else:path.write_text(source)
 ART.mkdir(parents=True,exist_ok=True)
 comparison=ART/'comparison';comparison.mkdir(exist_ok=True)
 split=runner.index('\n\nfn review_poly')
 (ART/'moon.work').write_text('members = ["../..", "./comparison"]\n')
 (comparison/'moon.mod').write_text('name = "Hosi121/cadreview"\nversion = "0.0.0"\nimport { "Hosi121/morph@0.1.0" }\n')
 (comparison/'moon.pkg').write_text(runner[:split]+'\n\npkgtype(kind: "executable")\n')
 (comparison/'main.mbt').write_text(runner[split+2:])
 stress=comparison/'stress';stress.mkdir(exist_ok=True)
 (stress/'moon.pkg').write_text('import { "Hosi121/morph/cad" @cad, "Hosi121/morph/realcad" @qf, "Hosi121/morph/realformula" @logic, "Hosi121/morph/polynomial" @poly, "Hosi121/morph/testsupport" @oracle }\npkgtype(kind: "executable")\n')
 helper=runner[runner.index('fn review_poly'):runner.index('fn budget()')]
 stress_matrix=conj(atom(y*(y-x-1),'EqualZero',[x,y]),atom(y*(y-2*x-3),'EqualZero',[x,y]),atom(y,'NotZero',[x,y]))
 stress_source=helper+'fn main raise {\n  println("prepare original shared-factor stress")\n  let problem=@cad.prepare(@oracle.nat(2), '+stress_matrix+').unwrap()\n  println("run original shared-factor stress")\n  let value=match @cad.run(@cad.start(problem),@oracle.nat(100000)).unwrap() { Complete(v)=>v; _=>fail("finite transition budget") }\n  println("check original shared-factor stress")\n  assert_true(@cad.check_result(problem,value,@cad.certificate(value)))\n  let qe=@cad.eliminate(value,@oracle.nat(1),@oracle.chain([@logic.Quantifier::Exists])).unwrap()\n  for x in [-3,-2,-1,0,1,2] { assert_eq(@cad.evaluate_formula(@cad.rational_point(@oracle.chain([@oracle.rational(x,1)])),@cad.quantifier_free(qe)).unwrap(),x == -2) }\n  println("original shared-factor stress verified")\n}\n'
 (stress/'main.mbt').write_text(stress_source)
 data['optional_stress']={'matrix':'y*(y-x-1)=0 and y*(y-2*x-3)=0 and y!=0','closed_form':'x=-2','command':'tools/measure --cpu 8 .tools/moon/bin/moon -C .tools/cad-review-20261116 run comparison/stress --target native','default_suite':False,'observed_limit':'Initial implementation exceeded a 10-second diagnostic cap for the full QE/checker case; no semantic result inferred.'}
 (ART/'oracle.json').write_text(json.dumps(data,indent=2)+'\n')
 print(f"{'Checked' if args.check else 'Wrote'} 19 CAD and 6 FO closed-form cases, plus 4 old-CAD2 complete base-cell comparisons.")
if __name__=='__main__':main()
