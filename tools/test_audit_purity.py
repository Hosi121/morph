import unittest
from audit_purity import FORBIDDEN, code_only


class PurityGateTests(unittest.TestCase):
    def test_numeric_aliases_operators_and_data_literals_are_rejected(self):
        for source in [
            "let x : Int32 = input()", "let x : UInt64 = input()",
            "let x : Float32 = input()", "let x = a + b", "let x = a << b",
            "let x = a ^ b", "let x = a & b", "let x = 42",
            'let x = "41"', "let x = 'a'", 'extern "js" fn f()',
            "let mut x = Nil", "let x : Array[Bool] = empty()",
        ]:
            with self.subTest(source=source):
                self.assertIsNotNone(FORBIDDEN.search(code_only(source)))

    def test_symbolic_syntax_and_numeric_documentation_are_allowed(self):
        source = '''// SHA-256 uses 32-bit words, not Int32 values here.
/* outer 42 /* nested "quoted" */ still comment */
fn f(n : Nat) -> Nat {
  match n { Zero => Succ(Zero); Succ(x) => x }
}
'''
        self.assertIsNone(FORBIDDEN.search(code_only(source)))
        self.assertEqual(source.count("\n"), code_only(source).count("\n"))

    def test_comment_markers_inside_literals_are_not_comments(self):
        code = code_only('let x = "/* // \\\" */"\nlet y = Succ(Zero)')
        self.assertIn("__MORPH_LITERAL__", code)
        self.assertIn("let y = Succ(Zero)", code)

    def test_complete_custom_eq_header_is_type_syntax(self):
        source = 'pub impl Eq for Gaussian with fn equal(self, other) { self.mean.equal(other.mean) }'
        self.assertIsNone(FORBIDDEN.search(code_only(source)))
        self.assertEqual(len(source), len(code_only(source)))

    def test_executable_for_remains_forbidden_even_inside_eq(self):
        sources = [
            'pub impl Eq for Gaussian with fn equal(self, other) { for item in values { use(item) }; true }',
            'fn f() { for value in values { use(value) } }',
            'impl Eq for Gaussian { for value in values { use(value) } }',
            'let header = "pub impl Eq for Gaussian with fn equal("',
        ]
        for source in sources:
            with self.subTest(source=source):
                self.assertIsNotNone(FORBIDDEN.search(code_only(source)))


if __name__ == "__main__":
    unittest.main()
