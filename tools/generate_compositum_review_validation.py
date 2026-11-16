#!/usr/bin/env python3
"""Record independent compositum review under enclosing tools/measure CPU8 lock."""
from pathlib import Path
import subprocess,time,json,datetime
ROOT=Path(__file__).resolve().parents[1]
commands=[['.tools/moon/bin/moon','test','src/compositum','--target',target,'-f','*review*','--deny-warn'] for target in ['native','js','wasm-gc']]+[
 ['.tools/moon/bin/moon','check','src/compositum','--deny-warn'],
 ['.tools/moon/bin/moon','fmt','--check','src/compositum'],
 ['python3','tools/generate_compositum_review_fixtures.py','--check'],
 ['python3','tools/audit_purity.py'],
 ['git','diff','706cb8b','--','src/compositum/checker.mbt','src/compositum/context.mbt','src/compositum/producer.mbt','src/compositum/moon.pkg','src/compositum/pkg.generated.mbti'],
]
records=[]
for command in commands:
 start=time.monotonic();p=subprocess.run(command,cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 record=dict(command=command,exit_code=p.returncode,wall_seconds=round(time.monotonic()-start,6),output=p.stdout);records.append(record);print(json.dumps(record),flush=True)
 path=ROOT/'docs/research/compositum-review-20261116-validation.json'
 path.write_text(json.dumps(dict(utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),cpu=8,source='706cb8b',dependency='24d04ed',scope='review tests/generators/note/artifacts only; no producer/checker modification',serialization='tools/measure shared git-common-dir lock',timing_scope='incremental command wall time, not an isolated algorithm benchmark',commands=records),indent=2)+'\n')
 if p.returncode:break
raise SystemExit(any(r['exit_code'] for r in records))
