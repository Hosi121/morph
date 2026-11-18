#!/usr/bin/env python3
"""ABBA native CLI comparison with complete independent Fraction output checks.

Run under tools/measure --cpu 4. Source and compiler freezing is the caller's job;
this script records ELF hashes, all checked results and complete process timings.
"""
from collections import defaultdict
from fractions import Fraction as Q
from itertools import product
from pathlib import Path
import argparse
import hashlib
import json
import math
import statistics
import subprocess
import time

CASES = {'lc-simplex2':200,'alpha-simplex2':200,'cubic-pullback3':150,'gaussian2':10,'scalar0':1000}


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def decode(value):
    if isinstance(value,list):
        if len(value)==3 and isinstance(value[0],bool) and all(isinstance(s,str) for s in value[1:]):
            sign,n,d=value
            assert n and d, 'Empty numeric hex is not a complete integer'
            assert n==format(int(n,16),'x') and d==format(int(d,16),'x'), 'Noncanonical numeric hex'
            n,d=int(n,16),int(d,16)
            assert d>0 and math.gcd(n,d)==1 and not (sign and n==0)
            return Q(-n if sign else n,d)
        return [decode(item) for item in value]
    if isinstance(value,dict):
        return {key:decode(item) for key,item in value.items()}
    return value


def simplex_curvature(alpha,contracted=False):
    g=[[Q(6),Q(2)],[Q(2),Q(6)]]
    k=(1-alpha*alpha)/4
    r=[k*(g[i][a]*g[j][b]-g[i][b]*g[j][a]) for i,j,a,b in product(range(2),repeat=4)]
    result={'metric':g,'lower_riemann':r,'ricci':[[k*x for x in row] for row in g],'scalar':2*k}
    if contracted:
        result['contracted']=2*k
    else:
        inverse=[[Q(3,16),Q(-1,16)],[Q(-1,16),Q(3,16)]]
        cubic=lambda i,j,k: Q(12) if i==j==k else Q(-4)
        result['coefficients']=[sum((inverse[r][s]*(-(1+alpha)/2)*cubic(i,j,s) for s in range(2)),Q(0))
                                for i,j,r in product(range(2),repeat=3)]
    return result


def polynomial_product(a,b):
    result=defaultdict(Q)
    for i,x in a.items():
        for j,y in b.items():
            result[tuple(u+v for u,v in zip(i,j))]+=x*y
    return {key:value for key,value in result.items() if value}


def standard_moment(powers):
    value=1
    for power in powers:
        if power%2:
            return Q(0)
        value*=math.prod(range(1,power,2))
    return Q(value)


def gaussian_expected():
    # Independent standard coordinates: E[X^a Y^b] is a product of double factorials.
    stats=[{(1,0):Q(1)},{(0,1):Q(1)},{(2,0):Q(1)},{(1,1):Q(1)},{(0,2):Q(1)}]
    mean=lambda p:sum((value*standard_moment(key) for key,value in p.items()),Q(0))
    centered=[]
    for p in stats:
        p=dict(p)
        p[(0,0)]=-mean(p)
        centered.append({k:v for k,v in p.items() if v})
    moments={}
    def joint(indices):
        key=tuple(sorted(indices))
        if key not in moments:
            p={(0,0):Q(1)}
            for i in key:
                p=polynomial_product(p,centered[i])
            moments[key]=mean(p)
        return moments[key]
    g=[[joint((i,j)) for j in range(5)] for i in range(5)]
    first=[[[joint((k,i,j)) for j in range(5)] for i in range(5)] for k in range(5)]
    second=[[[[joint((k,l,i,j))-g[k][l]*g[i][j]-g[k][i]*g[l][j]-g[k][j]*g[l][i]
               for j in range(5)] for i in range(5)] for l in range(5)] for k in range(5)]
    return {'metric':g,'first':first,'second':second}


def expected_outputs():
    j=[[Q(1),Q(1,3),Q(0)],[Q(0),Q(1),Q(1,2)],[Q(1,4),Q(0),Q(1)]]
    t=lambda a,b,c: Q(75,4) if a==b==c else Q(-25,4)
    pullback=[sum((t(a,b,c)*j[a][i]*j[b][k]*j[c][l] for a,b,c in product(range(3),repeat=3)),Q(0))
              for i,k,l in product(range(3),repeat=3)]
    return {'lc-simplex2':simplex_curvature(Q(0),True),
            'alpha-simplex2':simplex_curvature(Q(2)),
            'cubic-pullback3':pullback,'gaussian2':gaussian_expected(),
            'scalar0':{'metric':[],'lower_riemann':[],'ricci':[],'scalar':Q(0),'contracted':Q(0)}}


def summarize(rows):
    summary={}
    for name in CASES:
        chosen=[row for row in rows if row['case']==name]
        b=[row['wall_seconds'] for row in chosen if row['side']=='baseline']
        c=[row['wall_seconds'] for row in chosen if row['side']=='candidate']
        ratios=[]
        for block in sorted({row['block'] for row in chosen}):
            group=[row for row in chosen if row['block']==block]
            ratios.append(statistics.mean(row['wall_seconds'] for row in group if row['side']=='baseline')/
                          statistics.mean(row['wall_seconds'] for row in group if row['side']=='candidate'))
        summary[name]={'baseline_median_seconds':statistics.median(b),'candidate_median_seconds':statistics.median(c),
                       'median_ratio':statistics.median(b)/statistics.median(c),'block_ratios':ratios,
                       'positive_blocks':sum(r>1 for r in ratios),'samples_each':len(b)}
    return summary


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline',required=True,type=Path)
    parser.add_argument('--candidate',required=True,type=Path)
    parser.add_argument('--output',required=True,type=Path)
    parser.add_argument('--blocks',type=int,default=5)
    args=parser.parse_args()
    if not 1<=args.blocks<=10:
        parser.error('blocks must be between one and ten')
    expected=expected_outputs()
    frozen={name:sha(path) for name,path in [('baseline',args.baseline),('candidate',args.candidate)]}
    rows=[]
    for case,iterations in CASES.items():
        for block in range(args.blocks):
            for slot,side in enumerate(['baseline','candidate','candidate','baseline']):
                path=getattr(args,side)
                start=time.perf_counter()
                run=subprocess.run([str(path),'--benchmark',case],capture_output=True,text=True,check=True)
                wall=time.perf_counter()-start
                result=json.loads(run.stdout)
                assert result['case']==case and result['iterations']==iterations
                assert decode(result['result'])==expected[case],case
                rows.append({'case':case,'block':block,'slot':slot,'side':side,'wall_seconds':wall,
                             'full_checked':True,'stdout':run.stdout,'stderr':run.stderr})
        print('checked',case,flush=True)
    assert frozen=={name:sha(path) for name,path in [('baseline',args.baseline),('candidate',args.candidate)]}
    record={'schema':1,'script_sha256':sha(__file__),'elf_sha256':frozen,'timing':'full native process including validation and JSON serialization',
            'oracle':'complete independent Fraction values, closed simplex curvature/cubic and independent standard Gaussian double factorials',
            'blocks':args.blocks,'rows':rows,'summary':summarize(rows)}
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(record['summary'],indent=2))


if __name__=='__main__':
    main()
