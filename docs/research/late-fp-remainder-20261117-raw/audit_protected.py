"""Protect public division, exponent schedule and certificate algorithms."""
from pathlib import Path
from hashlib import sha256
import subprocess,re,json
BASE='905d23dc1a098359c28b4d9d7914c38d9a797c34'
def old(path):return subprocess.check_output(['git','show',BASE+':'+path],text=True)
def function(source,name):
 a=re.search(r'(?m)^(?:pub )?fn '+re.escape(name)+r'\(',source).start();b=source.find('\n///|',a)
 return source[a:b if b>=0 else len(source)].rstrip()
path='src/fppoly/polynomial.mbt';before=old(path);after=Path(path).read_text();records=[]
changed={'product_remainder','square_remainder','power_mod'}
for name in re.findall(r'(?m)^(?:pub )?fn (\w+)\(',before):
 if name in changed:continue
 a=function(before,name);b=function(after,name);assert a==b,name
 records.append(dict(function=name,sha256=sha256(a.encode()).hexdigest(),unchanged=True))
files=[]
for path in ['src/fppoly/characteristic_two.mbt','src/fppoly/irreducibility.mbt','src/fppoly/factorization.mbt','src/galois/galois.mbt','src/galois/carryless.mbt']:
 a=old(path);b=Path(path).read_text();assert a==b,path
 files.append(dict(path=path,sha256=sha256(a.encode()).hexdigest(),byte_identical=True))
Path(__file__).with_name('protected-source.json').write_text(json.dumps(dict(base=BASE,protected_functions=records,protected_files=files,changed_callers=sorted(changed),note='Public divide, its loop/constant helper, all exponent schedule and existing known F2 square are unchanged. Certificate algorithms share modular-power arithmetic; host and public-divide oracles are required.'),indent=2)+'\n')
print('Public division/oracle, exponent schedule, known F2 square and checkers unchanged')
