#!/usr/bin/env python3
"""Record package verification under an enclosing tools/measure CPU8 lock."""
import subprocess,time,json,datetime
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
commands=[
 ['.tools/moon/bin/moon','test','src/orderedsturm','--target',target] for target in ['native','js','wasm-gc']
]+[
 ['.tools/moon/bin/moon','check','src/orderedsturm','--deny-warn'],
 ['.tools/moon/bin/moon','info','src/orderedsturm'],
 ['.tools/moon/bin/moon','fmt','--check','src/orderedsturm'],
 ['python3','tools/audit_purity.py'],
 ['python3','tools/generate_orderedsturm_fixtures.py','--check'],
]
records=[]
for command in commands:
 start=time.monotonic();p=subprocess.run(command,cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 record=dict(command=command,exit_code=p.returncode,wall_seconds=round(time.monotonic()-start,6),output=p.stdout);records.append(record)
 print(json.dumps(record),flush=True)
 if p.returncode:break
path=ROOT/'docs/research/orderedsturm-20261116-validation.json'
path.write_text(json.dumps(dict(utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),cpu=8,serialization='tools/measure shared git-common-dir lock',timing_scope='incremental command wall time, not an algorithm benchmark',commands=records),indent=2)+'\n')
raise SystemExit(any(r['exit_code'] for r in records))
