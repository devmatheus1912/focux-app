#!/usr/bin/env python3
"""Wrap feature screens without Semantics in fxScreenA11yScope."""

from __future__ import annotations

import re
import sys
from pathlib import Path

IMPORT_LINE = "import '../../../core/widgets/fx_screen_a11y.dart';"
IMPORT_LINE_ALT = "import 'package:focux_app/core/widgets/fx_screen_a11y.dart';"

SKIP_FILES = {
    "qa_smoke_screen.dart",
}

ROOT_WIDGETS = ("FxShellScaffold", "Scaffold", "FeatureGate")


def extract_label(source: str, path: Path) -> str:
    for pattern in (
        r"FxShellAppBar\s*\(\s*title:\s*'([^']+)'",
        r"FxShellAppBar\s*\(\s*title:\s*\"([^\"]+)\"",
        r"AppBar\s*\(\s*title:\s*(?:const\s+)?Text\s*\(\s*'([^']+)'",
        r"title:\s*Text\s*\(\s*'([^']+)'",
    ):
        match = re.search(pattern, source)
        if match:
            return match.group(1)
    stem = path.stem.replace("_screen", "").replace("_", " ")
    return stem.title()


def find_matching_paren(source: str, open_index: int) -> int:
    depth = 0
    in_single = False
    in_double = False
    in_triple = False
    i = open_index
    while i < len(source):
        ch = source[i]
        nxt = source[i : i + 3]
        if in_triple:
            if nxt == "'''":
                in_triple = False
                i += 3
                continue
        elif in_single:
            if ch == "'" and source[i - 1] != "\\":
                in_single = False
        elif in_double:
            if ch == '"' and source[i - 1] != "\\":
                in_double = False
        else:
            if nxt == "'''":
                in_triple = True
                i += 3
                continue
            if ch == "'":
                in_single = True
            elif ch == '"':
                in_double = True
            elif ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0:
                    return i
        i += 1
    return -1


def add_import(source: str) -> str:
    if "fx_screen_a11y.dart" in source:
        return source
    lines = source.splitlines(keepends=True)
    last_import = 0
    for idx, line in enumerate(lines):
        if line.startswith("import "):
            last_import = idx
    insert = IMPORT_LINE + "\n"
    if "package:focux_app/" in source:
        insert = IMPORT_LINE_ALT + "\n"
    lines.insert(last_import + 1, insert)
    return "".join(lines)


def wrap_return_widget(source: str, label: str) -> str | None:
    for widget in ROOT_WIDGETS:
        pattern = re.compile(rf"\breturn\s+{widget}\s*\(")
        match = pattern.search(source)
        if not match:
            continue
        open_paren = source.index("(", match.end() - 1)
        close_paren = find_matching_paren(source, open_paren)
        if close_paren < 0:
            continue
        original = source[match.start() : close_paren + 1]
        indent_match = re.match(r"(\s*)return", original)
        indent = indent_match.group(1) if indent_match else "    "
        prefix = f"{indent}return "
        inner = original[len(prefix) :]
        wrapped = (
            f"{indent}return fxScreenA11yScope(\n"
            f"{indent}  label: '{label}',\n"
            f"{indent}  child: {inner},\n"
            f"{indent});"
        )
        return source[: match.start()] + wrapped + source[close_paren + 1 :]
    return None


def process_file(path: Path) -> bool:
    if path.name in SKIP_FILES:
        return False
    source = path.read_text(encoding="utf-8")
    if "Semantics(" in source or "fxScreenA11yScope(" in source:
        return False
    label = extract_label(source, path)
    updated = wrap_return_widget(source, label)
    if not updated:
        return False
    updated = add_import(updated)
    path.write_text(updated, encoding="utf-8")
    print(f"OK {path}")
    return True


def main() -> int:
    root = Path(__file__).resolve().parents[1] / "lib" / "features"
    changed = 0
    for path in sorted(root.rglob("*_screen.dart")):
        if process_file(path):
            changed += 1
    print(f"Updated {changed} screens")
    return 0


if __name__ == "__main__":
    sys.exit(main())
