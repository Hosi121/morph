import unittest
from audit_paths import roundtrips, word_hex_misuse


class ConversionGateTests(unittest.TestCase):
    def test_rejects_identity_and_halving(self):
        source = """@binary.to_nat(@binary.from_nat(n))
@binary.from_nat(@binary.to_nat(b))
@binary.to_nat(
  @binary.half(@binary.from_nat(n)),
)"""
        self.assertEqual(len(roundtrips(source)), 3)

    def test_alias_and_comments(self):
        self.assertEqual(len(roundtrips('@b.to_nat(@b.half(/*x*/ @b.from_nat(n)))', ('b',))), 1)
        self.assertEqual(roundtrips('// @binary.to_nat(@binary.from_nat(n))\n"@binary.to_nat(@binary.from_nat(n))"'), [])

    def test_keeps_real_representation_boundaries(self):
        source = """@binary.from_nat(index)
@binary.to_nat(run.length)
@binary.to_nat(@binary.gcd(a,b))
@core.half_nat(n)"""
        self.assertEqual(roundtrips(source), [])

    def test_rejects_numeral_bits_as_hex_word(self):
        self.assertEqual(len(word_hex_misuse('@oracle.hex_bits(@binary.bits(n))')),1)
        self.assertEqual(len(word_hex_misuse('@o.hex_bits(\n@b.bits(n),\n)',('o',),('b',))),1)

    def test_word_hex_keeps_valid_word_and_formatted_inputs(self):
        self.assertEqual(word_hex_misuse('@oracle.hex_bits(word)\n@oracle.hex_bits(@oracle.chain(padded))'),[])
        self.assertEqual(word_hex_misuse('// @oracle.hex_bits(@binary.bits(n))\n"@oracle.hex_bits(@binary.bits(n))"'),[])
        self.assertEqual(word_hex_misuse('@unrelated.hex_bits(@binary.bits(n))'),[])


if __name__ == '__main__':
    unittest.main()
