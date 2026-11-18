from pathlib import Path
from fractions import Fraction as Q
import argparse,gzip,hashlib,io,json,os,re,shutil,statistics,subprocess,tarfile,time
CASES={'scalar1':20,'scalar2':2,'full2':1,'action2':2}
def sha(data):return hashlib.sha256(data).hexdigest()
def encode(v):
    if isinstance(v,Q):return [v<0,format(abs(v.numerator),'x'),format(v.denominator,'x')]
    if isinstance(v,list):return [encode(x) for x in v]
    if isinstance(v,dict):return {k:encode(x) for k,x in v.items()}
    return v
def snapshot(tree,output):
    files={'moon.mod':(tree/'moon.mod').read_bytes(),'tools/moon':(tree/'tools/moon').read_bytes()};todo=['cmd/hessianbench'];seen=set()
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


# Versioned independent references: raw Gaussian moments by double factorials;
# generic Christoffel derivatives from a metric two-jet, not the new commutator.
import importlib.util,sys
_MODELS=None
def load_reference(path,name):
    spec=importlib.util.spec_from_file_location(name,path);module=importlib.util.module_from_spec(spec);sys.modules[name]=module;spec.loader.exec_module(module);return module

def expected(case,reference_dir=None):
    global _MODELS
    if _MODELS is None:
        reference_dir=reference_dir or Path.cwd()/'docs/measurements'
        gaussian=load_reference(reference_dir/'structure-hessian-20261118-moments-reference.py','hessian_moment_reference')
        geometry=load_reference(reference_dir/'structure-hessian-20261118-curvature-reference.py','hessian_curvature_reference')
        data=gaussian.gaussian_expected();_MODELS={}
        for n,indices in ((1,[0,2]),(2,list(range(5)))):
            g=[[data['metric'][i][j] for j in indices] for i in indices]
            d=[[[data['first'][k][i][j] for j in indices] for i in indices] for k in indices]
            h=[[[[data['second'][k][l][i][j] for j in indices] for i in indices] for l in indices] for k in indices]
            _MODELS[n]=(g,geometry.geometry(g,d,h))
        assert _MODELS[1][1]['scalar']==Q(-1)
        assert _MODELS[2][1]['scalar']==Q(-9,2)
    g,result=_MODELS[1 if case=='scalar1' else 2]
    if case.startswith('scalar'):value={'metric':g,'scalar':result['scalar']}
    elif case=='action2':
        action=[result['upper'][r][0][0][2] for r in range(5)]
        assert action==[Q(0),Q(0),Q(1,2),Q(0),Q(0)]
        value={'metric':g,'action':action}
    else:
        flat=[result['upper'][i][j][k][l] for i in range(5) for j in range(5) for k in range(5) for l in range(5)]
        value={'metric':g,'riemann':flat,'ricci':result['ricci'],'scalar':result['scalar']}
    return encode({'case':case,'iterations':CASES[case],'results':[value]*CASES[case]})

def main():
    root=Path.cwd();scratch=root/'.tools/structure-modeling';public=root/'docs/measurements'
    reference_files={}
    for original,name in [('tools/benchmark_information.py','moments'),('tools/generate_riemann_fixtures.py','curvature')]:
        target=public/('structure-hessian-20261118-'+name+'-reference.py');shutil.copyfile(original,target)
        reference_files[str(target.relative_to(root))]=sha(target.read_bytes())
    source=snapshot(root,public/'structure-hessian-20261118-source.tar.gz');source['path']=str(Path(source['path']).relative_to(root))
    original=root/'_build/native/release/build/cmd/hessianbench/hessianbench.exe';exe=scratch/'hessian-comparison.exe';shutil.copyfile(original,exe);exe.chmod(0o755);shutil.copyfile(original.with_suffix('.c'),scratch/'hessian-comparison.c');frozen=sha(exe.read_bytes())
    rows=[];expectations={case:expected(case) for case in CASES}
    for case in CASES:
        for group in range(5):
            for position,side in enumerate(['before','after','after','before']):
                route='general' if side=='before' else 'structured';argv=[str(exe),route,case]
                start=time.perf_counter_ns();p=subprocess.run(argv,text=True,capture_output=True);elapsed=time.perf_counter_ns()-start
                assert p.returncode==0,(case,p.returncode,p.stderr)
                payload=json.loads(p.stdout);assert payload==expectations[case],(case,side)
                rows.append({'case':case,'group':group,'position':position,'variant':side,'process_ns':elapsed,'checked':True,'exit_code':p.returncode,'stdout':p.stdout,'stderr':p.stderr,'payload':payload,'argv':argv})
        print('checked',case,flush=True)
    assert sha(exe.read_bytes())==frozen
    harness=public/'structure-hessian-20261118-harness.py';shutil.copyfile(__file__,harness)
    record={'schema_kind':'hessian-derived-geometry-v1','all_checked':True,'groups':5,'order':['before','after','after','before'],'timing':'Full native process including common source construction, preparation and complete JSON; release, CPU4, serial lock.','affinity':sorted(os.sched_getaffinity(0)),'source_archives':{'shared':source},'frozen_elf':{'shared':{'path':str(exe),'sha256':frozen}},'routes':{'before':'general metric two-jet, fourth cumulants and rank-four curvature','after':'provenance-preserving Hessian point; operator and contracted invariants'},'harness_path':str(harness.relative_to(root)),'harness_sha256':sha(harness.read_bytes()),'reference_files':reference_files,'compiler':subprocess.check_output(['tools/moon','version','--all'],text=True),'reference':'Independent double-factorial moments through order eight, generic metric-two-jet Christoffel derivatives; every requested output component for every repetition.','reference_payloads':expectations,'runs':rows,'summary':summary(rows)}
    raw=(json.dumps(record,indent=2)+'\n').encode();path=public/'structure-hessian-20261118.json.gz';path.write_bytes(gzip.compress(raw,mtime=0));short={k:v for k,v in record.items() if k!='runs'};short.update(run_count=len(rows),lossless_full_record={'path':str(path.relative_to(root)),'sha256':sha(path.read_bytes()),'uncompressed_sha256':sha(raw)})
    (public/'structure-hessian-20261118-summary.json').write_text(json.dumps(short,indent=2)+'\n')
    print(json.dumps(record['summary'],indent=2))
if __name__=='__main__':main()
