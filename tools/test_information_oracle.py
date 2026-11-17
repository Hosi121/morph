import unittest
import copy
import gzip
import json
from pathlib import Path
from fractions import Fraction as Q

from benchmark_information import decode, expected_outputs
from check_information_evidence import validate


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

    def test_retained_evidence_rejects_missing_duplicate_or_unequal_full_outputs(self):
        path=Path(__file__).resolve().parent.parent/'docs/measurements/information-tensor-consumers-20261118.json.gz'
        record=json.loads(gzip.decompress(path.read_bytes()))
        expected=expected_outputs()
        validate(record,expected)
        for change in ['missing','slot','value','timing']:
            altered=copy.deepcopy(record)
            if change=='missing':
                altered['rows'].pop()
            elif change=='slot':
                altered['rows'][1]['slot']=0
            elif change=='value':
                result=json.loads(altered['rows'][0]['stdout'])
                result['result']['scalar']=[False,'1','1']
                altered['rows'][0]['stdout']=json.dumps(result)+'\n'
            else:
                altered['rows'][0]['wall_seconds']*=2
            with self.subTest(change=change), self.assertRaises(AssertionError):
                validate(altered,expected)


if __name__=='__main__':
    unittest.main()
