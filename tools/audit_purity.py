#!/usr/bin/env python3
"""A conservative source gate for the handwritten symbolic kernel.

Not a compiler proof: derived code, runtime and termination are outside its scope.
Comments are lexed out; literal data are marked before checking tokens.
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parent.parent
FORBIDDEN = re.compile(
    r"\b(?:Int(?:8|16|32|64|128)?|UInt(?:8|16|32|64|128)?|Double|Float(?:32|64)?|BigInt|Byte|Char|"
    r"Array|FixedArray|ReadOnlyArray|Bytes|Map|Set|String|"
    r"mut|while|for|extern|unsafe|abort|panic|__MORPH_LITERAL__)\b"
    r"|\b\d[\w.]*|<<|>>|==|!=|\+|(?<![>-])-(?!>)|\*|/|%|\^|(?<!&)&(?!&)"
)

# This repository's monomorphic custom Eq header uses a type-level `for`.
# Mask only that token in a complete header. Executable `for` remains forbidden,
# including in the body of the same implementation; the compiler checks syntax.
EQ_IMPL_HEADER = re.compile(
    r"(?m)^[ \t]*(?:pub[ \t]+)?impl[ \t]+Eq[ \t]+(?P<keyword>for)"
    r"[ \t]+[A-Z][A-Za-z_0-9]*[ \t]+with[ \t]+fn[ \t]+equal[ \t]*\("
)


def code_only(source: str) -> str:
    # Keep line numbers; support nested block comments and escaped strings.
    out = list(source)
    i = 0
    depth = 0
    quote = None
    while i < len(source):
        if depth:
            if source.startswith("/*", i):
                depth += 1
                out[i:i+2] = "  "
                i += 2
            elif source.startswith("*/", i):
                depth -= 1
                out[i:i+2] = "  "
                i += 2
            else:
                if source[i] != "\n":
                    out[i] = " "
                i += 1
        elif quote:
            if source[i] == "\\":
                out[i:i+2] = "  "
                i += 2
            else:
                if source[i] == quote:
                    quote = None
                if source[i] != "\n":
                    out[i] = " "
                i += 1
        elif source.startswith("//", i):
            end = source.find("\n", i)
            end = len(source) if end < 0 else end
            out[i:end] = " " * (end - i)
            i = end
        elif source.startswith("/*", i):
            depth = 1
            out[i:i+2] = "  "
            i += 2
        elif source[i] in {'"', "'"}:
            quote = source[i]
            out[i] = " __MORPH_LITERAL__ "
            i += 1
        else:
            i += 1
    code = "".join(out)
    out = list(code)
    for header in EQ_IMPL_HEADER.finditer(code):
        start, end = header.span('keyword')
        out[start:end] = ' ' * (end - start)
    return "".join(out)


def main() -> int:
    failures = []
    count = 0
    for path in sorted((ROOT / "src").rglob("*.mbt")):
        rel = path.relative_to(ROOT)
        if path.name.endswith(("_test.mbt", "_wbtest.mbt")) or rel.parts[1] in {"testsupport", "cmd"}:
            continue
        count += 1
        source = code_only(path.read_text())
        for match in FORBIDDEN.finditer(source):
            line = source.count("\n", 0, match.start()) + 1
            failures.append(f"{rel}:{line}: forbidden token {match.group()!r}")
    # The independent numeric oracle may only be imported by tests or examples.
    for path in sorted((ROOT / "src").rglob("moon.pkg")):
        if path.relative_to(ROOT).parts[1] in {"testsupport", "cmd"}:
            continue
        source = path.read_text()
        for block in re.finditer(r"import\s*\{([^}]+)\}([^\n]*)", source):
            if "testsupport" in block[1] and not re.search(r'for\s+"(?:test|wbtest)"', block[2]):
                failures.append(f"{path.relative_to(ROOT)}: oracle imported by production")
    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    print(f"Purity gate passed: {count} kernel files; no machine numerics, mutation, arrays or FFI.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
