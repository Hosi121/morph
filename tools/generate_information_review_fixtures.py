#!/usr/bin/env python3
"""Independent Sympy calculus review; no MoonBit helpers or observed values as expectations."""
from pathlib import Path
from functools import lru_cache
from itertools import product, combinations_with_replacement
import argparse, gzip, hashlib, json, subprocess
from fractions import Fraction

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "docs/research/amari-chentsov-independent-20261118-raw"
s = QQ = x = y = z = alpha = None


def symbolic_backend():
    """Loaded only by mathematical re-derivation, never --check-stored."""
    global s, QQ, x, y, z, alpha
    import sympy
    s = sympy
    QQ = s.Rational
    x, y = s.symbols('x y', real=True)
    z = (x, y)
    alpha = s.symbols('alpha', real=True)


def q(value):
    value = s.cancel(value)
    assert value.is_Rational, value
    return [int(value.p), int(value.q)]

def flatten(value):
    if isinstance(value, s.MatrixBase): return [q(x) for x in value]
    if isinstance(value, list):
        result=[]
        for x in value: result.extend(flatten(x))
        return result
    return [q(value)]

def gaussian_cases():
    result=[]
    inputs=[([0],[[1]]),([QQ(2,3)],[[QQ(3,2)]]),([QQ(-5,4)],[[QQ(2,3)]]),
            ([QQ(1,3),QQ(-2,5)],[[2,QQ(1,2)],[QQ(1,2),QQ(3,2)]]),
            ([-2,QQ(1,2)],[[QQ(3,2),QQ(-1,3)],[QQ(-1,3),QQ(4,3)]]),
            ([QQ(2,5),QQ(3,4)],[[QQ(5,4),QQ(2,3)],[QQ(2,3),QQ(7,3)]]),
            ([0,0],[[2,1],[1,2]])]
    for d in (1,2):
        eta=s.symbols('eta0:'+str(d)); pairs=[(i,j) for i in range(d) for j in range(i,d)]
        theta=s.symbols('theta0:'+str(len(pairs))); variables=eta+theta
        H=s.zeros(d)
        for var,(i,j) in zip(theta,pairs): H[i,j]=H[j,i]=var if i==j else var/2
        e=s.Matrix(eta)
        F=-(e.T*H.inv()*e)[0]/4-s.log((-2*H).det())/2
        @lru_cache(None)
        def derivative(indices):
            return F if not indices else s.diff(derivative(indices[:-1]),variables[indices[-1]])
        keys=[key for order in (2,3,4) for key in combinations_with_replacement(range(len(variables)),order)]
        for key in keys: derivative(key)
        for mean,covariance in inputs:
            if len(mean)!=d: continue
            covariance=s.Matrix(covariance);mu=s.Matrix(mean);P=covariance.inv()
            assert all(covariance[:k,:k].det()>0 for k in range(1,d+1))
            ep=P*mu;hp=-P/2
            values=list(ep)+[hp[i,j] if i==j else 2*hp[i,j] for i,j in pairs]
            substitution=dict(zip(variables,values))
            evaluated={key:s.cancel(derivative(key).subs(substitution)) for key in keys}
            item={'name':'gaussian_'+str(len(result)), 'dimension':d,'parameters':len(variables),
                  'mean':flatten(mu),'covariance':flatten(covariance),'natural_point':[q(x) for x in values]}
            for order,name in [(2,'metric'),(3,'first'),(4,'second')]:
                item[name]=[q(evaluated[tuple(sorted(indices))]) for indices in product(range(len(variables)),repeat=order)]
            result.append(item)
            print('Gaussian derived',item['name'],d,flush=True)
    return result


def evaluate(expr,point): return s.cancel(expr.subs(dict(zip(z,point))))

def tensor(shape,entry,prefix=()):
    return entry(prefix) if not shape else [tensor(shape[1:],entry,prefix+(i,)) for i in range(shape[0])]

def finite_base(name, probabilities, point):
    assert s.expand(sum(probabilities)-1)==0
    assert all(evaluate(p,point)>0 for p in probabilities)
    logs=[s.log(p) for p in probabilities]
    metric=s.Matrix(2,2,lambda i,j:sum(p*s.diff(l,z[i])*s.diff(l,z[j]) for p,l in zip(probabilities,logs)))
    g=metric.applyfunc(lambda e:evaluate(e,point));assert g.det()>0
    first=[metric.diff(variable).applyfunc(lambda e:evaluate(e,point)) for variable in z]
    second=[[metric.diff(a,b).applyfunc(lambda e:evaluate(e,point)) for b in z] for a in z]
    jets=[{'p':q(evaluate(p,point)), 'gradient':[q(evaluate(s.diff(p,a),point)) for a in z],
           'hessian':flatten(s.hessian(p,z).applyfunc(lambda e:evaluate(e,point))),
           'third':[q(evaluate(s.diff(p,z[i],z[j],z[k]),point)) for i,j,k in product(range(2),repeat=3)]}
          for p in probabilities]
    cubic=tensor([2,2,2],lambda a:sum(p*s.diff(l,z[a[0]])*s.diff(l,z[a[1]])*s.diff(l,z[a[2]]) for p,l in zip(probabilities,logs)))
    cubic=[q(evaluate(e,point)) for plane in cubic for row in plane for e in row]
    polys=[]
    for p in probabilities:
        polys.append([{'coefficient':q(c),'exponents':list(exponents)} for exponents,c in s.Poly(s.expand(p),z).terms()])
    item={'name':name,'point':[q(a) for a in point],'polynomials':polys,'jets':jets,
          'metric':flatten(g),'first':[q(a) for matrix in first for a in matrix],
          'second':[q(a) for row in second for matrix in row for a in matrix],
          'cubic':cubic,'natural_gradient':flatten(g.inv()*s.Matrix([QQ(2,3),QQ(-1,2)]))}
    return item,probabilities,logs,g,first

def with_alphas(base):
    item,probabilities,logs,g,first=base
    # Compute a local symbolic inverse and differentiate it, rather than coding
    # the derivative-of-inverse identity used by the implementation under review.
    u,v=s.symbols('du dv');delta=(u,v)
    glocal=g+first[0]*u+first[1]*v
    inverse_local=glocal.inv()
    result=[]
    lower_symbolic=tensor([2,2,2],lambda a:sum(p*(s.diff(l,z[a[0]],z[a[1]])+(1-alpha)/2*s.diff(l,z[a[0]])*s.diff(l,z[a[1]]))*s.diff(l,z[a[2]]) for p,l in zip(probabilities,logs)))
    by_alpha={}
    for value in (QQ(0),QQ(1),QQ(-1),QQ(3,5),QQ(-3,5)):
        low=tensor([2,2,2],lambda a:evaluate(lower_symbolic[a[0]][a[1]][a[2]].subs(alpha,value),[s.Rational(*q) for q in item['point']]))
        dlow=tensor([2,2,2,2],lambda a:evaluate(s.diff(lower_symbolic[a[1]][a[2]][a[3]],z[a[0]]).subs(alpha,value),[s.Rational(*q) for q in item['point']]))
        local=tensor([2,2,2],lambda a:sum(inverse_local[a[2],b]*(low[a[0]][a[1]][b]+sum(dlow[k][a[0]][a[1]][b]*delta[k] for k in range(2))) for b in range(2)))
        upper=tensor([2,2,2],lambda a:s.cancel(local[a[0]][a[1]][a[2]].subs({u:0,v:0})))
        dupper=tensor([2,2,2,2],lambda a:s.cancel(s.diff(local[a[1]][a[2]][a[3]],delta[a[0]]).subs({u:0,v:0})))
        connection=[s.Matrix(2,2,lambda r,j:upper[i][j][r]) for i in range(2)]
        curvature=[[s.Matrix(2,2,lambda r,j:dupper[k][l][j][r]-dupper[l][k][j][r])+connection[k]*connection[l]-connection[l]*connection[k] for l in range(2)] for k in range(2)]
        riemann=tensor([2,2,2,2],lambda a:s.cancel(curvature[a[2]][a[3]][a[0],a[1]]))
        lowered=tensor([2,2,2,2],lambda a:s.cancel((g*curvature[a[2]][a[3]])[a[0],a[1]]))
        ricci=s.Matrix(2,2,lambda j,l:sum(riemann[r][j][r][l] for r in range(2)))
        scalar=s.cancel(s.trace(g.inv()*ricci))
        for r,j,k,l in product(range(2),repeat=4):
            assert riemann[r][j][k][l]+riemann[r][k][l][j]+riemann[r][l][j][k]==0
        by_alpha[value]=lowered
        result.append({'alpha':q(value),'lower':flatten(low),'lower_first':flatten(dlow),
                       'coefficients':flatten(upper),'derivatives':flatten(dupper),
                       'riemann':flatten(riemann),'lowered':flatten(lowered),
                       'ricci':flatten(ricci),'scalar':q(scalar)})
    for a in (QQ(0),QQ(1),QQ(3,5)):
        for i,j,k,l in product(range(2),repeat=4):
            assert by_alpha[a][i][j][k][l]+by_alpha[-a][j][i][k][l]==0
    item['alphas']=result
    print('Finite derived',item['name'],flush=True)
    return item

def finite_cases():
    a=[QQ(1,4)+x/10+y/20+x*y/30+x*x/40+x*x*y/60,
       QQ(1,5)-x/12+y/15+x*y*y/70-y*y/50,
       QQ(3,10)+x/25-y/9+x*y/35-x**3/80]
    a.append(1-sum(a))
    b=[QQ(1,5)+x/9-y/17+x*x*y/25+x*x*y*y/33,
       QQ(1,6)-x/13+y/11+x*y*y/29+y**3/45,
       QQ(1,7)+x/15+y/19-x*x/31+x*y/37,
       QQ(1,8)-x/23-y/21+x**3/41-y*y/43]
    b.append(1-sum(b))
    cases=[]
    for name,ps,points in [('four_outcome',a,[(QQ(1,3),QQ(-1,4)),(QQ(-1,4),QQ(1,5))]),('five_outcome',b,[(QQ(1,5),QQ(1,4)),(QQ(-1,3),QQ(1,6))])]:
        for index,point in enumerate(points):cases.append(with_alphas(finite_base(name+'_'+str(index),ps,point)))
    return cases

def rat(value):
 n,d=value
 return f'({str(n<0).lower()}, "{abs(n):x}", "{d:x}")'

def rats(values): return '['+', '.join(rat(v) for v in values)+']'

def preamble(): return '''// Independent Sympy log-partition/coordinate-calculus oracle; generated in scratch.
///|
type IRRat = (Bool,String,String)
///|
fn ir_q(value : IRRat) -> @exact.Rational {
  let (negative,n,d) = value
  let numerator = @exact.positive(@oracle.binary_from_hex(n))
  let numerator = if negative { @exact.negate(numerator) } else { numerator }
  @exact.ratio(numerator,@oracle.binary_from_hex(d)).unwrap()
}
///|
fn ir_values(values : Array[IRRat]) -> @core.Chain[@exact.Rational] {
  @oracle.chain(values.map(ir_q))
}
///|
fn ir_matrix(values : Array[IRRat], width : Int32) -> @matrix.Matrix[@exact.Rational] {
  let rows = Array::makei(width,fn(i) { @oracle.chain(Array::makei(width,fn(j) { ir_q(values[i*width+j]) })) })
  @matrix.matrix(@oracle.nat(width),@oracle.chain(rows)).unwrap()
}
///|
fn ir_flat_matrix(value : @matrix.Matrix[@exact.Rational]) -> @core.Chain[@exact.Rational] {
  @core.fold_left(@matrix.rows(value),@core.Nil,@core.append)
}
///|
fn ir_flat_first(value : @core.Chain[@matrix.Matrix[@exact.Rational]]) -> @core.Chain[@exact.Rational] {
  @core.fold_left(value,@core.Nil,fn(result,matrix) { @core.append(result,ir_flat_matrix(matrix)) })
}
///|
fn ir_flat_second(value : @core.Chain[@core.Chain[@matrix.Matrix[@exact.Rational]]]) -> @core.Chain[@exact.Rational] {
  @core.fold_left(value,@core.Nil,fn(result,row) { @core.append(result,ir_flat_first(row)) })
}
'''

def render(DATA):
    G=preamble()+'''///|
    struct IRGaussian {
     name : String
     dimension : Int32
     parameters : Int32
     mean : Array[IRRat]
     covariance : Array[IRRat]
     metric : Array[IRRat]
     first : Array[IRRat]
     second : Array[IRRat]
    }
    ///|
    fn ir_gaussians() -> Array[IRGaussian] {
     [
    '''
    for f in DATA['gaussian']:
     G+=' { name: "'+f['name']+'", dimension: '+str(f['dimension'])+', parameters: '+str(f['parameters'])+',\n'
     G+=',\n'.join(' '+key+': '+rats(f[key]) for key in ['mean','covariance','metric','first','second'])+',\n },\n'
    G+=''' ]
    }
    ///|
    test "independent Sympy Gaussian natural log-partition derivatives through order four" {
      for f in ir_gaussians() {
        let source = gaussian(ir_values(f.mean),ir_matrix(f.covariance,f.dimension)).unwrap()
        let jet = fisher_jet(source).unwrap()
        assert_eq(@riemann.dimension(jet),@oracle.nat(f.parameters),msg=f.name)
        assert_eq(ir_flat_matrix(@riemann.metric(jet)),ir_values(f.metric),msg=f.name)
        assert_eq(ir_flat_first(@riemann.first_derivatives(jet)),ir_values(f.first),msg=f.name)
        assert_eq(ir_flat_second(@riemann.second_derivatives(jet)),ir_values(f.second),msg=f.name)
      }
    }
    '''
    S=preamble()+'''///|
    struct IRTerm { coefficient : IRRat; exponents : Array[Int32] }
    ///|
    struct IRJet { p : IRRat; gradient : Array[IRRat]; hessian : Array[IRRat]; third : Array[IRRat] }
    ///|
    struct IRAlpha {
     alpha : IRRat
     lower : Array[IRRat]
     lower_first : Array[IRRat]
     coefficients : Array[IRRat]
     derivatives : Array[IRRat]
     riemann : Array[IRRat]
     lowered : Array[IRRat]
     ricci : Array[IRRat]
     scalar : IRRat
    }
    ///|
    struct IRFinite {
     name : String
     point : Array[IRRat]
     polynomials : Array[Array[IRTerm]]
     jets : Array[IRJet]
     metric : Array[IRRat]
     first : Array[IRRat]
     second : Array[IRRat]
     cubic : Array[IRRat]
     scores : Array[IRRat]
     natural_gradient : Array[IRRat]
     cubic_pullback : IRRat
     alphas : Array[IRAlpha]
    }
    ///|
    fn ir_finites() -> Array[IRFinite] {
     [
    '''
    for f in DATA['finite']:
     S+=' { name: "'+f['name']+'", point: '+rats(f['point'])+',\n polynomials: [\n'
     for p in f['polynomials']:
      S+=' ['+', '.join('{ coefficient: '+rat(t['coefficient'])+', exponents: ['+', '.join(map(str,t['exponents']))+'] }' for t in p)+'],\n'
     S+=' ],\n jets: [\n'
     for jet in f['jets']:
      S+=' { p: '+rat(jet['p'])+', '+', '.join(k+': '+rats(jet[k]) for k in ['gradient','hessian','third'])+' },\n'
     S+=' ],\n'+',\n'.join(' '+k+': '+rats(f[k]) for k in ['metric','first','second','cubic','natural_gradient'])+',\n'
     scores=[[Fraction(*a)/Fraction(*jet['p']) for a in jet['gradient']] for jet in f['jets']]
     S+=' scores: '+rats([[v.numerator,v.denominator] for row in scores for v in row])+',\n'
     direction=[Fraction(1,2),Fraction(-2,3)]
     value=sum((Fraction(*f['cubic'][(i*2+j)*2+k])*direction[i]*direction[j]*direction[k] for i in range(2) for j in range(2) for k in range(2)),Fraction(0))
     S+=' cubic_pullback: '+rat([value.numerator,value.denominator])+',\n alphas: [\n'
     for a in f['alphas']:
      S+=' { alpha: '+rat(a['alpha'])+', scalar: '+rat(a['scalar'])+',\n'+',\n'.join(' '+k+': '+rats(a[k]) for k in ['lower','lower_first','coefficients','derivatives','riemann','lowered','ricci'])+',\n },\n'
     S+=' ],\n },\n'
    S+=''' ]
    }
    ///|
    fn ir_family(f : IRFinite) -> @infogeom.Family {
      let polynomials = f.polynomials.map(fn(terms) {
        @polynomial.polynomial(@oracle.nat(2),@oracle.chain(terms.map(fn(t) {
          @polynomial.Term::{ coefficient: ir_q(t.coefficient), exponents: @oracle.chain(t.exponents.map(@oracle.nat)) }
        }))).unwrap()
      })
      @infogeom.family(@oracle.nat(2),@oracle.chain(polynomials)).unwrap()
    }
    ///|
    test "independent Sympy nonclosedform finite family jets and alpha curvature" {
      for f in ir_finites() {
        let family = ir_family(f)
        let point = @infogeom.at(family,ir_values(f.point)).unwrap()
        let model = @infogeom.local_model(point)
        assert_eq(@infogeom.dimension(model),@oracle.nat(2),msg=f.name)
        let jets = @oracle.array(@infogeom.jets(model))
        let thirds = @oracle.array(@infogeom.third_derivatives(point))
        assert_eq(jets.length(),f.jets.length(),msg=f.name)
        assert_eq(thirds.length(),f.jets.length(),msg=f.name)
        for i in 0..<f.jets.length() {
          assert_eq(jets[i].probability,ir_q(f.jets[i].p),msg=f.name)
          assert_eq(jets[i].gradient,ir_values(f.jets[i].gradient),msg=f.name)
          assert_eq(ir_flat_matrix(jets[i].hessian),ir_values(f.jets[i].hessian),msg=f.name)
          assert_eq(ir_flat_first(thirds[i]),ir_values(f.jets[i].third),msg=f.name)
        }
        assert_eq(@infogeom.fisher(model),ir_matrix(f.metric,2),msg=f.name)
        assert_eq(ir_flat_matrix(@infogeom.scores(model).unwrap()),ir_values(f.scores),msg=f.name)
        assert_eq(ir_flat_first(@infogeom.metric_first(model).unwrap()),ir_values(f.first),msg=f.name)
        assert_eq(ir_flat_second(@infogeom.metric_second(point).unwrap()),ir_values(f.second),msg=f.name)
        assert_eq(ir_flat_first(@infogeom.cubic(model).unwrap()),ir_values(f.cubic),msg=f.name)
        assert_eq(@tensor.entries(cubic_tensor(model).unwrap()),ir_values(f.cubic),msg=f.name)
        assert_eq(@infogeom.natural_gradient(model,@oracle.chain([@oracle.rational(2,3),@oracle.rational(-1,2)])).unwrap(),ir_values(f.natural_gradient),msg=f.name)
        let jacobian = @matrix.matrix(@oracle.nat(1),@oracle.chain([@oracle.chain([@oracle.rational(1,2)]),@oracle.chain([@oracle.rational(-2,3)])])).unwrap()
        assert_eq(@tensor.entries(pullback_cubic(model,jacobian).unwrap()),@core.Cons(ir_q(f.cubic_pullback),@core.Nil),msg=f.name)
        for index, a in f.alphas {
          let label = f.name + " alpha#" + index.to_string()
          let alpha = ir_q(a.alpha)
          let actual = alpha_geometry(point,alpha).unwrap()
          let three = @oracle.chain([2,2,2].map(@oracle.nat))
          let four = @oracle.chain([2,2,2,2].map(@oracle.nat))
          assert_eq(@tensor.shape(alpha_coefficients(actual)),three,msg=label)
          assert_eq(@tensor.shape(alpha_derivatives(actual)),four,msg=label)
          assert_eq(@tensor.shape(alpha_riemann(actual)),four,msg=label)
          assert_eq(@tensor.shape(alpha_lowered_riemann(actual)),four,msg=label)
          assert_eq(ir_flat_first(@infogeom.alpha_lower(model,alpha).unwrap()),ir_values(a.lower),msg=label)
          assert_eq(ir_flat_second(@infogeom.alpha_lower_first(point,alpha).unwrap()),ir_values(a.lower_first),msg=label)
          assert_eq(@tensor.entries(alpha_coefficients(actual)),ir_values(a.coefficients),msg=label)
          assert_eq(@tensor.entries(alpha_raised(model,alpha).unwrap()),ir_values(a.coefficients),msg=label)
          assert_eq(@tensor.entries(alpha_derivatives(actual)),ir_values(a.derivatives),msg=label)
          assert_eq(@tensor.entries(alpha_riemann(actual)),ir_values(a.riemann),msg=label)
          assert_eq(@tensor.entries(alpha_lowered_riemann(actual)),ir_values(a.lowered),msg=label)
          assert_eq(ir_flat_matrix(alpha_ricci(actual)),ir_values(a.ricci),msg=label)
          assert_eq(alpha_scalar(actual),ir_q(a.scalar),msg=label)
          if index == 0 {
            let ordinary = curvature(point).unwrap()
            let upper = @core.fold_left(@riemann.riemann(ordinary),@core.Nil,fn(result,tensor) {
              @core.fold_left(tensor,result,fn(result,matrix) { @core.fold_left(matrix,result,@core.append) })
            })
            assert_eq(upper,ir_values(a.riemann),msg=label)
            assert_eq(scalar_by_contraction(ordinary).unwrap(),ir_q(a.scalar),msg=label)
          }
        }
      }
    }
    '''
    return {"src/gaussian/gaussian_sympy_review_wbtest.mbt": G,
            "src/statgeometry/finite_sympy_review_wbtest.mbt": S}


def counts(data):
    gaussian = sum(sum(len(f[k]) for k in ('metric', 'first', 'second')) for f in data['gaussian'])
    finite = 0
    for f in data['finite']:
        finite += sum(len(f[k]) for k in ('metric', 'first', 'second', 'cubic', 'natural_gradient'))
        finite += sum(1 + sum(len(j[k]) for k in ('gradient', 'hessian', 'third')) for j in f['jets'])
        finite += sum(1 + sum(len(a[k]) for k in ('lower', 'lower_first', 'coefficients', 'derivatives', 'riemann', 'lowered', 'ricci')) for a in f['alphas'])
    auxiliary = sum(len(f['jets']) * 2 + 1 for f in data['finite'])
    crosschecks = sum(len(f['cubic']) + sum(len(a['coefficients']) for a in f['alphas']) + 17 for f in data['finite'])
    return dict(gaussian_cases=len(data['gaussian']), finite_points=len(data['finite']),
                alpha_geometries=sum(len(f['alphas']) for f in data['finite']),
                gaussian_component_positions=gaussian, finite_component_positions=finite,
                archived_component_positions=gaussian + finite,
                auxiliary_scores_and_pullback_positions=auxiliary,
                additional_public_api_crosscheck_positions=crosschecks)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--check', action='store_true', help='Sympy: rederive the mathematics and check generated bytes')
    mode.add_argument('--check-stored', action='store_true', help='stdlib: rerender committed oracle data only; no mathematical rederivation')
    args = parser.parse_args()
    checking = args.check or args.check_stored
    if args.check_stored:
        data = json.loads(gzip.decompress((RAW / 'oracles.json.gz').read_bytes()))
    else:
        symbolic_backend()
        data = dict(sympy=s.__version__, gaussian=gaussian_cases(), finite=finite_cases())
    payload = (json.dumps(data, sort_keys=True) + '\n').encode()
    generated = render(data)
    formatter = str(ROOT / '.tools/moon/bin/moonfmt')
    for relative, source in generated.items():
        source = subprocess.run([formatter, '-'], input=source, text=True, check=True, capture_output=True).stdout
        path = ROOT / relative
        if checking:
            if path.read_text() != source:
                raise SystemExit('Independent fixtures differ: ' + relative)
        else:
            path.write_text(source)
    oracle = RAW / 'oracles.json.gz'
    summary = counts(data)
    summary['sympy'] = data['sympy']
    summary['oracle_uncompressed_sha256'] = hashlib.sha256(payload).hexdigest()
    summary_bytes = (json.dumps(summary, indent=2, sort_keys=True) + '\n').encode()
    if checking:
        if gzip.decompress(oracle.read_bytes()) != payload:
            raise SystemExit('Independent oracle payload differs')
        if (RAW / 'oracle-summary.json').read_bytes() != summary_bytes:
            raise SystemExit('Independent oracle summary differs')
    else:
        RAW.mkdir(parents=True, exist_ok=True)
        with gzip.GzipFile(oracle, 'wb', mtime=0) as output:
            output.write(payload)
        (RAW / 'oracle-summary.json').write_bytes(summary_bytes)
    label = 'stored oracle consistency only' if args.check_stored else 'Sympy mathematical rederivation'
    print(label + ': ' + json.dumps(counts(data), sort_keys=True))


if __name__ == '__main__':
    main()
