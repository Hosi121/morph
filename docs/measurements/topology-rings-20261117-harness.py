from pathlib import Path,PurePosixPath
import datetime,hashlib,json,os,platform,re,resource,statistics,subprocess,time
ROOT=Path.cwd(); OUT=ROOT/'.tools/topology-rings-20261117'; BASE='8997862'
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
assert not git('diff',BASE,'--','src/homology/pkg.generated.mbti'), 'Frozen homology public API changed'
manifest={p:sha(p) for p in git('ls-files','src','tools','moon.mod','formal').splitlines() if Path(p).is_file()}
report={'started_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source_commit':source,'baseline':git('rev-parse',BASE),'retained_full_baseline':'docs/measurements/topology-20261117-validation.json','scope':'All maintenance/type/API/purity/formal checks; source changes and reverse dependency closure of old+current imports (including tests), on all three targets. Unchanged unrelated tests not rerun.','changed_files':changed,'roots':sorted(roots),'packages':selected,'old_import_graph':{k:sorted(v) for k,v in old.items()},'new_import_graph':{k:sorted(v) for k,v in now.items()},'source_files':manifest,'source_manifest_sha256':hashlib.sha256(json.dumps(manifest,sort_keys=True).encode()).hexdigest(),'platform':platform.platform(),'affinity':sorted(os.sched_getaffinity(0)),'python':platform.python_version(),'toolchain':subprocess.check_output(['tools/moon','version','--all'],text=True),'commands':[],'tour_cases':[],'native_process_trials':[],'status':'running'}
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
 command('maintenance',['bash','-c','set -euo pipefail\n'+'\n'.join(gates)])
 for target in ['wasm-gc','js','native']:
  command('tests-'+target,['tools/moon','test',*['src/'+p for p in selected],'--target',target,'--deny-warn','-j','1']+(['--release'] if target=='native' else []))
 command('formal',['tools/check_formal'])
 expected=Path('docs/TOPOLOGY_RINGS_TOUR.txt').read_text();lines=expected.splitlines(keepends=True)
 sections={'all':expected,'rings':''.join(lines[:3]),'relative':''.join(lines[3:5]),'collapse':''.join(lines[5:])}
 for target in ['js','wasm-gc','native']:
  for suffix,mode in [([], 'all'),(['all'],'all'),(['rings'],'rings'),(['relative'],'relative'),(['collapse'],'collapse'),(['invalid'],None),(['rings','extra'],None)]:
   argv=['tools/moon','run','src/cmd/topologyrings','--target',target,'--release','--deny-warn','-j','1']+(['--',*suffix] if suffix else [])
   start=time.perf_counter();r=subprocess.run(argv,capture_output=True,text=True)
   okay=(r.returncode==0 and r.stdout==sections[mode]) if mode else (r.returncode!=0 and ('expected ' in r.stderr or (target=='wasm-gc' and 'unreachable' in r.stderr)))
   report['tour_cases'].append({'target':target,'argv':argv,'returncode':r.returncode,'wall_seconds':time.perf_counter()-start,'stdout':r.stdout,'stderr':r.stderr,'passed':okay});save()
   if not okay:raise RuntimeError('tour mismatch '+str(argv))
  print('TOUR',target,'7 cases pass',flush=True)
 artifact=ROOT/'_build/native/release/build/cmd/topologyrings/topologyrings.exe'
 report['native_artifact']={'path':str(artifact.relative_to(ROOT)),'sha256':sha(artifact),'scope':'process startup + input construction + algorithm + runtime witness checks + output; excludes compilation','repetitions':3}
 for mode in ['rings','relative','collapse','all']:
  for trial in range(3):
   start=time.perf_counter_ns();r=subprocess.run([str(artifact),mode],capture_output=True,text=True);elapsed=time.perf_counter_ns()-start
   assert r.returncode==0 and r.stdout==sections[mode],mode
   report['native_process_trials'].append({'mode':mode,'trial':trial,'elapsed_ns':elapsed,'stdout':r.stdout,'stderr':r.stderr,'returncode':r.returncode})
  print('BENCH',mode,[round(v['elapsed_ns']/1e6,3) for v in report['native_process_trials'] if v['mode']==mode],flush=True)
 assert source==git('rev-parse','HEAD') and all(sha(p)==s for p,s in manifest.items()),'Source changed during validation'
 report['status']='passed'
except BaseException as e:
 report['status']='failed';report['error']=str(e);raise
finally:
 report['finished_utc']=datetime.datetime.now(datetime.timezone.utc).isoformat();save()
