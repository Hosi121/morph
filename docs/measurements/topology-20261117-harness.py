from pathlib import Path
import datetime,hashlib,json,os,platform,re,resource,subprocess,time
ROOT=Path.cwd(); OUT=ROOT/'.tools/topology-20261117'; OUT.mkdir(exist_ok=True)
resource.setrlimit(resource.RLIMIT_CORE,(0,0))
def sha(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def git(*args):return subprocess.check_output(['git',*args],text=True).strip()
source=git('rev-parse','HEAD')
assert not git('status','--porcelain'), 'freeze source before full validation'
manifest={p:sha(p) for p in git('ls-files','src','tools','moon.mod','formal').splitlines() if Path(p).is_file()}
report={'started_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source_commit':source,'source_manifest_sha256':hashlib.sha256(json.dumps(manifest,sort_keys=True).encode()).hexdigest(),'source_files':manifest,'platform':platform.platform(),'affinity':sorted(os.sched_getaffinity(0)),'python':platform.python_version(),'commands':[],'tour_cases':[],'native_process_trials':[],'status':'running'}
def save(): (OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
def command(name,argv):
 print('START',name,flush=True); path=OUT/(name+'.log'); start=time.perf_counter()
 with path.open('w') as log:r=subprocess.run(argv,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT)
 entry={'name':name,'argv':argv,'returncode':r.returncode,'wall_seconds':time.perf_counter()-start,'log':str(path.relative_to(ROOT)),'sha256':sha(path)}
 text=path.read_text(); entry['test_totals']=re.findall(r'Total tests: (\d+), passed: (\d+), failed: (\d+)',text)
 report['commands'].append(entry);save();print('END',name,r.returncode,round(entry['wall_seconds'],3),entry['test_totals'],flush=True)
 if r.returncode:raise RuntimeError(name+' failed; inspect '+str(path))
try:
 command('check',['tools/check'])
 command('native-release',['tools/moon','test','--target','native','--release','--deny-warn','-j','1'])
 command('formal',['tools/check_formal'])
 expected=(ROOT/'docs/TOPOLOGY_TOUR.txt').read_text();lines=expected.splitlines(keepends=True)
 sections={'all':expected,'rips':''.join(lines[:3]),'maps':''.join(lines[3:5]),'codes':''.join(lines[5:])}
 for target in ['js','wasm-gc','native']:
  for suffix,mode in [([], 'all'),(['all'],'all'),(['rips'],'rips'),(['maps'],'maps'),(['codes'],'codes'),(['invalid'],None),(['maps','extra'],None)]:
   argv=['tools/moon','run','src/cmd/topology','--target',target,'--release','--deny-warn','-j','1']+(['--',*suffix] if suffix else [])
   start=time.perf_counter();r=subprocess.run(argv,capture_output=True,text=True)
   okay=(r.returncode==0 and r.stdout==sections[mode]) if mode else (r.returncode!=0 and ('expected ' in r.stderr or (target=='wasm-gc' and 'unreachable' in r.stderr)))
   report['tour_cases'].append({'target':target,'argv':argv,'returncode':r.returncode,'wall_seconds':time.perf_counter()-start,'stdout':r.stdout,'stderr':r.stderr,'passed':okay});save()
   if not okay:raise RuntimeError('tour mismatch '+str(argv))
  print('TOUR',target,'7 cases pass',flush=True)
 artifact=ROOT/'_build/native/release/build/cmd/topology/topology.exe'
 report['native_artifact']={'path':str(artifact.relative_to(ROOT)),'sha256':sha(artifact),'scope':'process startup + input construction + algorithm + runtime witness checks + output; excludes compilation','repetitions':3}
 for mode in ['rips','maps','codes','all']:
  for trial in range(3):
   start=time.perf_counter_ns();r=subprocess.run([str(artifact),mode],capture_output=True,text=True);elapsed=time.perf_counter_ns()-start
   assert r.returncode==0 and r.stdout==sections[mode],mode
   report['native_process_trials'].append({'mode':mode,'trial':trial,'elapsed_ns':elapsed,'stdout':r.stdout,'stderr':r.stderr,'returncode':r.returncode})
  print('BENCH',mode,[round(x['elapsed_ns']/1e6,3) for x in report['native_process_trials'] if x['mode']==mode],flush=True)
 assert source==git('rev-parse','HEAD') and manifest=={p:sha(p) for p in manifest}, 'source changed during validation'
 report['status']='passed'
except BaseException as error:
 report['status']='failed';report['error']=str(error);raise
finally:
 report['finished_utc']=datetime.datetime.now(datetime.timezone.utc).isoformat();save()
