"""Small exact reference systems for the full-system fixture oracle."""
from fractions import Fraction as Q
import unittest

from generate_linearspan_fixtures import fixtures, solve


class FullSystemOracleTests(unittest.TestCase):
    def test_zero_dimensional_and_empty_basis(self):
        self.assertEqual(solve([], []), [])
        self.assertEqual(solve([], [Q(0), Q(0)]), [])
        self.assertIsNone(solve([], [Q(0), Q(1)]))

    def test_reversed_pivots_with_exact_fractions(self):
        columns = [[Q(0), Q(1, 3)], [Q(1, 2), Q(0)]]
        self.assertEqual(solve(columns, [Q(3, 2), Q(1)]), [Q(3), Q(3)])

    def test_inconsistent_rectangular_system(self):
        columns = [[Q(0), Q(2, 3), Q(1, 2)]]
        self.assertEqual(solve(columns, [Q(0), Q(-2), Q(-3, 2)]), [Q(-3)])
        self.assertIsNone(solve(columns, [Q(1), Q(-2), Q(-3, 2)]))

    def test_corpus_preserves_frozen_shape_and_seed(self):
        cases = fixtures()
        self.assertEqual(cases, fixtures())
        self.assertEqual(len(cases), 15)
        self.assertEqual(sum(len(c["vectors"]) for c in cases), 120)
        for case in cases:
            self.assertEqual(sum(a is None for a in case["answers"]), case["dimension"])


if __name__ == "__main__":
    unittest.main()
