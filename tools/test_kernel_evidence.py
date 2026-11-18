import copy
import json
from pathlib import Path
import unittest

from check_kernel_evidence import tensor


class KernelEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.root = Path(__file__).resolve().parent.parent
        self.record = json.loads((self.root / 'docs/measurements/tensor-kernel-20261118/abba.json').read_text())

    def test_consistently_modified_complete_payload_is_rejected(self):
        record = copy.deepcopy(self.record)
        for row in record['rows']:
            if row['case'] == 'permute-scalar':
                row['payload']['entries'][0] += 1
                row['stdout'] = json.dumps(row['payload'])
        with self.assertRaisesRegex(ValueError, 'Tensor complete output differs'):
            tensor(self.root, record)

    def test_modified_aggregate_is_rejected(self):
        record = copy.deepcopy(self.record)
        record['summary']['permute-tiny']['before_over_after'] += 1
        with self.assertRaisesRegex(ValueError, 'Tensor timing summary differs'):
            tensor(self.root, record)
