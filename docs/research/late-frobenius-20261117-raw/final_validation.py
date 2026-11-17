"""Final bounded package checks, intentionally no global compiler/test graph."""
from pathlib import Path
from hashlib import sha256
import json,subprocess,time,sys
BASE='a39f3234da50eb86e19d58583d5db5c2c99b62c1'
folder=Path(__file__).resolve().parent
commands=[['tools/moon','test','src/fppoly','src/galois','--target',target,'--release','--deny-warn','-j','1'] for target in ['native','wasm-gc','js']]
commands += [['tools/moon','info','src/fppoly','src/galois','src/cmd/latefrobeniusbench','--target','all'],['python3',str(folder/'audit_protected.py')]]
rows=[]
for command in commands:
 start=time.monotonic();p=subprocess.run(command,capture_output=True,text=True)
 rows.append(dict(command=command,exit_code=p.returncode,seconds=time.monotonic()-start,stdout=p.stdout,stderr=p.stderr))
 (folder/'validation.json').write_text(json.dumps(rows,indent=2)+'\n')
 print(' '.join(command),p.returncode,p.stdout,p.stderr,flush=True)
 if p.returncode:raise SystemExit(p.returncode)
records=[]
for package in ['fppoly','galois']:
 path='src/'+package+'/pkg.generated.mbti';a=subprocess.check_output(['git','show',BASE+':'+path]);b=Path(path).read_bytes();assert a==b
 records.append(dict(path=path,before_sha256=sha256(a).hexdigest(),after_sha256=sha256(b).hexdigest(),identical=True))
(folder/'api-diff.json').write_text(json.dumps(records,indent=2)+'\n')
sys.path.insert(0,'tools')
from audit_purity import FORBIDDEN,code_only
production=['src/fppoly/characteristic_two.mbt','src/fppoly/polynomial.mbt']
for path in production:assert not FORBIDDEN.search(code_only(Path(path).read_text())),path
(folder/'scoped-purity.json').write_text(json.dumps(dict(scope=production,passed=True,note='Only changed production files checked; root owns full global regression.'),indent=2)+'\n')
print('fppoly/galois API bytes unchanged; scoped production purity passed',flush=True)
