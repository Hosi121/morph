from pathlib import Path
import os,subprocess,json
root=Path.cwd();out=root/'.tools/algorithm-kernels-20261117';before=root.parent/'morph-algo-before'
os.environ.pop('MORPH_CANONICAL_ITERATIONS',None)
cases={'nfkernelbench':['addsub-d4','addsub-d1','coords-sparse-d4','coords-dense-d4','coords-zero-d1','matrix-d4','multiply-control-d4','complex-square-d4'],'spanbench':['nf2','nf6','nf6-subfield','cf2-tiny','cf4','cf8','fglm3','fglm8'],'structuralbench':['smith-small','smith-rectangular','smith-dense','persistence-tiny','persistence-sparse','persistence-collisions']}
for package,names in cases.items():
 artifact=Path('_build/native/release/build/cmd')/package/(package+'.exe')
 command=['python3','tools/compare_field_kernels.py','--before',str(before/artifact),'--after',str(root/artifact),'--before-root',str(before),'--after-root',str(root),'--harness','src/cmd/'+package,'--groups','5','--output','docs/measurements/algorithm-kernels-'+package+'-20261117.json']
 for name in names:command+=['--case',name]
 print('START',package,flush=True)
 with (out/(package+'-final-comparison.log')).open('w') as log:subprocess.run(command,check=True,stdout=log,stderr=subprocess.STDOUT)
 print('DONE',package,flush=True)
