#!/usr/bin/env python3
"""Generate a deterministic source inventory, without claiming test execution."""
from pathlib import Path
import argparse
import re
import sys

ROOT = Path(__file__).resolve().parent.parent
DESTINATION = ROOT / "docs/INVENTORY.md"


def generate():
    packages = []
    for manifest in sorted((ROOT / "src").rglob("moon.pkg")):
        folder = manifest.parent
        relative = folder.relative_to(ROOT / "src")
        if relative.parts[0] in {"cmd", "testsupport", "benchmarks"}:
            continue
        sources = list(folder.glob("*.mbt"))
        kernels = [p for p in sources if not p.name.endswith(("_test.mbt", "_wbtest.mbt"))]
        if not kernels:
            continue
        tests = benches = 0
        for path in sources:
            for match in re.finditer(r'^test\s+"(?:[^"\\]|\\.)*"\s*(\([^)]*\))?', path.read_text(), re.M):
                if match[1] and "@bench.T" in match[1]:
                    benches += 1
                else:
                    tests += 1
        dependencies = []
        for block in re.finditer(r'import\s*\{([^}]+)\}([^\n]*)', manifest.read_text()):
            if re.search(r'\bfor\s+"(?:test|wbtest)"', block[2]):
                continue
            dependencies.extend(re.findall(r'"Hosi121/morph/([^"\n]+)"', block[1]))
        packages.append((str(relative), len(kernels), tests, benches, sorted(dependencies)))
    lines = [
        "# パッケージ一覧", "",
        "[ドキュメント](README.md) / [アルゴリズム一覧](ALGORITHMS.md)", "",
        "`python3 tools/inventory.py`で再生成する。手書きの集計値を正本にしない。",
        "テスト欄はソース上の宣言数で、成功数・独立性・網羅率を表さない。",
        "bench欄もgroup数で、group内部の個別計測数とは異なる。", "",
        f"算法の核：{len(packages)}パッケージ、{sum(p[1] for p in packages)}ソース。",
        f"核のテスト宣言：{sum(p[2] for p in packages)}、bench group：{sum(p[3] for p in packages)}。",
        "testsupport・cmd・benchmarksは核の集計から除外する。", "",
        "| パッケージ | 核ソース | テスト宣言 | bench group | 直接の核依存 |",
        "| --- | ---: | ---: | ---: | --- |",
    ]
    for name, kernels, tests, benches, dependencies in packages:
        dependencies = ", ".join(f"`{d}`" for d in dependencies) or "—"
        lines.append(f"| [{name}](../src/{name}) | {kernels} | {tests} | {benches} | {dependencies} |")
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="reject a stale inventory")
    args = parser.parse_args()
    content = generate()
    if args.check:
        if not DESTINATION.exists() or DESTINATION.read_text() != content:
            print("Source inventory is stale: run python3 tools/inventory.py", file=sys.stderr)
            return 1
        print("Source inventory is current.")
    else:
        DESTINATION.write_text(content)
        print(DESTINATION.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
