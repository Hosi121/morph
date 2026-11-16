"""Check that immutable Binary initializers remain part of the source lock."""
from pathlib import Path
import tempfile
import unittest

from check_model_drift import constant_tokens, function_tokens


class ConstantRegionTests(unittest.TestCase):
    def tokens(self, source, function=False):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'constants.mbt'
            path.write_text(source)
            return (function_tokens if function else constant_tokens)(path, 'sample')

    def test_whitespace_and_comments_do_not_change_the_region(self):
        original = self.tokens('let sample : Binary = { bits: Cons(true, Nil), }')
        edited = self.tokens('// leading\nlet sample : Binary = {\n// comment\nbits: Cons(true, Nil),\n}\n')
        self.assertEqual(original, edited)

    def test_changed_initializer_is_detected(self):
        original = self.tokens('let sample : Binary = { bits: Cons(true, Nil), }')
        changed = self.tokens('let sample : Binary = { bits: Cons(false, Nil), }')
        self.assertNotEqual(original, changed)

    def test_alias_instead_of_a_record_requires_explicit_review(self):
        with self.assertRaises(ValueError):
            self.tokens('let sample : Binary = another\nfn other() -> Binary { another }')

    def test_function_fingerprints_keep_nested_bodies(self):
        original = self.tokens('fn sample() -> Binary { { bits: Cons(true, Nil), } }', function=True)
        changed = self.tokens('fn sample() -> Binary { { bits: Cons(false, Nil), } }', function=True)
        self.assertNotEqual(original, changed)


if __name__ == '__main__':
    unittest.main()
