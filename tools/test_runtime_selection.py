from pathlib import Path
import json
import tempfile
import unittest
from unittest.mock import patch

from check_affected import (runtime_selection, zero_test_command, TEST_INFO_KEYS,
                            argv_for, verify_record, initialize)


class RuntimeSelectionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / 'moon.mod').write_text('name = "fixture"\nsource = "src"\n')

    def package(self, package='cmd/zero', source='fn main {}', extra=None, config=None):
        path = self.root / 'src' / package
        path.mkdir(parents=True)
        (path / 'moon.pkg').write_text(config or 'pkgtype(kind: "executable")\n')
        (path / 'main.mbt').write_text(source)
        for name, text in (extra or {}).items():
            (path / name).write_text(text)
        info = {key: {p.name: [] for p in path.glob('*.mbt')} for key in TEST_INFO_KEYS}
        directory = self.root / '_build/native/release/test' / package
        directory.mkdir(parents=True)
        for kind in ('internal', 'blackbox'):
            (directory / ('__' + kind + '_test_info.json')).write_text(json.dumps(info))
        return path

    def assert_kept(self, **args):
        self.package(**args)
        package = args.get('package', 'cmd/zero')
        self.assertEqual(runtime_selection(self.root, [package]), ([package], []))

    def test_zero_test_command_skips_and_preserves_graph_input(self):
        self.package()
        selected = ['cmd/zero', 'module', 'testsupport']
        runtime, skipped = runtime_selection(self.root, selected)
        self.assertEqual(runtime, ['module', 'testsupport'])
        self.assertEqual(selected, ['cmd/zero', 'module', 'testsupport'])
        self.assertEqual(skipped[0]['source_count'], 1)
        self.assertEqual(skipped[0]['test_file_count'], 0)
        self.assertEqual(len(skipped[0]['native_empty_metadata']), 2)
        self.assertEqual(argv_for('tests-native', self.root, runtime)[2:4], ['src/module', 'src/testsupport'])
        self.assertNotIn('src/cmd/zero', argv_for('tests-native', self.root, runtime))
        self.assertEqual(argv_for('check-native', self.root, selected), argv_for('check-native', self.root, runtime))
        self.assertEqual(argv_for('tests-js', self.root, [])[0], 'python3')

    def test_initialize_freezes_distinct_graph_and_runtime_sets(self):
        self.package(config='import { "Hosi121/morph/module", }\npkgtype(kind: "executable")\n')
        module = self.root / 'src/module'
        module.mkdir()
        (module / 'moon.pkg').write_text('')
        (module / 'source.mbt').write_text('fn value {}')
        paths = ['src/module/moon.pkg', 'src/cmd/zero/moon.pkg']
        def git(*args):
            if args[0] == 'rev-parse':
                return 'fixed'
            if args[0] == 'status':
                return ''
            if args[0] == 'ls-tree':
                return '\n'.join(paths)
            if args[0] == 'show':
                return (self.root / args[1].split(':', 1)[1]).read_text().strip()
            if args[0] == 'ls-files':
                return '\n'.join(str(p.relative_to(self.root)) for p in self.root.rglob('*') if p.is_file())
            if args[:3] == ('diff', '--name-only', '--no-renames'):
                return 'src/module/source.mbt'
            return ''
        with patch('check_affected.subprocess.check_output', return_value='fixture compiler'):
            record = initialize(self.root, self.root / 'record.json', 'base', [], git)
        self.assertEqual(record['packages'], ['cmd/zero', 'module'])
        self.assertEqual(record['runtime_packages'], ['module'])
        self.assertEqual([p['package'] for p in record['skipped_zero_test_commands']], ['cmd/zero'])

    def test_inline_test_kept_despite_stale_empty_metadata(self):
        self.assert_kept(source='test "inline" { assert_true(true) }')

    def test_whitebox_and_blackbox_files_keep(self):
        for name in ('extra_wbtest.mbt', 'extra_test.mbt'):
            with self.subTest(name=name):
                package = 'cmd/' + name
                self.assert_kept(package=package, extra={name: '// empty test file still keeps'})

    def test_conditional_native_test_kept(self):
        self.assert_kept(source='#cfg(target="native")\ntest "native" { }')

    def test_documentation_fence_and_test_word_in_comment_keep(self):
        self.assert_kept(source='/// ```mbt\n/// fn example {}\n/// ```\nfn main {}')
        self.assert_kept(package='cmd/comment', source='// future test\nfn main {}')

    def test_generated_source_and_unknown_configuration_keep(self):
        self.assert_kept(config='pkgtype(kind: "executable")\npre-build = "generate"\n')
        self.assert_kept(package='cmd/conditional', config='pkgtype(kind: "executable")\noptions(targets: ["native"])')

    def test_module_generation_hook_keeps_command(self):
        self.package()
        with (self.root / 'moon.mod').open('a') as output:
            output.write('pre_build = "generate"\n')
        self.assertIsNone(zero_test_command(self.root, 'cmd/zero'))

    def test_normal_module_and_testsupport_always_keep(self):
        self.assert_kept(package='normal')
        self.assert_kept(package='testsupport')

    def test_missing_source_or_metadata_keeps(self):
        path = self.package()
        (path / 'main.mbt').unlink()
        self.assertIsNone(zero_test_command(self.root, 'cmd/zero'))
        self.package(package='cmd/no_metadata')
        (self.root / '_build/native/release/test/cmd/no_metadata/__internal_test_info.json').unlink()
        self.assertIsNone(zero_test_command(self.root, 'cmd/no_metadata'))

    def test_nonempty_unknown_or_malformed_metadata_keeps(self):
        self.package()
        path = self.root / '_build/native/release/test/cmd/zero/__internal_test_info.json'
        for info in ({'new_kind': {}}, {'tests': {'main.mbt': ['native test']}}, []):
            path.write_text(json.dumps(info))
            self.assertIsNone(zero_test_command(self.root, 'cmd/zero'))
        path.write_text('{invalid')
        self.assertIsNone(zero_test_command(self.root, 'cmd/zero'))

    def test_new_untracked_test_after_initialization_invalidates_record(self):
        path = self.package()
        _, skipped = runtime_selection(self.root, ['cmd/zero'])
        record = {'source_commit': 'fixed', 'source_files': {}, 'commands': [],
                  'skipped_zero_test_commands': skipped}
        verify_record(self.root, record, lambda *args: 'fixed')
        (path / 'new_test.mbt').write_text('test "new" {}')
        with self.assertRaisesRegex(ValueError, 'Runtime selection drift'):
            verify_record(self.root, record, lambda *args: 'fixed')


if __name__ == '__main__':
    unittest.main()
