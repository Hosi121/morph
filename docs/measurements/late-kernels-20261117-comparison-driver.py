from pathlib import Path
import subprocess,json,gzip,hashlib,shutil,datetime
root=Path.cwd();out=root/'.tools/late-kernels-20261117';git=lambda *a:subprocess.check_output(['git',*a],text=True).strip();sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
record=json.loads((out/'final-validation-v2/validation.json').read_text());source=record['source_commit'];assert record['status']=='passed' and source==git('rev-parse','HEAD');assert all(sha(root/p)==h for p,h in record['source_files'].items());assert not git('status','--porcelain','--','src','tools','moon.mod','formal')
settings=[('morph-late-before',{'latepolybench':['full-cancellation','interleaved','block-disjoint','mixed-rational','small-zero-errors','buchberger'],'latefrobeniusbench':['dense-f2-power16','sparse-f2-power32','irreducibility-setup8','odd17-control','lowdegree-f2','setup-one-shot-f2'],'lateboolproductbench':['tiny-and-shapes','sparse','dense','zero','cohomology-circle','cohomology-torus']}),('morph-late-r2-before',{'lateunitbench':['unit-plus','unit-minus','nonunit-controls','dense-control','tiny-zero-errors','nf-upper'],'lateremainderbench':['dense-f2-power16','sparse-f2-power32','irreducibility-setup8','odd17-control','lowdegree-f2','setup-one-shot-f2'],'latebasisbench':['tiny','sparse','dense','fullrank','zerorank','cohomology-torus']})]
print('BUILD all final public CLIs',flush=True)
subprocess.run(['tools/moon','build',*['src/cmd/'+p for _,cases in settings for p in cases],'--target','native','--release','--deny-warn','-j','1'],check=True)
all_artifacts=[];reports=[]
for before_name,cases in settings:
 before=root.parent/before_name
 for package,names in cases.items():
  artifact=Path('_build/native/release/build/cmd')/package/(package+'.exe');path=out/(package+'-final.json')
  argv=['python3','tools/compare_field_kernels.py','--before',str(before/artifact),'--after',str(root/artifact),'--before-root',str(before),'--after-root',str(root),'--harness','src/cmd/'+package,'--groups','5','--output',str(path)]
  for name in names:argv+=['--case',name]
  print('START',package,flush=True)
  with (out/(package+'-final.log')).open('w') as log:subprocess.run(argv,check=True,stdout=log,stderr=subprocess.STDOUT)
  d=json.loads(path.read_text());assert d['all_checked'];dest=root/'docs/measurements'/f'late-final-{package}-20261117.json.gz'
  with dest.open('wb') as f:
   with gzip.GzipFile(filename='',fileobj=f,mode='wb',mtime=0) as z:z.write(path.read_bytes())
  assert gzip.decompress(dest.read_bytes())==path.read_bytes()
  summary={k:v for k,v in d.items() if k!='runs'};summary['run_count']=len(d['runs']);summary['lossless_full_record']={'path':str(dest.relative_to(root)),'sha256':sha(dest),'uncompressed_sha256':sha(path),'format':'gzip-compressed UTF-8 JSON; retains every complete stdout/result, timing and provenance'}
  dest.with_suffix('').write_text(json.dumps(summary,indent=2)+'\n')
  reports.append({'package':package,'path':str(dest.with_suffix('').relative_to(root)),'runs':len(d['runs']),'all_checked':True})
  for label,tree in [('before',before),('after',root)]:
   saved=out/'artifacts/final'/(package+'-'+label+'.exe');saved.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(tree/artifact,saved);assert sha(saved)==d[label]['artifact_sha256'];all_artifacts.append({'path':str(saved.relative_to(root)),'sha256':sha(saved),'mode':oct(saved.stat().st_mode & 0o777)})
  print('DONE',package,{k:round(v['process_ns']['before_over_after'],3) for k,v in d['summary'].items()},flush=True)
assert sum(r['runs'] for r in reports)==720
assert source==git('rev-parse','HEAD') and all(sha(root/p)==h for p,h in record['source_files'].items());assert not git('status','--porcelain','--','src','tools','moon.mod','formal')
(out/'final-artifacts.json').write_text(json.dumps(all_artifacts,indent=2)+'\n');(out/'final-comparison-status.json').write_text(json.dumps({'status':'passed','source_commit':source,'reports':reports,'full_checked_processes':720,'finished_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()},indent=2)+'\n')
