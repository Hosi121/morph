#!/usr/bin/env python3
"""Reproduce the committed NIST bit-oriented fixtures from their source rsp.

Usage: python3 tools/generate_nist_sha256.py path/to/SHA256ShortMsg.rsp
Source zip: https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Algorithm-Validation-Program/documents/shs/shabittestvectors.zip
"""
from pathlib import Path
import hashlib
import re
import sys

root = Path(__file__).resolve().parent.parent
source = Path(sys.argv[1]).read_bytes()
rows = re.findall(r'Len = (\d+)\s+Msg = ([0-9a-f]+)\s+MD = ([0-9a-f]+)', source.decode('ascii'))
assert rows and rows[0][0] == '0' and rows[-1][0] == '512'
out = '// NIST CAVP SHA256ShortMsg.rsp, all bit lengths from zero through one block.\n'
out += '// Source SHA256: ' + hashlib.sha256(source).hexdigest() + '\n///|\n'
out += 'test "NIST CAVP bit-oriented SHA-256 all short messages" {\n'
for length, message, digest in rows:
    literal = ''.join('\\x' + message[i:i+2] for i in range(0, len(message), 2))
    out += f'  assert_hash_bits(@core.take(@oracle.nat({length}),bit_message(b"{literal}")),"{digest}")\n'
out += '}\n'
(root / 'src/sha256/nist_wbtest.mbt').write_text(out)
