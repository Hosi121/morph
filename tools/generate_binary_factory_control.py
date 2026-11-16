#!/usr/bin/env python3
from pathlib import Path
import re, hashlib
ROOT = Path(__file__).resolve().parent.parent
sources=[ROOT / 'src/binary/binary.mbt']
if (ROOT / 'src/binary/division.mbt').exists(): sources.append(ROOT / 'src/binary/division.mbt')
functions={}
for path in sources:
    text=path.read_text()
    for chunk in text.split('///|'):
        m=re.search(r'^(?:pub )?fn (\w+)\(',chunk,re.M)
        if m: functions[m[1]]=chunk[m.start():].strip()
selected=set()
def visit(name):
    if name in selected:return
    selected.add(name)
    for called in re.findall(r'(?<![@\w.:])([a-zA-Z_]\w*)\s*\(',functions[name]):
        if called in functions and called!=name: visit(called)
for name in ['add','subtract','multiply','divmod','gcd']:visit(name)
base='''// Frozen benchmark controls: only zero/one factories differ.
// Generated in the private worktree; no production implementation is replaced.
'''
for mode in ['fresh','shared']:
  for name in sorted(selected):
    if name in ['zero','one']:
      call='previous_'+name+'_factory()' if mode=='fresh' else 'canonical_'+name+'()'
      fn='fn '+name+'() -> Binary { '+call+' }'
    else: fn=re.sub(r'^pub fn ', 'fn ', functions[name])
    for sym in sorted(selected,key=len,reverse=True):
      fn=re.sub(r'(?<![@\w.:])'+sym+r'(?=\s*\()', 'factory_'+mode+'_'+sym, fn)
    base+='\n///|\n'+fn+'\n'
base+='''
///|
test "shared Binary constants preserve canonical boundaries and arithmetic" {
  assert_eq(canonical_zero(), @oracle.binary(0))
  assert_eq(canonical_one(), @oracle.binary(1))
  for a in 0..<256 {
    for b in 0..<256 {
      let x = @oracle.binary(a)
      let y = @oracle.binary(b)
      assert_eq(factory_shared_add(x,y), @oracle.binary(a+b))
      assert_eq(factory_shared_multiply(x,y), @oracle.binary(a*b))
      let expected = if b == 0 { None } else { Some((@oracle.binary(a/b),@oracle.binary(a%b))) }
      assert_eq(factory_shared_divmod(x,y), expected)
      assert_eq(factory_shared_gcd(x,y), gcd(x,y))
    }
  }
}

///|
test "same ELF mixed small Binary factory cohort" (b : @bench.T) {
  let pairs = []
  for index in 0..<128 {
    let a = (index * 73 + 19) % 65
    let c = (index * 137 + 43) % 65
    pairs.push((@oracle.binary(a), @oracle.binary(c)))
  }
  b.bench(name="fresh small128", fn() {
    for pair in pairs {
      b.keep(factory_fresh_add(pair.0,pair.1))
      b.keep(factory_fresh_subtract(pair.0,pair.1))
      b.keep(factory_fresh_multiply(pair.0,pair.1))
      b.keep(factory_fresh_divmod(pair.0,pair.1))
      b.keep(factory_fresh_gcd(pair.0,pair.1))
    }
  })
  b.bench(name="shared small128", fn() {
    for pair in pairs {
      b.keep(factory_shared_add(pair.0,pair.1))
      b.keep(factory_shared_subtract(pair.0,pair.1))
      b.keep(factory_shared_multiply(pair.0,pair.1))
      b.keep(factory_shared_divmod(pair.0,pair.1))
      b.keep(factory_shared_gcd(pair.0,pair.1))
    }
  })
}
'''
(ROOT / 'src/binary/factory_control_wbtest.mbt').write_text(base)
print('functions',len(selected),'source hash', hashlib.sha256(''.join(p.read_text() for p in sources).encode()).hexdigest())
