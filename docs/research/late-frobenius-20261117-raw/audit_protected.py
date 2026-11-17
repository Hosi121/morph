"""Verify the known-square edit leaves algorithms, guards and exponent order intact."""
from pathlib import Path
from hashlib import sha256
import subprocess,json,re
BASE='a39f3234da50eb86e19d58583d5db5c2c99b62c1'
def old(path):return subprocess.check_output(['git','show',BASE+':'+path],text=True)
def function(source,name):
 marker=re.search(r'(?m)^(?:pub )?fn '+re.escape(name)+r'\(',source)
 start=marker.start();end=source.find('\n///|',start)
 return source[start:end if end>=0 else len(source)].rstrip()
path='src/fppoly/polynomial.mbt';before=old(path);after=Path(path).read_text()
records=[]
for name in re.findall(r'(?m)^(?:pub )?fn (\w+)\(',before):
 expected=function(before,name);actual=function(after,name)
 if name=='power_loop':
  assert actual.count('square_remainder(base, modulus)')==1
  actual=actual.replace('square_remainder(base, modulus)','product_remainder(base, base, modulus)')
 assert actual==expected,name
 records.append(dict(function=name,sha256=sha256(expected.encode()).hexdigest(),unchanged_except_known_square_call=name=='power_loop'))
path='src/fppoly/characteristic_two.mbt';assert Path(path).read_text().startswith(old(path))
files=[]
for path in ['src/fppoly/irreducibility.mbt','src/fppoly/factorization.mbt','src/galois/galois.mbt','src/galois/carryless.mbt']:
 a=old(path);b=Path(path).read_text();assert a==b,path
 files.append(dict(path=path,sha256=sha256(a.encode()).hexdigest(),byte_identical=True))
output=Path(__file__).resolve().parent/'protected-source.json'
output.write_text(json.dumps(dict(base=BASE,functions=records,unchanged_files=files,limitations='Irreducibility orbit replay and Galois.extension share power_mod and the optimized square. Checkers are text-identical but are not independent arithmetic oracles. Host carryless/Bezout checks and unchanged generic multiplication provide independent bounded evidence.'),indent=2)+'\n')
print('Protected algorithms and error/exponent order unchanged; only known-square call replaced')
