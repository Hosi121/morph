from pathlib import Path
import copy
import gzip
import hashlib
import json
import tempfile
import unittest

from check_evidence import comparison, validation, local
from structure_evidence import check_reference


class EvidenceTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)

    def fixture(self):
        payload = {'checked': True, 'result': [1, 0, 1]}
        runs = [dict(case='a', group=0, position=i, variant=s, checked=True, exit_code=0,
                     process_ns=10 if s == 'before' else 5,
                     payload=copy.deepcopy(payload), stdout=json.dumps(payload), stderr='')
                for i, s in enumerate(['before', 'after', 'after', 'before'])]
        return dict(all_checked=True, groups=1, order=['before', 'after', 'after', 'before'], runs=runs,
                    summary={'a': {'process_ns': {'medians': {'before': 10, 'after': 5},
                             'ranges': {'before': [10, 10], 'after': [5, 5]},
                             'before_over_after': 2.0, 'block_ratios': [2.0]}}})

    def pack(self, full):
        raw = json.dumps(full).encode()
        compressed = gzip.compress(raw)
        (self.root / 'full.gz').write_bytes(compressed)
        summary = {k: v for k, v in full.items() if k != 'runs'}
        summary['run_count'] = len(full['runs'])
        summary['lossless_full_record'] = dict(path='full.gz', sha256=hashlib.sha256(compressed).hexdigest(),
                                             uncompressed_sha256=hashlib.sha256(raw).hexdigest())
        return summary

    def test_valid_complete_comparison(self):
        comparison(self.root, self.pack(self.fixture()))

    def test_compressed_tamper(self):
        summary = self.pack(self.fixture())
        (self.root / 'full.gz').write_bytes(b'replaced')
        with self.assertRaisesRegex(ValueError, 'Compressed evidence hash'):
            comparison(self.root, summary)

    def test_wrong_raw_digest(self):
        summary = self.pack(self.fixture())
        summary['lossless_full_record']['uncompressed_sha256'] = '0' * 64
        with self.assertRaisesRegex(ValueError, 'Raw evidence hash'):
            comparison(self.root, summary)

    def test_different_results_cannot_hide_behind_checked_flag(self):
        full = self.fixture()
        full['runs'][1]['payload']['result'] = [0]
        full['runs'][1]['stdout'] = json.dumps(full['runs'][1]['payload'])
        with self.assertRaisesRegex(ValueError, 'Unequal complete results'):
            comparison(self.root, self.pack(full))

    def test_stdout_and_payload_must_agree(self):
        full = self.fixture()
        full['runs'][1]['stdout'] = '{}'
        with self.assertRaisesRegex(ValueError, 'stdout/payload differ'):
            comparison(self.root, self.pack(full))

    def test_missing_run_rejected_even_if_counts_and_hashes_rewritten(self):
        full = self.fixture()
        full['runs'].pop()
        with self.assertRaisesRegex(ValueError, 'Missing ABBA slot'):
            comparison(self.root, self.pack(full))

    def test_wrong_aggregate_rejected_even_if_both_records_agree(self):
        full = self.fixture()
        full['summary']['a']['process_ns']['before_over_after'] = 9
        with self.assertRaisesRegex(ValueError, 'Timing summary differs'):
            comparison(self.root, self.pack(full))

    def test_summary_copy_cannot_drift_from_raw(self):
        summary = self.pack(self.fixture())
        summary['groups'] = 2
        with self.assertRaisesRegex(ValueError, 'Summary differs'):
            comparison(self.root, summary)

    def test_repository_path_traversal_rejected(self):
        with self.assertRaisesRegex(ValueError, 'escapes repository'):
            local(self.root, '../outside')

    def structure_fixture(self):
        root = Path(__file__).resolve().parent.parent
        path = root / 'docs/measurements/structure-gaussian-20261118-summary.json'
        summary = json.loads(path.read_text())
        full = json.loads(gzip.decompress((root / summary['lossless_full_record']['path']).read_bytes()))
        return root, summary, full

    def test_exact_external_reference_report(self):
        root, summary, _ = self.structure_fixture()
        comparison(root, summary)

    def test_consistent_result_tamper_cannot_change_independent_reference(self):
        root, _, full = self.structure_fixture()
        for run in full['runs']:
            run['payload']['iterations'] = 999
            run['stdout'] = json.dumps(run['payload'])
        for payload in full['reference_payloads'].values():
            payload['iterations'] = 999
        with self.assertRaisesRegex(ValueError, 'Independent reference payload differs'):
            check_reference(root, full)

    def test_source_manifest_member_hash_checked(self):
        root, _, full = self.structure_fixture()
        full['source_archives']['before']['files']['moon.mod'] = '0' * 64
        with self.assertRaisesRegex(ValueError, 'Source member hash mismatch'):
            check_reference(root, full)

    def test_hessian_report_reconstructed_from_independent_metric_jet(self):
        root = Path(__file__).resolve().parent.parent
        record = json.loads((root / 'docs/measurements/structure-hessian-20261118-summary.json').read_text())
        comparison(root, record)

    def test_hessian_reference_script_hash_checked(self):
        root = Path(__file__).resolve().parent.parent
        record = json.loads((root / 'docs/measurements/structure-hessian-20261118-summary.json').read_text())
        full = json.loads(gzip.decompress((root / record['lossless_full_record']['path']).read_bytes()))
        first = next(iter(full['reference_files']))
        full['reference_files'][first] = '0' * 64
        with self.assertRaisesRegex(ValueError, 'Frozen reference/source hash mismatch'):
            check_reference(root, full)

    def log_fixture(self):
        data = b'header\npassed\n'
        (self.root / 'log.txt').write_bytes(data)
        return dict(status='passed', published_log_sha256=hashlib.sha256(data).hexdigest(), commands=[
            dict(name='test', returncode=0, sha256=hashlib.sha256(b'passed\n').hexdigest(),
                 published_log=dict(path='log.txt', offset_bytes=7, length_bytes=7))])

    def test_log_byte_spans_verified(self):
        validation(self.root, self.log_fixture())

    def test_log_digest_tamper(self):
        record = self.log_fixture()
        record['commands'][0]['sha256'] = '0' * 64
        with self.assertRaisesRegex(ValueError, 'Command log hash'):
            validation(self.root, record)

    def test_overlapping_log_spans(self):
        record = self.log_fixture()
        duplicate = copy.deepcopy(record['commands'][0])
        duplicate['name'] = 'other'
        record['commands'].append(duplicate)
        with self.assertRaisesRegex(ValueError, 'Overlapping'):
            validation(self.root, record)


if __name__ == '__main__':
    unittest.main()
