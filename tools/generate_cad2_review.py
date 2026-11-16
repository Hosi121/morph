#!/usr/bin/env python3
"""Implementation-independent CAD2/relativeCAD families, frozen before CAD2 API.
Exact signs and roots use SymPy; quantified truth follows stated family identities.
No implementation source or implementation-produced expected result is read.
"""
from pathlib import Path
from functools import cmp_to_key
import argparse,hashlib,json,subprocess
import sympy as s
ROOT=Path(__file__).resolve().parents[1];x,y=s.symbols('x y',real=True)
def atom(i,r):return ['atom',i,r]
def conj(a,b):return ['and',a,b]
def disj(a,b):return ['or',a,b]
def neg(a):return ['not',a]
def sign(a):
 z=s.sign(s.simplify(s.expand(a)))
 assert z in (-1,0,1),(a,z)
 return int(z)
def same(a,b):return s.simplify(a-b)==0
def compare(a,b):return sign(a-b)
def holds(f,ss):
 op=f[0]
 if op=='truth':return f[1]
 if op=='not':return not holds(f[1],ss)
 if op=='and':return holds(f[1],ss) and holds(f[2],ss)
 if op=='or':return holds(f[1],ss) or holds(f[2],ss)
 z=ss[f[1]]
 return {'lt':z<0,'le':z<=0,'eq':z==0,'ne':z!=0,'ge':z>=0,'gt':z>0}[f[2]]
def terms(p):
 return [[int(c.p),int(c.q),int(e[0]),int(e[1])] for e,c in s.Poly(p,x,y,domain=s.QQ).terms() if c]
def roots_at(ps,a):
 roots=[];polynomials=[s.simplify(p.subs(x,a)) for p in ps]
 for p in polynomials:
  if not p or not p.has(y):continue
  for r in s.solve(p,y):
   if r.is_real is False:continue
   assert r.is_real is True,(p,r)
   if not any(same(r,z) for z in roots):roots.append(r)
 return sorted(roots,key=cmp_to_key(compare)),polynomials
def fibre(ps,f,a):
 a=s.sympify(a)
 assert not a.atoms(s.Float), ("inexact fibre sample",a)
 roots,polynomials=roots_at(ps,a)
 assert not any(z.atoms(s.Float) for z in roots+polynomials), ("inexact roots/coefficients",a)
 samples=[]
 if roots:
  samples=[roots[0]-1]
  for i,r in enumerate(roots):
   samples.append(r)
   if i+1<len(roots):samples.append((r+roots[i+1])/2)
  samples.append(roots[-1]+1)
 else:samples=[s.Integer(0)]
 assert not any(z.atoms(s.Float) for z in samples), ("inexact sector samples",a)
 signs=[[sign(p.subs(y,b)) for p in polynomials] for b in samples]
 truth=[holds(f,ss) for ss in signs]
 return dict(x=str(a),roots=[str(r) for r in roots],samples=[str(b) for b in samples],signs=signs,truth=truth,exists=any(truth),forall=all(truth),nullified=[i for i,p in enumerate(polynomials) if p==0])
def cover(cuts):
 cuts=sorted(map(s.sympify,cuts),key=cmp_to_key(compare))
 if not cuts:return [s.Integer(0)]
 out=[cuts[0]-1]
 for i,c in enumerate(cuts):
  out.append(c)
  if i+1<len(cuts):out.append((c+cuts[i+1])/2)
 out.append(cuts[-1]+1)
 return out
# Explicit expected [exists x exists y, exists x forall y,
# forall x exists y, forall x forall y]. Each reason is independent of sampling.
P=[]
def plane(name,ps,f,cuts,expected,reason):P.append((name,ps,f,cuts,expected,reason))
circle=x*x+y*y-1
plane('circle equality',[circle],atom(0,'eq'),[-1,1],[1,0,0,0],'A circle exists, has no full vertical line, and has no point above x=2.')
plane('closed disk',[circle],atom(0,'le'),[-1,1],[1,0,0,0],'The disk has points but bounded vertical fibres and no fibre above x=2.')
plane('open disk strict endpoints',[circle],atom(0,'lt'),[-1,1],[1,0,0,0],'At x=+-1 the strict disk fibre is empty; at x=0 it is nonempty.')
plane('strict circle exterior',[circle],atom(0,'gt'),[-1,1],[1,1,1,0],'x=2 makes all y exterior; every x admits sufficiently large y; the centre is interior.')
plane('parabola equality',[y-x*x],atom(0,'eq'),[0],[1,0,1,0],'The witness y=x^2 exists for every x, but no fibre is the full line.')
plane('strict parabola epigraph',[y-x*x],atom(0,'gt'),[0],[1,0,1,0],'Choose y=x^2+1, while y=x^2 is a counterexample to universal y.')
plane('quadratic degree birth',[y*y-x],atom(0,'eq'),[0],[1,0,0,0],'A real square equals x exactly when x>=0.')
plane('nullified xy equality',[x*y],atom(0,'eq'),[0],[1,1,1,0],'x=0 nullifies the atom for all y, and y=0 works for every x.')
plane('nullified xy strict',[x*y],atom(0,'gt'),[0],[1,0,0,0],'x=0 forbids strict positivity, and any nonzero x has both y signs.')
plane('nullified xy disequality',[x*y],atom(0,'ne'),[0],[1,0,0,0],'At x=0 or y=0 the product is zero; x=y=1 is nonzero.')
plane('guarded nullification',[x,x*y],disj(atom(0,'eq'),atom(1,'gt')),[0],[1,1,1,0],'x=0 makes the guard true for all y; other x choose the matching y sign.')
plane('shared line equality',[y-x,(y-x)*(y+x)],conj(atom(0,'eq'),atom(1,'eq')),[0],[1,0,1,0],'y=x is a shared root for every x; other y refute universal y.')
plane('shared root collision strict',[(y-x)**2,(y-x)*(y+x)],conj(atom(0,'gt'),atom(1,'eq')),[0],[1,0,0,0],'The remaining root y=-x works exactly when x!=0.')
plane('repeated square impossible',[(y-x)**2],atom(0,'lt'),[0],[0,0,0,0],'A real square is never strictly negative.')
plane('repeated square nonnegative',[(y-x)**2],atom(0,'ge'),[0],[1,1,1,1],'Every real square is nonnegative.')
plane('shared factors mixed strict',[(y-x)**2*(y+x),(y-x)*(y+1)],conj(atom(0,'gt'),atom(1,'lt')),[-1,0,1],[1,0,0,0],'x=1 permits -1<y<1; x=0 makes y^3>0 and y(y+1)<0 incompatible.')
plane('vertical leading coefficient',[(x-1)*y-1],atom(0,'eq'),[1],[1,0,0,0],'x=1 gives constant -1; other x have the unique root 1/(x-1).')
plane('quadratic to linear degree drop',[(x-1)*y*y+y],atom(0,'eq'),[1],[1,0,1,0],'y=0 always works; at x=1 the polynomial is y rather than a quadratic.')
plane('vertical nullification',[(x-1)*y],atom(0,'eq'),[1],[1,1,1,0],'The whole vertical line x=1 is zero and y=0 works elsewhere.')
plane('irrational vertical nullification',[(x*x-2)*y],atom(0,'eq'),[-s.sqrt(2),s.sqrt(2)],[1,1,1,0],'x=+-sqrt(2) nullifies all y coefficients; y=0 works at every x.')
plane('irrational nullification strict',[(x*x-2)*y],atom(0,'gt'),[-s.sqrt(2),s.sqrt(2)],[1,0,0,0],'The strict fibre is empty at +-sqrt(2), and nonempty elsewhere.')
plane('vertical factor times horizontal square',[(x*x-2)*(y*y-1)],atom(0,'ge'),[-s.sqrt(2),s.sqrt(2)],[1,1,1,0],'At +-sqrt(2) all y work; choose |y|>=1 or |y|<=1 to match the other factor sign.')
plane('pure base atom',[x-1],atom(0,'eq'),[1],[1,1,0,0],'At x=1 all y work; at x=0 none do.')
plane('identically zero equality',[s.Integer(0)],atom(0,'eq'),[],[1,1,1,1],'The zero polynomial is zero on the whole plane.')
plane('identically zero strict',[s.Integer(0)],atom(0,'gt'),[],[0,0,0,0],'The zero polynomial is never strictly positive.')
plane('nonzero constant',[s.Integer(3)],atom(0,'gt'),[],[1,1,1,1],'The constant 3 is positive on the whole plane.')
plane('circle shared line endpoints',[circle,y-x],conj(atom(0,'eq'),atom(1,'eq')),[-1,-s.sqrt(2)/2,0,s.sqrt(2)/2,1],[1,0,0,0],'Substitution y=x gives 2x^2=1, with exactly the two isolated solutions.')
plane('circle line strict interior',[circle,y-x],conj(atom(0,'lt'),atom(1,'eq')),[-1,-s.sqrt(2)/2,0,s.sqrt(2)/2,1],[1,0,0,0],'Substitution y=x gives the strict interval -1/sqrt(2)<x<1/sqrt(2).')
plane('open interval between moving roots',[(y-x)*(y-x-1)],atom(0,'lt'),[],[1,0,1,0],'For every x, the open interval x<y<x+1 is nonempty and proper.')
plane('closed interval between moving roots',[(y-x)*(y-x-1)],atom(0,'le'),[],[1,0,1,0],'For every x, the closed interval x<=y<=x+1 is nonempty and proper.')
plane('contradictory strict and weak',[y-x],conj(atom(0,'lt'),atom(0,'ge')),[],[0,0,0,0],'A real number cannot be simultaneously negative and nonnegative.')
plane('trichotomy tautology',[y-x],disj(atom(0,'lt'),disj(atom(0,'eq'),atom(0,'gt'))),[],[1,1,1,1],'Exactly one of negative, zero, positive holds at every point.')
plane('empty true formula',[],['truth',True],[],[1,1,1,1],'A literal true formula holds at every point of the plane.')
plane('empty false formula',[],['truth',False],[],[0,0,0,0],'A literal false formula has no satisfying point.')
plane('negated closed disk',[circle],neg(atom(0,'le')),[-1,1],[1,1,1,0],'The negation of a closed disk is its strict exterior, including no boundary points.')
plane_records=[]
for name,ps,f,cuts,expected,reason in P:
 ps=list(map(s.expand,ps));fibres=[fibre(ps,f,a) for a in cover(cuts)]
 obtained=[any(z['exists'] for z in fibres),any(z['forall'] for z in fibres),all(z['exists'] for z in fibres),all(z['forall'] for z in fibres)]
 assert obtained==list(map(bool,expected)),(name,obtained,expected)
 plane_records.append(dict(name=name,atoms=[terms(p) for p in ps],formula=f,cuts=list(map(str,cuts)),quantifiers=list(map(bool,expected)),reason=reason,fibres=fibres))
R=[]
def relative(name,alpha,ps,f):R.append((name,alpha,ps,f))
a=s.sqrt(2)
relative('linear over Qsqrt2',a,[y-x],atom(0,'gt'))
relative('quadratic extension fibre',a,[y*y-x],atom(0,'eq'))
relative('negative conjugate has no quadratic roots',-a,[y*y-x],atom(0,'eq'))
relative('repeated field root',a,[(y-x)**2],atom(0,'le'))
relative('shared field roots',a,[y-x,(y-x)*(y+x)],conj(atom(0,'eq'),atom(1,'eq')))
relative('residue nullification',a,[(x*x-2)*y+(x*x-2)],atom(0,'eq'))
relative('residue nullification strict',a,[(x*x-2)*y],atom(0,'gt'))
relative('vanishing leading coefficient degree drop',a,[(x*x-2)*y*y+y-1],atom(0,'gt'))
relative('negative algebraic constant',a,[-x],atom(0,'lt'))
relative('positive conjugate constant',-a,[-x],atom(0,'gt'))
relative('empty atom truth',a,[],['truth',True])
relative('cubic proper extension fibre',a,[y**3-x],atom(0,'eq'))
relative('quartic proper extension fibre',a,[y**4-2],atom(0,'lt'))
relative('odd even repeated root signs',a,[(y-x)**2*(y+x)**3],atom(0,'gt'))
relative('shared factors distinct intervals',a,[(y-x)**2,(y-x)*(y+1)],conj(atom(0,'gt'),atom(1,'lt')))
relative('shared factors negative conjugate',-a,[(y-x)**2,(y-x)*(y+1)],conj(atom(0,'gt'),atom(1,'lt')))
relative('positive leading algebraic sign',a,[x*y-1],atom(0,'gt'))
relative('negative leading algebraic sign',-a,[x*y-1],atom(0,'gt'))
relative('negated strict field inequality',a,[y-x],neg(atom(0,'lt')))
relative_records=[]
for name,alpha,ps,f in R:
 ps=list(map(s.expand,ps));result=fibre(ps,f,alpha)
 relative_records.append(dict(name=name,alpha=str(alpha),atoms=[terms(p) for p in ps],formula=f,**result))
out=ROOT/'docs/research/cad2-independent-review-20261116-fixtures.json'
payload=dict(oracle='known exact factor families; SymPy symbolic real roots/signs; hand-derived quantifier reasons, independent of implementation',sympy=s.__version__,plane=plane_records,relative=relative_records)
encoded=json.dumps(payload,indent=2,sort_keys=True)+'\n'
parser=argparse.ArgumentParser();parser.add_argument('--check',action='store_true');parser.add_argument('--emit-drafts',action='store_true');parser.add_argument('--emit-tests',action='store_true');args=parser.parse_args()
if args.check:
 assert out.read_text()==encoded,'frozen semantic oracle changed'
else:out.write_text(encoded)
artifact=ROOT/'.tools/cad2-independent-review-20261116';artifact.mkdir(parents=True,exist_ok=True)
(artifact/'oracle-sha256.txt').write_text(hashlib.sha256(encoded.encode()).hexdigest()+'\n')
print(f'frozen {len(plane_records)} plane families, {sum(len(r["fibres"]) for r in plane_records)} exact fibres, {len(relative_records)} algebraic-field fibres; sha256={hashlib.sha256(encoded.encode()).hexdigest()}')

# Rendering tests changes no semantic expected data or frozen JSON.
def mb_terms(atoms):
 return '['+', '.join('['+', '.join('('+', '.join(map(str,z))+')' for z in p)+']' for p in atoms)+']'
def mb_bool(value):return 'true' if value else 'false'
def mb_formula(f):
 names={'lt':'LessZero','le':'AtMostZero','eq':'EqualZero','ne':'NotZero','ge':'AtLeastZero','gt':'GreaterZero'}
 op=f[0]
 if op=='truth':return 'Truth('+mb_bool(f[1])+')'
 if op=='atom':return f'Atom(ps[{f[1]}], {names[f[2]]})'
 if op=='not':return 'Negation('+mb_formula(f[1])+')'
 return ('Conjunction' if op=='and' else 'Disjunction')+'('+mb_formula(f[1])+', '+mb_formula(f[2])+')'
def mb_pairs(values):return '['+', '.join(f'({int(c.p)}, {int(c.q)})' for c in values)+']'
def field_data(value):
 p=s.Poly(s.minimal_polynomial(value,x),x,domain=s.QQ).monic()
 for (lo,hi),_ in s.intervals(p,eps=s.Rational(1,32)):
  if lo==hi:
   if not same(value,hi):continue
   lo=hi-1
  if sign(value-lo)>0 and sign(hi-value)>=0:return p,lo,hi
 raise AssertionError(('field root interval',value,p))
def mb_fibre(name,atoms,f,result):
 value=s.sympify(result['x']);p,lo,hi=field_data(value)
 formula=mb_formula(f);param='_' if not atoms else 'ps'
 expected='['+', '.join('['+', '.join(map(str,row))+']' for row in result['signs'])+']'
 truth='['+', '.join(map(mb_bool,result['truth']))+']'
 return ['///|','test '+json.dumps(name)+' {',
  '  review_relative_fixture('+mb_pairs(reversed(p.all_coeffs()))+f', ({int(lo.p)}, {int(lo.q)}), ({int(hi.p)}, {int(hi.q)}),',
  '    '+mb_terms(atoms)+', fn('+param+') { '+formula+' }, '+expected+', '+truth+')','}','']
if args.emit_drafts or args.emit_tests:
 relative_lines=['// Generated from frozen independent semantics, not implementation results.','']
 for i,record in enumerate(relative_records):
  relative_lines+=mb_fibre('independent algebraic fibre '+str(i)+' '+record['name'],record['atoms'],record['formula'],record)
 for i,record in enumerate(plane_records):
  for j,result in enumerate(record['fibres']):
   relative_lines+=mb_fibre(f'independent plane fibre {i} {j} '+record['name'],record['atoms'],record['formula'],result)
 plane_lines=['// Generated from frozen hand-derived quantified semantics.','']
 for i,record in enumerate(plane_records):
  param='_' if not record['atoms'] else 'ps'
  truth='['+', '.join(map(mb_bool,record['quantifiers']))+']'
  plane_lines+=['///|',f'test "independent plane quantifier family {i} '+record['name']+'" {',
   '  review_plane_fixture('+mb_terms(record['atoms'])+', fn('+param+') { '+mb_formula(record['formula'])+' }, '+truth+')','}','']
 targets=[(artifact/'relativecad-frozen-review.mbt',relative_lines),(artifact/'cad2-frozen-review.mbt',plane_lines)]
 if args.emit_tests:
  targets=[(ROOT/'src/relativecad/independent_review_fixtures_wbtest.mbt',relative_lines),(ROOT/'src/cad2/independent_review_fixtures_wbtest.mbt',plane_lines)]
 for path,lines in targets:
  assert path.parent.exists(),path
  path.write_text('\n'.join(lines))
 print(f'emitted {len(relative_records)+sum(len(r["fibres"]) for r in plane_records)} fixed relative fibres and {len(plane_records)} fixed quantified families')
