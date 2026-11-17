from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from check_affected import affected, imports, owner, verify_record, sha, running_child, argv_for, checkpoint_lock


class AffectedPlanTests(unittest.TestCase):
    def test_removed_import_keeps_old_reverse_consumer(self):
        roots, packages = affected({'a': set(), 'b': {'a'}, 'c': {'b'}},
                                   {'a': set(), 'b': set(), 'c': {'b'}}, ['src/a/data.mbt'])
        self.assertEqual(roots, ['a'])
        self.assertEqual(packages, ['a', 'b', 'c'])

    def test_new_import_selects_new_reverse_consumer(self):
        _, packages = affected({'a': set(), 'b': set()}, {'a': set(), 'b': {'a'}}, ['src/a/data.mbt'])
        self.assertEqual(packages, ['a', 'b'])

    def test_deleted_package_is_not_executed_but_its_old_consumer_is(self):
        roots, packages = affected({'gone': set(), 'user': {'gone'}}, {'user': set()}, ['src/gone/data.mbt'])
        self.assertEqual(roots, ['gone'])
        self.assertEqual(packages, ['user'])

    def test_nested_package_owner_is_exact_not_a_prefix_collision(self):
        self.assertEqual(owner('src/cmd/a/item.mbt', {'cmd', 'cmd/a', 'cmd/ab'}), 'cmd/a')
        self.assertIsNone(owner('src/cmd/abc/item.mbt', {'cmd/a', 'cmd/ab'}))

    def test_whitebox_import_aliases_are_in_the_graph(self):
        self.assertEqual(imports('import { "Hosi121/morph/a" @alias, } for "wbtest"'), {'a'})

    def test_unknown_changed_source_requires_a_decision(self):
        with self.assertRaisesRegex(ValueError, 'no package'):
            affected({}, {}, ['src/unowned/data.mbt'])

    def test_empty_source_scope_never_defaults_to_all_moon_tests(self):
        command = argv_for('tests-native', Path('/unused'), [])
        self.assertEqual(command[0], 'python3')
        self.assertNotIn('tools/moon', command)


class CheckpointTests(unittest.TestCase):
    def test_source_tamper_is_rejected_even_with_same_git_head(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'a.mbt').write_text('before')
            report = {'source_commit': 'fixed', 'source_files': {'a.mbt': sha(root / 'a.mbt')}, 'commands': []}
            git = lambda *args: 'fixed'
            verify_record(root, report, git)
            (root / 'a.mbt').write_text('after')
            with self.assertRaisesRegex(ValueError, 'Source drift'):
                verify_record(root, report, git)

    def test_completed_log_tamper_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'test.log').write_text('passed')
            report = {'source_commit': 'fixed', 'source_files': {}, 'commands': [
                {'name': 'tests-js', 'returncode': 0, 'log': 'test.log', 'sha256': sha(root / 'test.log')}]}
            (root / 'test.log').write_text('replacement')
            with self.assertRaisesRegex(ValueError, 'log drift'):
                verify_record(root, report, lambda *args: 'fixed')

    def test_record_lock_refuses_duplicate_and_releases_cleanly(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'run.json'
            with checkpoint_lock(path):
                with self.assertRaisesRegex(ValueError, 'owns this record'):
                    with checkpoint_lock(path):
                        self.fail('Duplicate checkpoint owner')
            with checkpoint_lock(path):
                pass

    def test_missing_process_token_is_not_a_live_child(self):
        with patch('check_affected.process_token', return_value=None):
            self.assertFalse(running_child({'child_pid': 1, 'child_token': None}))
            self.assertFalse(running_child({'child_pid': 1, 'child_token': 'old'}))

    def test_pid_reuse_is_not_a_live_original_child(self):
        with patch('check_affected.process_token', return_value='new'):
            self.assertFalse(running_child({'child_pid': 1, 'child_token': 'old'}))
            self.assertTrue(running_child({'child_pid': 1, 'child_token': 'new'}))


if __name__ == '__main__':
    unittest.main()
