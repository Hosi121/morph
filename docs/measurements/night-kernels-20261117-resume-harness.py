from pathlib import Path
import subprocess,hashlib,json,datetime,time,re,resource,shutil
root=Path.cwd();out=root/'.tools/night-kernels-20261117';sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();git=lambda *a:subprocess.check_output(['git',*a],text=True).strip();resource.setrlimit(resource.RLIMIT_CORE,(0,0))
d=json.loads((out/'validation.json').read_text());assert d['status']=='running';assert d['source_commit']==git('rev-parse','HEAD');assert all(sha(root/p)==h for p,h in d['source_files'].items());assert [c['name'] for c in d['commands']]==['maintenance','check-js','check-native','tests-wasm-gc','tests-js']
for c in d['commands']:assert c['returncode']==0 and sha(root/c['log'])==c['sha256']
archive=out/'interrupted-native-attempt';archive.mkdir(exist_ok=True)
for name in ['tests-native.log','validation-driver.log','final-comparison-driver.log']:
 p=out/name
 if p.exists():shutil.copy2(p,archive/name)
d.setdefault('interruptions',[]).append({'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'observed_parent_exit_code':143,'cause':'Unconfirmed external SIGTERM; driver had no final completion record. No failing test result observed.','incomplete_stage':'tests-native','completed_source_and_log_hashes_reverified':True,'partial_logs':{str(p.relative_to(root)):sha(p) for p in archive.iterdir() if p.is_file()},'resume_policy':'Keep all completed maintenance/global/WasmGC/JS stages; rerun only the unfinished native command using cached compiled artifacts, then formal.'})
def save():(out/'validation.json').write_text(json.dumps(d,indent=2)+'\n')
def command(name,argv):
 print('START',name,flush=True);p=out/(name+'.log');start=time.perf_counter()
 with p.open('w') as f:r=subprocess.run(argv,stdout=f,stderr=subprocess.STDOUT)
 entry={'name':name,'argv':argv,'returncode':r.returncode,'wall_seconds':time.perf_counter()-start,'log':str(p.relative_to(root)),'sha256':sha(p),'test_totals':re.findall(r'Total tests: (\d+), passed: (\d+), failed: (\d+)',p.read_text())};d['commands'].append(entry);save();print('END',name,r.returncode,entry['wall_seconds'],entry['test_totals'],flush=True)
 if r.returncode:raise RuntimeError(name+' failed')
save()
try:
 command('tests-native',['tools/moon','test',*['src/'+p for p in d['packages']],'--target','native','--deny-warn','-j','1','--release'])
 command('formal',['tools/check_formal'])
 assert d['source_commit']==git('rev-parse','HEAD') and all(sha(root/p)==h for p,h in d['source_files'].items())
 d['status']='passed'
except BaseException as e:d['status']='failed';d['error']=str(e);raise
finally:d['finished_utc']=datetime.datetime.now(datetime.timezone.utc).isoformat();d['resume_harness_sha256']=sha(out/'resume_validation.py');save()
