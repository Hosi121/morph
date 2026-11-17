import unittest
from compare_field_kernels import normalized


class CheckedBenchmarkOutputTests(unittest.TestCase):
    def test_ignores_only_timing_and_preserves_result_contract(self):
        a = {"checked": True, "fixture": "matrix", "iterations": 20, "checksum": 17, "elapsed_us": 5.1}
        b = dict(a, elapsed_us=8)
        self.assertEqual(normalized(a), normalized(b))
        self.assertNotEqual(normalized(a), normalized(dict(b, checksum=18)))
        self.assertNotEqual(normalized(a), normalized(dict(b, iterations=21)))

    def test_requires_positive_checked_flag(self):
        for payload in ({}, {"checked": False}, {"checked": 1}, [], None):
            with self.assertRaises(ValueError):
                normalized(payload)

    def test_rejects_invalid_timing(self):
        for value in (True, -1, "5", float("nan"), float("inf")):
            with self.assertRaises(ValueError):
                normalized({"checked": True, "elapsed_us": value})


if __name__ == "__main__":
    unittest.main()
