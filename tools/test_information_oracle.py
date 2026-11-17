import unittest
from fractions import Fraction as Q

from benchmark_information import decode, expected_outputs


class InformationOracleTests(unittest.TestCase):
    def test_rejects_truncated_and_noncanonical_wire_numbers(self):
        for value in [[False,'','1'],[False,'1',''],[False,'01','1'],
                      [True,'0','1'],[False,'2','4'],[False,'1','0']]:
            with self.subTest(value=value), self.assertRaises((AssertionError,ValueError)):
                decode(value)

    def test_wire_numbers_keep_large_coprime_values(self):
        n=(1<<200)+17
        d=(1<<197)+3
        expected=Q(-n,d)
        self.assertEqual(decode([True,format(abs(expected.numerator),'x'),format(expected.denominator,'x')]),expected)
        self.assertEqual(decode([False,'0','1']),Q(0))

    def test_independent_gaussian_oracle_has_known_standard_cumulants(self):
        normal=expected_outputs()['gaussian2']
        self.assertEqual([normal['metric'][i][i] for i in range(5)],[1,1,2,1,2])
        self.assertEqual(normal['first'][2][2][2],8)
        self.assertEqual(normal['second'][2][2][2][2],48)
        self.assertEqual(normal['second'][0][0][0][0],0)
        self.assertEqual(normal['second'][0][0][2][2],8)


if __name__=='__main__':
    unittest.main()
