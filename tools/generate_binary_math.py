#!/usr/bin/env python3
"""Exact big-result fixtures from Python integers and math.isqrt."""
from pathlib import Path
from math import isqrt, gcd

root = Path(__file__).resolve().parent.parent
out = '// Generated independently by tools/generate_binary_math.py using Python integers.\n'
out += '///|\ntest "fast doubling large exact Python integer fixtures" {\n'
for n in [100, 200, 1000]:
    a,b = 0,1
    for _ in range(n):
        a,b = b,a+b
    out += f'  assert_eq(fibonacci_pair(@oracle.binary({n})),(@oracle.binary_from_hex("{a:x}"),@oracle.binary_from_hex("{b:x}")))\n'
out += '}\n\n///|\ntest "large non-square roots match Python math.isqrt" {\n'
for n in [(1<<127)-1, (1<<256)+0x123456789abcdef, (1<<513)-1]:
    r = isqrt(n)
    out += f'  assert_eq(sqrt_rem(@oracle.binary_from_hex("{n:x}")),(@oracle.binary_from_hex("{r:x}"),@oracle.binary_from_hex("{n-r*r:x}")))\n'
out += '}\n'
out += '\n///|\ntest "large Stein GCD matches Python math.gcd" {\n'
for a,b in [((1<<600)-1,(1<<400)-1),((1<<511)+12345,(1<<255)+54321)]:
    out += f'  assert_eq(stein_gcd(@oracle.binary_from_hex("{a:x}"),@oracle.binary_from_hex("{b:x}")),@oracle.binary_from_hex("{gcd(a,b):x}"))\n'
out += '}\n'
(root / 'src/binary/math_vectors_wbtest.mbt').write_text(out)
