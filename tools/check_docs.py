#!/usr/bin/env python3
"""Check local documentation links, fragments, fenced blocks, and navigation.

This is a small repository check, not a complete Markdown renderer. External
URLs are not fetched. Code examples are excluded from link validation.
"""
from html import unescape
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit
import re
import sys
import unicodedata


ROOT = Path(__file__).resolve().parent.parent


def prose(text, inline=True):
    """Keep line numbers while removing fenced blocks and inline code."""
    lines, errors = [], []
    fence = None
    for number, line in enumerate(text.splitlines(), 1):
        match = re.match(r"^ {0,3}(`{3,}|~{3,})(.*)$", line)
        if fence:
            if match and match[1][0] == fence[0] and len(match[1]) >= fence[1] and not match[2].strip():
                fence = None
            lines.append("")
        elif match:
            fence = (match[1][0], len(match[1]), number)
            lines.append("")
        else:
            lines.append(re.sub(r"(`+)(.*?)\1", "", line) if inline else line)
    if fence:
        errors.append(f"line {fence[2]}: unclosed fenced code block")
    return "\n".join(lines), errors


class HtmlReferences(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self.ids = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if "id" in attrs:
            self.ids.append(attrs["id"])
        if tag == "a" and "name" in attrs:
            self.ids.append(attrs["name"])
        for attr in {"a": ["href"], "img": ["src"], "source": ["src", "srcset"]}.get(tag, []):
            if attr in attrs:
                values = attrs[attr].split(",") if attr == "srcset" else [attrs[attr]]
                self.links.extend(value.strip().split()[0] for value in values if value.strip())


def references(text):
    clean, errors = prose(text)
    html = HtmlReferences()
    html.feed(clean)
    links = list(html.links)
    pattern = r'!?\[[^\]\n]*\]\(\s*(?:<([^>\n]+)>|([^\s)\n]+))(?:\s+"[^"\n]*")?\s*\)'
    links.extend(match[1] or match[2] for match in re.finditer(pattern, clean))
    definitions = {
        match[1].strip().casefold(): match[2] or match[3]
        for match in re.finditer(r"(?m)^ {0,3}\[([^]\n]+)\]:\s*(?:<([^>\n]+)>|(\S+))", clean)
    }
    for match in re.finditer(r"!?\[([^]\n]+)\]\[([^]\n]*)\]", clean):
        label = (match[2] or match[1]).strip().casefold()
        if label not in definitions:
            errors.append(f"undefined reference link: {label}")
        else:
            links.append(definitions[label])
    links.extend(definitions.values())
    return links, html.ids, errors


def heading_ids(text):
    # Explicit anchors are preferred for links into the handbook. Generated
    # heading IDs also support ordinary Unicode letters and duplicate headings.
    clean, _ = prose(text, inline=False)
    counts, result = {}, set()
    for match in re.finditer(r"(?m)^ {0,3}#{1,6}\s+(.+?)\s*#*\s*$", clean):
        label = unescape(re.sub(r"<[^>]*>", "", match[1])).lower()
        slug = "".join(c for c in label if c in " _-" or unicodedata.category(c)[0] in "LMN")
        slug = slug.replace(" ", "-")
        number = counts.get(slug, 0)
        counts[slug] = number + 1
        result.add(f"{slug}-{number}" if number else slug)
    return result


def documentation(root):
    files = {root / name for name in ("README.md", "HANDBOOK.md") if (root / name).exists()}
    for folder in ("docs", "formal", "assets/brand"):
        files.update((root / folder).rglob("*.md"))
    return sorted(files)


def check(root):
    root = root.resolve()
    files = documentation(root)
    errors, parsed, anchors, graph = [], {}, {}, {p: set() for p in files}
    for path in files:
        content = path.read_text()
        links, explicit, problems = references(content)
        parsed[path] = links
        anchors[path] = set(explicit) | heading_ids(content)
        errors.extend(f"{path.relative_to(root)}: {problem}" for problem in problems)
    total = 0
    for path, links in parsed.items():
        for link in links:
            url = urlsplit(unescape(link))
            if url.scheme or url.netloc:
                continue
            total += 1
            if url.path:
                base = root if url.path.startswith("/") else path.parent
                target = (base / unquote(url.path).lstrip("/")).resolve()
            else:
                target = path
            label = f"{path.relative_to(root)}: {link}"
            if not target.is_relative_to(root):
                errors.append(f"{label}: target is outside the repository")
                continue
            if not target.exists():
                errors.append(f"{label}: missing local target")
                continue
            if target in graph:
                graph[path].add(target)
            fragment = unquote(url.fragment)
            if not fragment:
                continue
            if target.suffix == ".md":
                if fragment not in anchors.get(target, set()):
                    errors.append(f"{label}: missing section anchor")
            elif re.fullmatch(r"L\d+(?:-L\d+)?", fragment):
                numbers = [int(n) for n in re.findall(r"\d+", fragment)]
                size = len(target.read_text().splitlines())
                if any(n < 1 or n > size for n in numbers) or numbers != sorted(numbers):
                    errors.append(f"{label}: line anchor is outside the file")
            else:
                errors.append(f"{label}: unsupported local fragment")
    seen, pending = set(), [root / "README.md"]
    while pending:
        current = pending.pop()
        if current in seen:
            continue
        seen.add(current)
        pending.extend(graph.get(current, ()))
    for path in files:
        if path.relative_to(root).parts[0] in {"docs", "formal"} and path not in seen:
            errors.append(f"{path.relative_to(root)}: no documentation link from README")
    return errors, len(files), total


def main():
    errors, files, links = check(ROOT)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"Documentation gate passed: {files} Markdown files, {links} local links; navigation is connected.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
