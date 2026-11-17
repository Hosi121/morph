from pathlib import Path
import subprocess,json,gzip,hashlib,shutil,datetime,re
root=Path.cwd();out=root/'.tools/night-kernels-20261117';validation=json.loads((out/'validation.json').read_text());assert validation['status']=='passed','Regression not complete/passed'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();git=lambda *a:subprocess.check_output(['git',*a],text=True).strip();assert git('rev-parse','HEAD')==validation['source_commit'];assert all(sha(root/p)==h for p,h in validation['source_files'].items())
cases={
'nightnfbench':(1,['dense-repeat','sparse-no-reduction','degree1-control','field-setup-only','setup-one-shot','complex-square']),
'nightfpbench':(1,['multiply65537-dense','multiply257-unit','scale257-unreduced','divide17-d24','gf2-control','one-shot17']),
'nightgf2bench':(1,['tiny','sparse','dense','solve-reuse','solve-setup','cohomology-torus']),
'nightnormalbench':(2,['univariate-dense','rational-nonmonic','multivariate-order','no-reduction','edge-errors','buchberger']),
'nightevalbench':(2,['odd65537-reduced','odd257-unreduced','gf2-mixed','tiny-constant','setup-one-shot17','listdecode-encode17']),
'nighteliminatebench':(2,['rref-tiny','rref-sparse','rref-dense','rref-wide','factor-dense','css-validate']),
'nightproductbench':(3,['sparse-multivariate','dense-univariate','unequal-sparse','rational-cancellation','small-controls','buchberger']),
'nightconvolutionbench':(3,['sparse257','unit17-upper','dense65537','zero257','tiny17','gf2-control']),
'nightcursorbench':(3,['rref-tiny','rref-sparse','rref-dense','rref-wide','factor-dense','css-validate'])}
baselines={n:root.parent/name for n,name in [(1,'morph-night-before'),(2,'morph-night-r2-before'),(3,'morph-night-r3-before')]}
# Only whitespace and optional trailing commas changed during the fmt repair.
p=baselines[1]/'src/cmd/nightgf2bench/main.mbt';q=root/'src/cmd/nightgf2bench/main.mbt';norm=lambda s:re.sub(r',(?=[\]\)}])','', ''.join(s.split()));assert norm(p.read_text())==norm(q.read_text());shutil.copy2(q,p)
print('BUILD formatted baseline GF2 harness',flush=True)
subprocess.run([str(baselines[1]/'tools/moon'),'build','src/cmd/nightgf2bench','--target','native','--release','--deny-warn','-j','1'],cwd=baselines[1],check=True)
print('BUILD all final public CLIs',flush=True)
subprocess.run(['tools/moon','build',*['src/cmd/'+p for p in cases],'--target','native','--release','--deny-warn','-j','1'],check=True)
records=[];destdir=out/'artifacts/final';destdir.mkdir(parents=True,exist_ok=True)
for package,(round_number,names) in cases.items():
 before=baselines[round_number];artifact=Path('_build/native/release/build/cmd')/package/(package+'.exe');path=out/(package+'-final.json');argv=['python3','tools/compare_field_kernels.py','--before',str(before/artifact),'--after',str(root/artifact),'--before-root',str(before),'--after-root',str(root),'--harness','src/cmd/'+package,'--groups','5','--output',str(path)]
 for name in names:argv+=['--case',name]
 print('START',package,flush=True)
 with (out/(package+'-final.log')).open('w') as f:subprocess.run(argv,stdout=f,stderr=subprocess.STDOUT,check=True,timeout=180)
 data=json.loads(path.read_text());assert data['all_checked'];compressed=root/'docs/measurements'/f'night-final-{package}-20261117.json.gz'
 with compressed.open('wb') as f:
  with gzip.GzipFile(filename='',fileobj=f,mode='wb',mtime=0) as z:z.write(path.read_bytes())
 summary={k:v for k,v in data.items() if k!='runs'};summary['run_count']=len(data['runs']);summary['round_baseline']=round_number;summary['lossless_full_record']={'path':str(compressed.relative_to(root)),'sha256':sha(compressed),'uncompressed_sha256':sha(path)}
 if package=='nightcursorbench':summary['note']='Rejected cursor implementation is absent; this final-source harness is an unchanged-producer control, not evidence of cursor adoption.'
 if package=='nightgf2bench':summary['format_repair_note']='Baseline and final use the same formatted harness; baseline rebuilt after whitespace/optional-comma-only formatting repair. Original source/binaries/raw runs preserved separately.'
 compressed.with_suffix('').write_text(json.dumps(summary,indent=2)+'\n')
 for side,base in [('before',before),('after',root)]:
  p=destdir/(package+'-'+side+'.exe');shutil.copy2(base/artifact,p);assert sha(p)==data[side]['artifact_sha256'];records.append({'path':str(p.relative_to(root)),'sha256':sha(p),'source_commit':data[side]['commit']})
 print('DONE',package,{k:round(v['process_ns']['before_over_after'],3) for k,v in data['summary'].items()},flush=True)
assert git('rev-parse','HEAD')==validation['source_commit'];assert all(sha(root/p)==h for p,h in validation['source_files'].items())
(out/'final-artifacts.json').write_text(json.dumps(records,indent=2)+'\n');(out/'final-comparison-status.json').write_text(json.dumps({'status':'passed','source_commit':validation['source_commit'],'processes':1080,'packages':list(cases),'all_checked':True,'finished_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()},indent=2)+'\n')
