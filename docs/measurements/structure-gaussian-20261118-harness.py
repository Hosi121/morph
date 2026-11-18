from pathlib import Path
from fractions import Fraction as Q
import argparse,gzip,hashlib,io,json,os,re,shutil,statistics,subprocess,tarfile,time
CASES={'diag2':(2,True,50),'dense3':(3,False,20),'dense6':(6,False,5)}
def sha(data):return hashlib.sha256(data).hexdigest()
def inverse(a):
    n=len(a);r=[row[:]+[Q(i==j) for j in range(n)] for i,row in enumerate(a)]
    for k in range(n):
        pivot=next(i for i in range(k,n) if r[i][k]);r[k],r[pivot]=r[pivot],r[k]
        divisor=r[k][k];r[k]=[x/divisor for x in r[k]]
        for i in range(n):
            if i!=k:
                factor=r[i][k];r[i]=[x-factor*y for x,y in zip(r[i],r[k])]
    return [row[n:] for row in r]
def encode(v):
    if isinstance(v,Q):return [v<0,format(abs(v.numerator),'x'),format(v.denominator,'x')]
    if isinstance(v,list):return [encode(x) for x in v]
    if isinstance(v,dict):return {k:encode(x) for k,x in v.items()}
    return v
def expected(case):
    n,diagonal,iterations=CASES[case];mean=[Q(i+1,i+2) for i in range(n)];inputs=[]
    for shift in range(3):
        matrix=[[Q((i+2+shift if i==j else 0)+(0 if diagonal else sum(((k+2*i)%5-2)*((k+2*j)%5-2) for k in range(n))),3) for j in range(n)] for i in range(n)]
        inputs.append({'mean':mean,'covariance':matrix,'precision':inverse(matrix)})
    return encode({'case':case,'iterations':iterations,'results':[inputs[i%3] for i in range(iterations)]})
def snapshot(tree,output):
    files={'moon.mod':(tree/'moon.mod').read_bytes(),'tools/moon':(tree/'tools/moon').read_bytes()};todo=['cmd/structurebench'];seen=set()
    while todo:
        package=todo.pop()
        if package in seen:continue
        seen.add(package);directory=tree/'src'/package
        pkg=directory/'moon.pkg';files[str(pkg.relative_to(tree))]=pkg.read_bytes()
        for body,suffix in re.findall(r'import\s*\{(.*?)\}([^\n]*)',pkg.read_text(),re.S):
            if not suffix.strip().startswith('for'):
                todo.extend(re.findall(r'"Hosi121/morph/([^"\n]+)"',body))
        for path in directory.glob('*.mbt'):
            if not path.name.endswith(('_test.mbt','_wbtest.mbt')):files[str(path.relative_to(tree))]=path.read_bytes()
    raw=io.BytesIO()
    with tarfile.open(fileobj=raw,mode='w') as tar:
        for name,data in sorted(files.items()):
            info=tarfile.TarInfo(name);info.size=len(data);info.mode=0o755 if name=='tools/moon' else 0o644;tar.addfile(info,io.BytesIO(data))
    output.write_bytes(gzip.compress(raw.getvalue(),mtime=0))
    return {'path':str(output),'sha256':sha(output.read_bytes()),'files':{k:sha(v) for k,v in sorted(files.items())},'commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=tree,text=True).strip(),'packages':sorted(seen)}
def summary(runs):
    result={}
    for case in CASES:
        rows=[r for r in runs if r['case']==case];sides={v:[r['process_ns'] for r in rows if r['variant']==v] for v in ('before','after')}
        med={v:statistics.median(values) for v,values in sides.items()};ratios=[]
        for group in range(5):
            block={v:statistics.median(r['process_ns'] for r in rows if r['group']==group and r['variant']==v) for v in sides};ratios.append(block['before']/block['after'])
        result[case]={'process_ns':{'medians':med,'ranges':{v:[min(xs),max(xs)] for v,xs in sides.items()},'before_over_after':med['before']/med['after'],'block_ratios':ratios}}
    return result

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--baseline-tree',type=Path,required=True);args=parser.parse_args();root=Path.cwd();scratch=root/'.tools/structure-modeling';public=root/'docs/measurements';public.mkdir(exist_ok=True)
    roots={'before':args.baseline_tree.resolve(),'after':root};frozen={};source={}
    for side,tree in roots.items():
        exe=tree/'_build/native/release/build/cmd/structurebench/structurebench.exe';target=scratch/(side+'-gaussian.exe');shutil.copyfile(exe,target);target.chmod(0o755);frozen[side]={'path':str(target),'sha256':sha(target.read_bytes())}
        shutil.copyfile(exe.with_suffix('.c'),scratch/(side+'-gaussian.c'))
        source[side]=snapshot(tree,public/('structure-gaussian-20261118-'+side+'-source.tar.gz'));source[side]['path']=str(Path(source[side]['path']).relative_to(root))
    for name in ('main.mbt','moon.pkg'):assert (roots['before']/'src/cmd/structurebench'/name).read_bytes()==(root/'src/cmd/structurebench'/name).read_bytes()
    rows=[];expectations={case:expected(case) for case in CASES}
    for case in CASES:
        for group in range(5):
            for position,side in enumerate(['before','after','after','before']):
                argv=[frozen[side]['path'],case];start=time.perf_counter_ns();p=subprocess.run(argv,text=True,capture_output=True);elapsed=time.perf_counter_ns()-start
                assert p.returncode==0,(case,p.returncode,p.stderr)
                payload=json.loads(p.stdout);assert payload==expectations[case],case
                rows.append({'case':case,'group':group,'position':position,'variant':side,'process_ns':elapsed,'checked':True,'exit_code':p.returncode,'stdout':p.stdout,'stderr':p.stderr,'payload':payload,'argv':argv})
        print('checked',case,flush=True)
    assert all(sha(Path(v['path']).read_bytes())==v['sha256'] for v in frozen.values())
    harness=public/'structure-gaussian-20261118-harness.py';shutil.copyfile(__file__,harness)
    record={'schema_kind':'positive-form-gaussian-v1','all_checked':True,'groups':5,'order':['before','after','after','before'],'timing':'Full native process including common input construction and complete JSON; release, CPU4, serial lock.','affinity':sorted(os.sched_getaffinity(0)),'source_archives':source,'frozen_elf':frozen,'harness_path':str(harness.relative_to(root)),'harness_sha256':sha(harness.read_bytes()),'compiler':subprocess.check_output(['tools/moon','version','--all'],text=True),'reference':'Independent stdlib Fraction Gauss-Jordan, every mean/covariance/precision component for every repetition.','reference_payloads':expectations,'runs':rows,'summary':summary(rows)}
    raw=(json.dumps(record,indent=2)+'\n').encode();path=public/'structure-gaussian-20261118.json.gz';path.write_bytes(gzip.compress(raw,mtime=0));short={k:v for k,v in record.items() if k!='runs'};short.update(run_count=len(rows),lossless_full_record={'path':str(path.relative_to(root)),'sha256':sha(path.read_bytes()),'uncompressed_sha256':sha(raw)})
    (public/'structure-gaussian-20261118-summary.json').write_text(json.dumps(short,indent=2)+'\n')
    print(json.dumps(record['summary'],indent=2))
if __name__=='__main__':main()
