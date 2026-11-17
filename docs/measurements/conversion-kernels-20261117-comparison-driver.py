from pathlib import Path
import subprocess,json,gzip,hashlib,shutil,datetime
root=Path.cwd();out=root/'.tools/conversion-followup-20261117';git=lambda *a:subprocess.check_output(['git',*a],text=True).strip();sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
validation=json.loads((out/'final-validation/validation.json').read_text());source=validation['source_commit'];assert validation['status']=='passed' and source==git('rev-parse','HEAD');assert all(sha(root/p)==h for p,h in validation['source_files'].items());assert not git('status','--porcelain','--','src','tools','moon.mod','formal')
settings={
 'towerconstantbench':('morph-conversion-tower-before',['embed-base','embed-depth1','embed-depth2','embed-depth3-4','multiply-depth2','cold-setup-depth2']),
 'conversionmodularbench':('morph-conversion-modular-before',['negative-reduced','negative-unreduced','zero-tiny-boundaries','positive-control','inverse-field','one-shot']),
 'smithcontextbench':('morph-conversion-smith-before',['empty','one','many','bases','induced','connecting']),
 'conversionmonicbench':('morph-conversion-modular-before',['dense-monic','sparse-monic','rational-multivar','fallback-dense','zero-tiny-controls','resultant-caller'])}
print('BUILD final four public CLIs',flush=True);subprocess.run(['tools/moon','build',*['src/cmd/'+p for p in settings],'--target','native','--release','--deny-warn','-j','1'],check=True)
artifacts=[];reports=[]
for package,(before_name,names) in settings.items():
 before=root.parent/before_name;artifact=Path('_build/native/release/build/cmd')/package/(package+'.exe');path=out/(package+'-final.json');argv=['python3','tools/compare_field_kernels.py','--before',str(before/artifact),'--after',str(root/artifact),'--before-root',str(before),'--after-root',str(root),'--harness','src/cmd/'+package,'--groups','5','--output',str(path)]
 for case in names:argv+=['--case',case]
 print('START',package,flush=True)
 with (out/(package+'-final.log')).open('w') as log:subprocess.run(argv,check=True,stdout=log,stderr=subprocess.STDOUT)
 d=json.loads(path.read_text());assert d['all_checked'] and len(d['runs'])==120;dest=root/'docs/measurements'/f'conversion-final-{package}-20261117.json.gz'
 with dest.open('wb') as f:
  with gzip.GzipFile(filename='',fileobj=f,mode='wb',mtime=0) as z:z.write(path.read_bytes())
 assert gzip.decompress(dest.read_bytes())==path.read_bytes();summary={k:v for k,v in d.items() if k!='runs'};summary['run_count']=len(d['runs']);summary['lossless_full_record']={'path':str(dest.relative_to(root)),'sha256':sha(dest),'uncompressed_sha256':sha(path),'format':'lossless UTF-8 JSON gzip; every full result/stdout/stderr/timing/provenance retained'}
 if package in ['towerconstantbench','conversionmodularbench']:summary['note']='Rejected sharing/residue mechanism is absent. This measures original producers plus the adopted monic/Smith integration; effects must not be attributed to rejected source.'
 dest.with_suffix('').write_text(json.dumps(summary,indent=2)+'\n');reports.append({'package':package,'summary':str(dest.with_suffix('').relative_to(root)),'runs':120,'all_checked':True})
 for side,tree in [('before',before),('after',root)]:
  saved=out/'artifacts/final'/(package+'-'+side+'.exe');saved.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(tree/artifact,saved);assert sha(saved)==d[side]['artifact_sha256']
  c_source=(tree/artifact).with_suffix('.c');assert c_source.is_file();c_saved=saved.with_suffix('.c.gz')
  with c_saved.open('wb') as target:
   with gzip.GzipFile(filename='',fileobj=target,mode='wb',mtime=0) as z:z.write(c_source.read_bytes())
  assert gzip.decompress(c_saved.read_bytes())==c_source.read_bytes();artifacts.append({'path':str(saved.relative_to(root)),'sha256':sha(saved),'mode':oct(saved.stat().st_mode & 0o777),'generated_c':{'path':str(c_saved.relative_to(root)),'sha256':sha(c_saved),'uncompressed_sha256':sha(c_source)}})
 print('DONE',package,{k:round(v['process_ns']['before_over_after'],3) for k,v in d['summary'].items()},flush=True)
assert source==git('rev-parse','HEAD') and all(sha(root/p)==h for p,h in validation['source_files'].items());assert not git('status','--porcelain','--','src','tools','moon.mod','formal')
(out/'final-artifacts.json').write_text(json.dumps(artifacts,indent=2)+'\n');(out/'final-comparison-status.json').write_text(json.dumps({'status':'passed','source_commit':source,'full_checked_processes':480,'reports':reports,'finished_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()},indent=2)+'\n')
