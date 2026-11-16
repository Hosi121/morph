#!/usr/bin/env python3
"""Record semialgebraic verification under an enclosing shared CPU8 lock."""
from pathlib import Path
import subprocess,time,json,datetime
ROOT=Path(__file__).resolve().parents[1]
commands=[['.tools/moon/bin/moon','test','src/semialgebraic','--target',t,'--deny-warn'] for t in ['native','js','wasm-gc']]+[
 ['.tools/moon/bin/moon','check','src/semialgebraic','--deny-warn'],
 ['.tools/moon/bin/moon','info','src/semialgebraic'],
 ['.tools/moon/bin/moon','fmt','--check','src/semialgebraic'],
 ['python3','tools/generate_semialgebraic_fixtures.py','--check'],
 ['python3','tools/audit_purity.py'],
]
records=[]
for command in commands:
 start=time.monotonic();p=subprocess.run(command,cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 record=dict(command=command,exit_code=p.returncode,wall_seconds=round(time.monotonic()-start,6),output=p.stdout);records.append(record);print(json.dumps(record),flush=True)
 (ROOT/'docs/research/semialgebraic-20261116-validation.json').write_text(json.dumps(dict(utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),cpu=8,serialization='tools/measure shared git-common-dir lock',timing_scope='incremental command wall time, not an algorithm benchmark',commands=records),indent=2)+'\n')
 if p.returncode:break
raise SystemExit(any(r['exit_code'] for r in records))
