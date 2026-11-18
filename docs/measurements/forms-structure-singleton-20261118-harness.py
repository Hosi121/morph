from pathlib import Path
from fractions import Fraction as Q
import argparse,gzip,hashlib,io,json,os,re,shutil,statistics,subprocess,tarfile,time
CASES={'overlap':20,'disjoint':10,'mixed':3,'closed-d':100,'closed-primitive':10}
def sha(data):return hashlib.sha256(data).hexdigest()
def encode(v):
    if isinstance(v,Q):return [v<0,format(abs(v.numerator),'x'),format(v.denominator,'x')]
    if isinstance(v,list):return [encode(x) for x in v]
    if isinstance(v,dict):return {k:encode(x) for k,x in v.items()}
    return v
def snapshot(tree,output):
    files={'moon.mod':(tree/'moon.mod').read_bytes(),'tools/moon':(tree/'tools/moon').read_bytes()};todo=['cmd/formsbench'];seen=set()
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



import importlib.util,sys
_ORACLE=None
STEM='forms-structure-singleton-20261118'
def expected(case,reference_dir=None):
    global _ORACLE
    if _ORACLE is None:
        path=(reference_dir or Path(__file__).resolve().parent)/(STEM+'-forms-reference.py')
        spec=importlib.util.spec_from_file_location('_forms_structure_oracle',path)
        _ORACLE=importlib.util.module_from_spec(spec);sys.modules[spec.name]=_ORACLE;spec.loader.exec_module(_ORACLE)
    o=_ORACLE
    def coefficient(n,shift):
        terms=[]
        for t in range(8):
            e=[0]*n;e[(t+shift)%n]=1+t//n
            terms.append((Q(t+1+shift,1+t%3),e))
        return o.poly(terms)
    def form(n,bases,shift):return {tuple(b):coefficient(n,shift+i) for i,b in enumerate(bases)}
    if case=='overlap':n,k,value=4,4,o.wedge(form(4,[[0,2]],0),form(4,[[1,2]],1))
    elif case=='disjoint':n,k,value=4,4,o.wedge(form(4,[[1,3]],0),form(4,[[0,2]],1))
    elif case=='mixed':
        bases=[[0,1],[0,2],[0,3],[1,2],[1,3],[2,3]]
        n,k,value=4,4,o.wedge(form(4,bases,0),form(4,bases,1))
    elif case=='closed-d':n,k,value=4,2,o.exterior(o.exterior({():coefficient(4,0)},4),4)
    else:n,k,value=3,2,o.homotopy_integral(form(3,[[0,1,2]],0),3,3)
    result={'variables':n,'degree':k,'terms':[{'indices':list(indices),'coefficient':[[q,list(e)] for e,q in sorted(p.items(),reverse=True)]} for indices,p in sorted(value.items())]}
    return encode({'case':case,'iterations':CASES[case],'results':[result]*CASES[case]})

def verify_legacy(root,scratch):
    old=(scratch/'legacy-exterior.mbt').read_text()
    current=(root/'src/forms/exterior.mbt').read_text()
    assert old.split('pub fn exterior_derivative',1)[1]==current.split('pub fn exterior_derivative',1)[1]
    source=old.split('///|\npub fn exterior_derivative',1)[0].replace('pub fn wedge','fn legacy_wedge')
    for name in ['FormError','Form','Term']:source=re.sub(r'\b'+name+r'\b','@forms.'+name,source)
    for obj,field in [('a','variables'),('b','variables'),('a','degree'),('b','degree'),('a','terms'),('b','terms')]:source=source.replace(obj+'.'+field,'@forms.'+field+'('+obj+')')
    source=re.sub(r'(?<![\w.])form\(', '@forms.form(',source)
    formatted=subprocess.run([str(root/'.tools/moon/bin/moonfmt'),'-'],input=source,text=True,capture_output=True,check=True).stdout
    assert formatted==(root/'src/cmd/formsbench/legacy.mbt').read_text()

def main():
    root=Path.cwd();scratch=root/'.tools/forms-structure';public=root/'docs/measurements'
    verify_legacy(root,scratch)
    refs={}
    for origin,suffix in [(root/'tools/generate_forms_fixtures.py','forms-reference.py'),(scratch/'legacy-exterior.mbt','legacy-exterior.mbt')]:
        target=public/(STEM+'-'+suffix);shutil.copyfile(origin,target);refs[str(target.relative_to(root))]=sha(target.read_bytes())
    source=snapshot(root,public/(STEM+'-source.tar.gz'));source['path']=str(Path(source['path']).relative_to(root))
    original=root/'_build/native/release/build/cmd/formsbench/formsbench.exe';exe=scratch/'singleton-comparison.exe';shutil.copyfile(original,exe);exe.chmod(0o755);shutil.copyfile(original.with_suffix('.c'),scratch/'singleton-comparison.c');frozen=sha(exe.read_bytes())
    rows=[];expectations={case:expected(case,public) for case in CASES}
    for case in CASES:
        for group in range(5):
            for position,side in enumerate(['before','after','after','before']):
                route='general' if side=='before' else 'structured';argv=[str(exe),route,case]
                start=time.perf_counter_ns();p=subprocess.run(argv,text=True,capture_output=True);elapsed=time.perf_counter_ns()-start
                assert p.returncode==0,(case,route,p.returncode,p.stderr)
                payload=json.loads(p.stdout);assert payload==expectations[case],(case,route,payload,expectations[case])
                rows.append({'case':case,'group':group,'position':position,'variant':side,'process_ns':elapsed,'checked':True,'exit_code':p.returncode,'stdout':p.stdout,'stderr':p.stderr,'payload':payload,'argv':argv})
        print('checked',case,flush=True)
    assert sha(exe.read_bytes())==frozen
    harness=public/(STEM+'-harness.py');shutil.copyfile(__file__,harness)
    record={'schema_kind':'exterior-structure-v1','all_checked':True,'groups':5,'order':['before','after','after','before'],'timing':'Full native process including identical input/witness preparation and complete JSON; release, CPU4, serial lock.','affinity':sorted(os.sched_getaffinity(0)),'source_archives':{'shared':source},'frozen_elf':{'shared':{'path':str(exe),'sha256':frozen}},'legacy_source_commit':'00b8ed2dd21f99d9e43d8fd38ff5b4a5bfffd61c','routes':{'before':'Original wedge algorithm adapted only to public field accessors; ordinary exterior_derivative and checked primitive.','after':'Merged canonical exterior bases and closedness/primitive-preserving ADTs.'},'harness_path':str(harness.relative_to(root)),'harness_sha256':sha(harness.read_bytes()),'reference_files':refs,'compiler':subprocess.check_output(['tools/moon','version','--all'],text=True),'reference':'Independent Fraction sparse dictionaries and permutation inversions; radial homotopy by determinant pullback F(t,x)=tx and t-integration. Every full output and repetition.','reference_payloads':expectations,'runs':rows,'summary':summary(rows)}
    raw=(json.dumps(record,indent=2)+'\n').encode();path=public/(STEM+'.json.gz');path.write_bytes(gzip.compress(raw,mtime=0));short={k:v for k,v in record.items() if k!='runs'};short.update(run_count=len(rows),lossless_full_record={'path':str(path.relative_to(root)),'sha256':sha(path.read_bytes()),'uncompressed_sha256':sha(raw)})
    (public/(STEM+'-summary.json')).write_text(json.dumps(short,indent=2)+'\n')
    print(json.dumps(record['summary'],indent=2))
if __name__=='__main__':main()
