from pathlib import Path
import datetime,hashlib,json,os,platform,re,resource,shutil,subprocess,time
ROOT=Path.cwd();OUT=ROOT/'.tools/field-optimization-20261117'
resource.setrlimit(resource.RLIMIT_CORE,(0,0))
def git(*a):return subprocess.check_output(['git',*a],text=True).strip()
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
p=OUT/'validation.json';report=json.loads(p.read_text())
assert report['status']=='running'
assert report['source_commit']==git('rev-parse','HEAD') and not git('status','--porcelain')
assert all(sha(path)==h for path,h in report['source_files'].items())
assert [x['name'] for x in report['commands']]==['maintenance','tests-wasm-gc','tests-js']
assert all(x['returncode']==0 and sha(ROOT/x['log'])==x['sha256'] for x in report['commands'])
for x in report['commands'][1:]:assert x['test_totals']==[['3545','3545','0']]
shutil.copy2(p,OUT/'validation-interrupted.json')
report['resumptions']=[{'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'reason':'Previous execution session and its process no longer exist; log stops at START tests-native without a result. Preserve completed results and resume remaining commands only.','source_and_previous_log_hashes_verified':True,'platform':platform.platform(),'affinity':sorted(os.sched_getaffinity(0)),'toolchain':subprocess.check_output(['tools/moon','version','--all'],text=True),'interrupted_native_log_sha256':sha(OUT/'tests-native.log'),'resume_harness':str(Path(__file__).relative_to(ROOT)),'resume_harness_sha256':sha(__file__)}]
def save():p.write_text(json.dumps(report,indent=2)+'\n')
def command(name,argv):
 print('START',name,flush=True);log=OUT/(name+'.log');start=time.perf_counter()
 with log.open('w') as f:result=subprocess.run(argv,stdout=f,stderr=subprocess.STDOUT)
 entry={'name':name,'argv':argv,'returncode':result.returncode,'wall_seconds':time.perf_counter()-start,'log':str(log.relative_to(ROOT)),'sha256':sha(log),'test_totals':re.findall(r'Total tests: (\d+), passed: (\d+), failed: (\d+)',log.read_text())}
 report['commands'].append(entry);save();print('END',name,entry['returncode'],round(entry['wall_seconds'],3),entry['test_totals'],flush=True)
 if result.returncode:raise RuntimeError(name+' failed')
save()
try:
 command('tests-native',['tools/moon','test',*['src/'+k for k in report['packages']],'--target','native','--release','--deny-warn','-j','1'])
 command('formal',['tools/check_formal'])
 assert report['source_commit']==git('rev-parse','HEAD') and all(sha(p)==h for p,h in report['source_files'].items()),'Source changed during validation'
 report['status']='passed'
except BaseException as e:
 report['status']='failed';report['error']=str(e);raise
finally:
 report['finished_utc']=datetime.datetime.now(datetime.timezone.utc).isoformat();save()
