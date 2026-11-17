#!/usr/bin/env python3
"""Independent affine Miller / shifted-divisor reduced Tate oracle.

The only imported arithmetic is the independent host integer-polynomial Field
from the curve oracle. No morph executable or production source is evaluated.
"""
from pathlib import Path
from argparse import ArgumentParser
import runpy,json,gzip,re,sys,random
from functools import lru_cache

Field=runpy.run_path(str(Path(__file__).with_name('extension-curves-20261118-oracle.py')))['Field']
ERROR_CODES={'ZeroEvaluation':-1,'PoleEvaluation':-2,'IndeterminateEvaluation':-3,'EvaluationAtInfinity':-4}


class EvaluationError(Exception):pass


class CachedField(Field):
    @lru_cache(maxsize=None)
    def mul(self,x,y):return super().mul(x,y)
    @lru_cache(maxsize=None)
    def divide(self,x,y):return super().divide(x,y)


class Curve:
    def __init__(self,p,modulus):
        self.field=CachedField(p,modulus);f=self.field;self.a=f.zero;self.b=f.one
        self.points=[None]+[(x,y) for x in f.values for y in f.values if f.mul(y,y)==f.add(f.mul(f.mul(x,x),x),f.one)]
        self.index={P:i for i,P in enumerate(self.points)}
        self.sums=[[self.index[self.add(P,Q)] for Q in self.points] for P in self.points]
    @lru_cache(maxsize=None)
    def add(self,P,Q):
        f=self.field
        if P is None:return Q
        if Q is None:return P
        x,y=P;u,v=Q
        if x==u and f.add(y,v)==f.zero:return None
        slope=f.divide(f.add(f.times_int(f.mul(x,x),3),self.a),f.times_int(y,2)) if P==Q else f.divide(f.sub(v,y),f.sub(u,x))
        xx=f.sub(f.sub(f.mul(slope,slope),x),u);yy=f.sub(f.mul(slope,f.sub(x,xx)),y)
        return xx,yy
    @lru_cache(maxsize=None)
    def scale(self,P,n):
        result=None
        while n:
            if n&1:result=self.add(result,P)
            P=self.add(P,P);n>>=1
        return result
    def ratio(self,a,b):
        f=self.field
        if a==f.zero:
            raise EvaluationError('IndeterminateEvaluation' if b==f.zero else 'ZeroEvaluation')
        if b==f.zero:raise EvaluationError('PoleEvaluation')
        return f.divide(a,b)
    @lru_cache(maxsize=None)
    def line(self,P,Q,T):
        f=self.field;R=self.add(P,Q)
        if P is None or Q is None:return R,f.one
        if T is None:raise EvaluationError('EvaluationAtInfinity')
        x,y=P;u,v=Q;tx,ty=T
        if x==u and f.add(y,v)==f.zero:return R,self.ratio(f.sub(tx,x),f.one)
        if P==Q:slope=f.divide(f.add(f.times_int(f.mul(x,x),3),self.a),f.times_int(y,2))
        else:slope=f.divide(f.sub(v,y),f.sub(u,x))
        numerator=f.sub(f.sub(ty,y),f.mul(slope,f.sub(tx,x)))
        return R,self.ratio(numerator,f.sub(tx,R[0]))
    @lru_cache(maxsize=None)
    def miller(self,P,n,T):
        f=self.field
        if n==0:return None,f.one
        V=P;value=f.one
        for bit in bin(n)[3:]:
            V,g=self.line(V,V,T);value=f.mul(f.mul(value,value),g)
            if bit=='1':V,g=self.line(V,P,T);value=f.mul(value,g)
        assert V==self.scale(P,n)
        return V,value
    def tate(self,n,P,Q,S):
        f=self.field
        assert n>1 and (f.q-1)%n==0 and self.scale(P,n) is None
        if P is None or Q is None:return f.one,None,None
        _,top=self.miller(P,n,self.add(Q,S));_,bottom=self.miller(P,n,S)
        quotient=self.ratio(top,bottom);value=f.power(quotient,(f.q-1)//n)
        assert f.power(value,n)==f.one
        return value,top,bottom
    def encode(self,x):return sum(a*self.field.p**i for i,a in enumerate(x))
    def point_data(self):
        f=self.field
        return [None if P is None else [f.coefficients(P[0]),f.coefficients(P[1])] for P in self.points]


def tate_case(curve,n):
    f=curve.field;points=curve.points;count=len(points);torsion=[i for i,P in enumerate(points) if curve.scale(P,n) is None]
    image=sorted({curve.index[curve.scale(P,n)] for P in points})
    matrix=[];chosen=[];numerators=[];denominators=[];admissible=[];failures=[]
    for pi in torsion:
        for qi,Q in enumerate(points):
            accepted=[];seen=[]
            for si,S in enumerate(points):
                try:
                    value,top,bottom=curve.tate(n,points[pi],Q,S);accepted.append(si);seen.append((curve.encode(value),0 if top is None else curve.encode(top),0 if bottom is None else curve.encode(bottom)))
                except EvaluationError as e:
                    failures.append([pi,qi,si,ERROR_CODES[str(e)]])
            assert accepted, ('no admissible shift',n,pi,qi)
            assert len({v[0] for v in seen})==1,('shift variance',n,pi,qi)
            matrix.append(seen[0][0]);admissible.append(accepted)
            sample=list(range(len(accepted)))
            random.Random((n*count+pi)*count+qi).shuffle(sample)
            sample=sample[:3]
            chosen.append([accepted[k] for k in sample]);numerators.append([seen[k][1] for k in sample]);denominators.append([seen[k][2] for k in sample])
    pos={p:i for i,p in enumerate(torsion)}
    def get(pi,qi):return f.decode(matrix[pos[pi]*count+qi])
    for pi in torsion:
        for pj in torsion:
            total=curve.sums[pi][pj]
            for qi in range(count):assert get(total,qi)==f.mul(get(pi,qi),get(pj,qi))
        for qi in range(count):
            for qj in range(count):assert get(pi,curve.sums[qi][qj])==f.mul(get(pi,qi),get(pi,qj))
    left_kernel=[pi for pi in torsion if all(get(pi,qi)==f.one for qi in range(count))]
    right_kernel=[qi for qi in range(count) if all(get(pi,qi)==f.one for pi in torsion)]
    assert left_kernel==[0],('degenerate left',n,left_kernel)
    assert right_kernel==image,('wrong right quotient',n,right_kernel,image)
    assert len(torsion)*len(image)==count
    for qi in range(count):
        for ri in image:
            for pi in torsion:assert get(pi,curve.sums[qi][ri])==get(pi,qi)
    # Keep one example of each observable exceptional branch for native tests.
    examples={}
    for row in failures:examples.setdefault(row[3],row)
    return dict(order=n,exponent=(f.q-1)//n,torsion=torsion,image=image,values=matrix,shifts=chosen,raw_numerators=numerators,raw_denominators=denominators,all_admissible_shifts=admissible,error_examples=list(examples.values()),left_kernel=left_kernel,right_kernel=right_kernel,quotient_size=count//len(image),minimum_admissible_shifts=min(map(len,admissible)),host_shift_evaluations=len(torsion)*count*count)


def data():
    prime=Curve(5,[0,1]);extension=Curve(5,[2,0,1]);line_codes=[];miller_codes=[];multiples=[]
    for P in prime.points:
        for Q in prime.points:
            for T in prime.points:
                try:_,v=prime.line(P,Q,T);line_codes.append(prime.encode(v))
                except EvaluationError as e:line_codes.append(ERROR_CODES[str(e)])
        for n in range(9):
            multiples.append(prime.index[prime.scale(P,n)])
            for T in prime.points:
                try:_,v=prime.miller(P,n,T);miller_codes.append(prime.encode(v))
                except EvaluationError as e:miller_codes.append(ERROR_CODES[str(e)])
    large=(1<<200)+17
    P=(extension.field.zero,extension.field.one)
    T=(extension.field.embed([1]),extension.field.embed([0,2]))
    R,v=extension.miller(P,large,T)
    large_case={'p_index':extension.index[P],'at_index':extension.index[T],'multiple':extension.index[R],'value':extension.encode(v),'scalar':str(large)}
    return dict(schema_version=1,oracle='independent affine integer-polynomial line quotients and iterative Miller recurrence',large_miller=large_case,prime=dict(p=5,modulus=[0,1],points=prime.point_data(),sums=prime.sums,line_codes=line_codes,miller_codes=miller_codes,multiples=multiples,scalar_limit=9),extension=dict(p=5,modulus=[2,0,1],points=extension.point_data(),sums=extension.sums,cases=[tate_case(extension,n) for n in (2,3,6)]))


def ints(values,indent):return [indent+str(v)+',' for v in values]
def arr(values):return '['+', '.join(str(v) for v in values)+']'
def point_rows(points):return ['      None,' if P is None else f'      Some(({arr(P[0])}, {arr(P[1])})),' for P in points]


def render(d):
    p=d['prime'];e=d['extension'];out=['// Generated by tools/extension-pairings-20261118-oracle.py.','', '///|','test "independent affine line and Miller oracle over prime field" {','  pa_verify_lines(',f'    {p["p"]},',f'    {arr(p["modulus"])},','    [']+point_rows(p['points'])+['    ],','    [']+ints([x for row in p['sums'] for x in row],'      ')+['    ],','    [']+ints(p['line_codes'],'      ')+['    ],','    [']+ints(p['miller_codes'],'      ')+['    ],','    [']+ints(p['multiples'],'      ')+['    ],',f'    {p["scalar_limit"]},','  )','}','','']
    for c in e['cases']:
        out += ['///|',f'test "independent shifted Tate all pairs order {c["order"]}" {{','  pa_verify_tate(',f'    {e["p"]},',f'    {arr(e["modulus"])},','    [']+point_rows(e['points'])+['    ],','    [']+ints([x for row in e['sums'] for x in row],'      ')+['    ],',f'    {c["order"]},',f'    {c["exponent"]},','    [']+ints(c['torsion'],'      ')+['    ],','    [']+ints(c['values'],'      ')+['    ],','    [']+[f'      {arr(row)},' for row in c['shifts']]+['    ],','    [']+ints([x for row in c['raw_numerators'] for x in row],'      ')+['    ],','    [']+ints([x for row in c['raw_denominators'] for x in row],'      ')+['    ],','    [']+ints(c['image'],'      ')+['    ],','    [']+[f'      ({row[0]}, {row[1]}, {row[2]}, {row[3]}),' for row in c['error_examples']]+['    ],','  )','}','','']
    c=d['large_miller']
    out += ['///|','test "independent two-hundred-bit Miller scalar" {','  pa_verify_large(',f'    {e["p"]},',f'    {arr(e["modulus"])},','    [']+point_rows([e['points'][c['p_index']],e['points'][c['at_index']],e['points'][c['multiple']]])+['    ],',f'    {c["value"]},','  )','}','','']
    return '\n'.join(out)


def main():
    parser=ArgumentParser(description=__doc__);parser.add_argument('--check',action='store_true');args=parser.parse_args();root=Path(__file__).resolve().parents[1];d=data();text=render(d);raw=(json.dumps(d,sort_keys=True,indent=2)+'\n').encode();fixture=root/'src/pairing/host_fixtures_wbtest.mbt';report=root/'docs/research/extension-pairings-20261118-oracle.json.gz'
    def tokens(source):
        values=[t for t in re.findall(r'"(?:\\.|[^"\\])*"|//[^\n]*|\w+|[^\s]',source) if not t.startswith('//')]
        return [t for i,t in enumerate(values) if not (t==',' and i+1<len(values) and values[i+1] in (']',')','}'))]
    if args.check:
        if not fixture.exists() or tokens(fixture.read_text())!=tokens(text):sys.exit('pairing fixture tokens differ; regenerate')
        if not report.exists() or gzip.decompress(report.read_bytes())!=raw:sys.exit('pairing host raw JSON differs; regenerate')
    else:fixture.write_text(text);report.write_bytes(gzip.compress(raw,mtime=0))
    print(json.dumps({'prime_points':len(d['prime']['points']),'line_cases':len(d['prime']['line_codes']),'miller_cases':len(d['prime']['miller_codes']),'extension_points':len(d['extension']['points']),'tate_cases':[{k:c[k] for k in ('order','exponent','quotient_size','minimum_admissible_shifts','host_shift_evaluations')}|{'torsion_points':len(c['torsion']),'all_pairs':len(c['values'])} for c in d['extension']['cases']]}))


if __name__=='__main__':main()
