from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from check_docs import check, heading_ids, prose, references


class DocumentationTests(unittest.TestCase):
    def fixture(self, files):
        temporary = TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        for name, content in files.items():
            path = root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
        return root

    def test_moved_page_breaks_relative_source_link(self):
        root = self.fixture({"README.md": "[guide](docs/guide.md)",
                             "docs/guide.md": "[source](src/kernel.mbt)",
                             "src/kernel.mbt": "code"})
        errors, _, _ = check(root)
        self.assertTrue(any("missing local target" in error for error in errors))

    def test_explicit_anchor_and_html_logo(self):
        root = self.fixture({"README.md": '<img src="logo.png" alt="morph">\n[guide](docs/a.md#entry)',
                             "logo.png": "test fixture", "docs/a.md": '<a id="entry"></a>\n# Guide'})
        self.assertEqual(check(root)[0], [])

    def test_missing_section_is_rejected(self):
        root = self.fixture({"README.md": "[guide](docs/a.md#removed)", "docs/a.md": "# Renamed"})
        self.assertTrue(any("missing section anchor" in error for error in check(root)[0]))

    def test_source_line_bounds_are_checked(self):
        root = self.fixture({"README.md": "[source](src/a.mbt#L3)", "src/a.mbt": "one\ntwo\n"})
        self.assertTrue(any("line anchor" in error for error in check(root)[0]))

    def test_fences_and_inline_code_are_not_links(self):
        text = '```sh\n[x](missing)\n```\n`[y](missing)`\n~~~\n[z](missing)\n~~~\n[real](actual.md)'
        self.assertEqual(references(text)[0], ["actual.md"])
        self.assertEqual(prose(text)[1], [])

    def test_unclosed_fence_is_rejected(self):
        self.assertTrue(prose("# Guide\n```sh\ncommand")[1])

    def test_orphan_document_is_rejected(self):
        root = self.fixture({"README.md": "# Project", "docs/orphan.md": "# Guide"})
        self.assertTrue(any("no documentation link" in error for error in check(root)[0]))

    def test_reference_links_and_encoded_paths(self):
        root = self.fixture({"README.md": "[guide][g]\n[g]: <docs/a%20b.md>", "docs/a b.md": "# Guide"})
        self.assertEqual(check(root)[0], [])
        self.assertTrue(references("[bad][missing]")[2])

    def test_external_urls_are_not_fetched(self):
        root = self.fixture({"README.md": '[remote](https://example.invalid/a#section)\n<img src="data:image/png;base64,AA==">'})
        self.assertEqual(check(root)[0], [])

    def test_duplicate_heading_and_temporary_navigation_loop(self):
        self.assertEqual(heading_ids("# Guide\n## Guide\n## 日本語"), {"guide", "guide-1", "日本語"})
        root = self.fixture({"README.md": "[a](docs/a.md)", "docs/a.md": "[b](b.md)", "docs/b.md": "[a](a.md)"})
        self.assertEqual(check(root)[0], [])

    def test_code_in_heading_keeps_the_visible_words(self):
        self.assertEqual(heading_ids("## Run `tools/check`"), {"run-toolscheck"})

    def test_personal_path_is_not_a_portable_doc_link(self):
        root = self.fixture({"README.md": "[local](../outside.md)"})
        self.assertTrue(any("outside the repository" in error for error in check(root)[0]))


if __name__ == "__main__":
    unittest.main()
