#!/usr/bin/env python3
"""Reject trivial numeral roundtrips and report static library references.

This is a lexical maintenance gate, not a reachability or compiler proof.
"""
from pathlib import Path
import argparse
import re
import sys

from audit_purity import code_only

ROOT = Path(__file__).resolve().parent.parent
REPORT = ROOT / "docs/CALL_PATHS.md"
SYMBOLS = ("core.gcd", "core.interleave", "binary.stein_gcd", "binary.karatsuba",
           "core.half_nat", "core.halve_nat", "core.replicate_onto")


def call(expression):
    expression = expression.strip().removesuffix(",").strip()
    match = re.match(r"@([\w]+)\.([\w]+)\s*\(", expression)
    if not match:
        return None
    depth = 1
    end = match.end()
    while end < len(expression) and depth:
        depth += (expression[end] == "(") - (expression[end] == ")")
        end += 1
    if depth or expression[end:].strip():
        return None
    return match[1], match[2], expression[match.end():end-1]


def roundtrips(source, aliases=("binary",)):
    source = code_only(source)
    result = []
    for match in re.finditer(r"@([\w]+)\.(to_nat|from_nat)\s*\(", source):
        if match[1] not in aliases:
            continue
        depth, end = 1, match.end()
        while end < len(source) and depth:
            depth += (source[end] == "(") - (source[end] == ")")
            end += 1
        outer = call(source[match.start():end])
        if outer is None:
            continue
        inner = call(outer[2])
        kind = None
        if inner and inner[0] == outer[0]:
            if (outer[1], inner[1]) in (("to_nat", "from_nat"), ("from_nat", "to_nat")):
                kind = "identity numeral roundtrip"
            if outer[1] == "to_nat" and inner[1] == "half":
                leaf = call(inner[2])
                if leaf and leaf[:2] == (outer[0], "from_nat"):
                    kind = "Nat halving through Binary: use core.half_nat"
        if kind:
            result.append((source.count("\n", 0, match.start()) + 1, kind))
    return result


def imports(folder):
    source = (folder / "moon.pkg").read_text()
    return {alias or package.split("/")[-1]: package
            for package, alias in re.findall(r'"Hosi121/morph/([^"\n]+)"(?:\s+@([\w]+))?', source)}


def word_hex_misuse(source, word_aliases=('oracle',), binary_aliases=('binary',)):
    """Reject the direct wrong-endianness/unpadded Binary -> hex-word route."""
    source = code_only(source)
    result = []
    for match in re.finditer(r'@([\w]+)\.hex_bits\s*\(', source):
        if match[1] not in word_aliases:
            continue
        depth, end = 1, match.end()
        while end < len(source) and depth:
            depth += (source[end] == '(') - (source[end] == ')')
            end += 1
        outer = call(source[match.start():end])
        inner = call(outer[2]) if outer else None
        if inner and inner[0] in binary_aliases and inner[1] == 'bits':
            result.append((source.count('\n',0,match.start())+1,
                           'Binary bits are little endian and unpadded: use a complete numeric hex formatter'))
    return result


def inventory():
    references = {symbol: {"body": [], "test": [], "demo": []} for symbol in SYMBOLS}
    failures = []
    runbinary_importers = []
    for manifest in sorted((ROOT / "src").rglob("moon.pkg")):
        folder = manifest.parent
        package = str(folder.relative_to(ROOT / "src"))
        aliases = imports(folder)
        for path in sorted(folder.glob("*.mbt")):
            relative = path.relative_to(ROOT)
            category = "test" if path.name.endswith(("_test.mbt", "_wbtest.mbt")) else "body"
            if relative.parts[1] in {"cmd", "testsupport"}:
                category = "demo"
            text = path.read_text()
            failures.extend(f"{relative}:{line}: {message}" for line, message in word_hex_misuse(
                text, [a for a,p in aliases.items() if p=='testsupport'],
                [a for a,p in aliases.items() if p=='binary']))
            if category == "body":
                binary_aliases = [a for a, p in aliases.items() if p == "binary"]
                failures.extend(f"{relative}:{line}: {message}" for line, message in roundtrips(text, binary_aliases))
            # moon fmt's top-level markers make owner names explicit. Nested
            # helper recursion remains in its enclosing public function block.
            starts = [0] + [m.end() for m in re.finditer(r"(?m)^///\|[^\n]*\n", text)]
            for start, end in zip(starts, starts[1:] + [len(text)]):
                block = code_only(text[start:end])
                owner = re.search(r"\bfn(?:\[[^\]]+\])?\s+(\w+)\s*\(", block)
                owner_name = owner[1] if owner else None
                base_line = text.count("\n", 0, start)
                for match in re.finditer(r"@([\w]+)\.([\w]+)\b", block):
                    target = f"{aliases.get(match[1], '?')}.{match[2]}"
                    if target in references:
                        references[target][category].append((str(relative), base_line + block.count("\n", 0, match.start()) + 1))
                    if category == "body" and package != "runbinary" and aliases.get(match[1]) == "runbinary":
                        runbinary_importers.append(str(relative))
                for symbol in SYMBOLS:
                    target_package, name = symbol.split(".")
                    if target_package != package or owner_name == name:
                        continue
                    for match in re.finditer(r"(?<![\w.@])" + re.escape(name) + r"\s*\(", block):
                        references[symbol][category].append((str(relative), base_line + block.count("\n", 0, match.start()) + 1))
    return references, failures, sorted(set(runbinary_importers))


def render(references, importers):
    lines = ["# 本体からの静的参照と変換経路", "",
             "[ドキュメント](README.md) / [基礎部品の最適化](KERNELS.md)", "",
             "`python3 tools/audit_paths.py --write`で生成する。",
             "本体は通常の.mbt、test/demoは別集計。コメント・文字列・自己再帰は参照に数えない。",
             "関数引数としての参照も含む。静的な字句参照であり、実行頻度や到達可能性の証明ではない。",
             "内部参照がなくても、public APIは通常のライブラリ本体に含まれる。「テスト専用」とは区別する。", "",
             "| symbol | 本体の参照 | test/demo参照 | 現在の分類 |", "| --- | ---: | ---: | --- |"]
    for symbol, groups in references.items():
        body = sorted(set(groups["body"]))
        other = len(set(groups["test"] + groups["demo"]))
        classification = "本体から参照あり" if body else "公開API・内部の呼出しなし"
        lines.append(f"| `{symbol}` | {len(body)} | {other} | {classification} |")
    lines += ["", f"`runbinary`の他package本体からの参照：{len(importers)}ファイル。",
              "現時点では独立した公開実装で、通常Binaryの代替backendとして全体へ組み込んだとは扱わない。", "",
              "## 本体の参照位置", ""]
    for symbol, groups in references.items():
        body = sorted(set(groups["body"]))
        if body:
            links = ", ".join(f"[{p}:{line}](../{p}#L{line})" for p, line in body)
            lines.append(f"- `{symbol}`: {links}")
    lines += ["", "## 変換ゲートの範囲", "",
              "直接のto_nat(from_nat(...))、逆方向の恒等変換、to_nat(half(from_nat(...)))を拒否する。",
              "変数を介する経路や一般の意味の同値性はこの字句ゲートだけでは証明しない。",
              "testsupport.hex_bits(binary.bits(...))も拒否する。前者はbig-endianの4bit単位word用で、数のlittle-endian列は直接渡せない。",
              "既約性検査の二箇所と円分体の半分化はcore.half_natを使う。",
              "Binary converterは半分化の共有を経て、現在は三bitずつ出す専用の8進helperへ進めた。",
              "IDの二進cache、係数/指数への入力変換、明示的な展開境界は別の意味を持つので一括置換しない。",
              "残るto_natは、Fpのp乗根のstride、展開上限を検査するrunbinary.expand、SHAの有限padding長などの境界にある。", ""]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    references, failures, importers = inventory()
    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    text = render(references, importers)
    if args.write:
        REPORT.write_text(text)
    elif args.check and (not REPORT.exists() or REPORT.read_text() != text):
        print("Call-path snapshot is stale: run python3 tools/audit_paths.py --write", file=sys.stderr)
        return 1
    print("Conversion gate passed; static library references recorded separately from tests.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
