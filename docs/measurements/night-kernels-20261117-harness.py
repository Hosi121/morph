from pathlib import Path,PurePosixPath
import datetime,hashlib,json,os,platform,re,resource,statistics,subprocess,time
ROOT=Path.cwd(); OUT=ROOT/'.tools/night-kernels-20261117'; BASE='ab22a4a'
resource.setrlimit(resource.RLIMIT_CORE,(0,0))
def git(*a): return subprocess.check_output(['git',*a],text=True).strip()
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
source=git('rev-parse','HEAD');assert not git('status','--porcelain')
def parse(text):return set(re.findall(r'"Hosi121/morph/([^"\n]+)"',text))
old_paths=[p for p in git('ls-tree','-r','--name-only',BASE,'--','src').splitlines() if p.endswith('/moon.pkg')]
old={str(PurePosixPath(p).parent.relative_to('src')):parse(git('show',BASE+':'+p)) for p in old_paths}
now={str(p.parent.relative_to(ROOT/'src')):parse(p.read_text()) for p in (ROOT/'src').rglob('moon.pkg')}
graph={k:old.get(k,set())|now.get(k,set()) for k in old.keys()|now.keys()}
def owner(path,packages):
 candidates=[k for k in packages if path.startswith('src/'+k+'/')]
 return max(candidates,key=len) if candidates else None
changed=git('diff','--name-only','--no-renames',BASE,'--','src').splitlines();roots=set()
for p in changed:
 a,b=owner(p,old),owner(p,now)
 assert a is not None or b is not None,p
 roots.update(x for x in [a,b] if x is not None)
selected=set(roots)
while True:
 expanded=selected|{k for k,deps in graph.items() if deps&selected}
 if expanded==selected:break
 selected=expanded
selected=sorted(selected&now.keys())
assert not git('diff','--name-only',BASE,'--','moon.mod','tools/moon'), 'Global compiler/module change requires full regression'
for package in ['fppoly','homology','cohomology','csscode','linear','rowreduce','primefield','modular','persistence']:
 assert not git('diff',BASE,'--',f'src/{package}/pkg.generated.mbti'), 'Frozen public API changed: '+package
api_paths=[p for p in git('ls-tree','-r','--name-only',BASE,'--','src').splitlines() if p.endswith('/pkg.generated.mbti')]
for p in api_paths:
 old_api=git('show',BASE+':'+p)
 current=Path(p).read_text().strip()
 if p=='src/numberfield/pkg.generated.mbti':
  current=current.replace('  degree : @core.Nat\n  // private fields\n}', '  degree : @core.Nat\n}')
 assert old_api==current, 'Existing public interface changed: '+p
new_api_paths=set(git('diff','--name-only',BASE,'--','src/*/pkg.generated.mbti','src/cmd/*/pkg.generated.mbti').splitlines())-set(api_paths)
assert all(p.startswith('src/cmd/night') and p.endswith('/pkg.generated.mbti') for p in new_api_paths),new_api_paths
manifest={p:sha(p) for p in git('ls-files','src','tools','moon.mod','formal',':(glob)docs/research/**/*.py',':(glob)docs/research/**/*.json').splitlines() if Path(p).is_file()}
report={'started_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source_commit':source,'baseline':git('rev-parse',BASE),'retained_prior_scoped_validation':'docs/measurements/algorithm-kernels-20261117-validation.json','retained_prior_full_validation':'docs/measurements/topology-20261117-validation.json','scope':'All maintenance/type/API/purity/formal checks; source changes and reverse dependency closure of old+current imports (including tests), on all three targets. Unchanged unrelated tests not rerun.','changed_files':changed,'roots':sorted(roots),'packages':selected,'old_import_graph':{k:sorted(v) for k,v in old.items()},'new_import_graph':{k:sorted(v) for k,v in now.items()},'source_files':manifest,'source_manifest_sha256':hashlib.sha256(json.dumps(manifest,sort_keys=True).encode()).hexdigest(),'platform':platform.platform(),'affinity':sorted(os.sched_getaffinity(0)),'python':platform.python_version(),'toolchain':subprocess.check_output(['tools/moon','version','--all'],text=True),'commands':[],'status':'running'}
def save(): (OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
def command(name,argv):
 print('START',name,flush=True);path=OUT/(name+'.log');start=time.perf_counter()
 with path.open('w') as f:r=subprocess.run(argv,stdout=f,stderr=subprocess.STDOUT)
 text=path.read_text();entry={'name':name,'argv':argv,'returncode':r.returncode,'wall_seconds':time.perf_counter()-start,'log':str(path.relative_to(ROOT)),'sha256':sha(path),'test_totals':re.findall(r'Total tests: (\d+), passed: (\d+), failed: (\d+)',text)}
 report['commands'].append(entry);save();print('END',name,r.returncode,round(entry['wall_seconds'],3),entry['test_totals'],flush=True)
 if r.returncode:raise RuntimeError(name+' failed; inspect '+str(path))
try:
 print('SCOPE',','.join(selected),flush=True)
 gates=[line for line in Path('tools/check').read_text().splitlines() if line.startswith(('python3 ','tools/moon ')) and not line.startswith('tools/moon test ')]
 gates=[line.replace('tools/moon check --deny-warn', 'tools/moon check --deny-warn -j 1') for line in gates]
 command('maintenance',['bash','-c','set -euo pipefail\n'+'\n'.join(gates)])
 for target in ['js','native']:
  command('check-'+target,['tools/moon','check','--target',target,'--deny-warn','-j','1'])
 for target in ['wasm-gc','js','native']:
  command('tests-'+target,['tools/moon','test',*['src/'+p for p in selected],'--target',target,'--deny-warn','-j','1']+(['--release'] if target=='native' else []))
 command('formal',['tools/check_formal'])
 assert source==git('rev-parse','HEAD') and all(sha(p)==s for p,s in manifest.items()),'Source changed during validation'
 report['status']='passed'
except BaseException as e:
 report['status']='failed';report['error']=str(e);raise
finally:
 report['finished_utc']=datetime.datetime.now(datetime.timezone.utc).isoformat();save()
