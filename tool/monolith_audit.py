#!/usr/bin/env python3
"""Report and split monolithic screens (entry >900 or bundle >900)."""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
FEATURES = REPO / "lib" / "features"
EXCLUDE = {
    "lib/features/qa/screens/qa_smoke_screen.dart",
    "lib/features/qa/screens/tokens_strip_showcase_screen.dart",
}


def bundle_lines(main: Path) -> int:
    text = main.read_text(encoding="utf-8")
    base = main.stem
    parts = list(main.parent.glob(f"{base}*.part.dart"))
    sibling_parts = [p for p in main.parent.glob("*.part.dart") if p.name.startswith(base.replace("_screen", ""))]
    all_parts = set(parts) | set(sibling_parts)
    declared = re.findall(r"part\s+'([^']+\.part\.dart)';", text)
    for rel in declared:
        all_parts.add(main.parent / rel)
    total = len(text.splitlines())
    for p in all_parts:
        if p.exists():
            total += len(p.read_text(encoding="utf-8").splitlines())
    return total


def find_screens() -> list[tuple[int, int, str]]:
    rows: list[tuple[int, int, str]] = []
    for f in FEATURES.rglob("*_screen.dart"):
        rel = str(f.relative_to(REPO)).replace("\\", "/")
        if rel in EXCLUDE:
            continue
        entry = len(f.read_text(encoding="utf-8").splitlines())
        bundle = bundle_lines(f)
        if entry > 900 or bundle > 900:
            rows.append((entry, bundle, rel))
    rows.sort(key=lambda x: x[1], reverse=True)
    return rows


def split_screen(rel_path: str) -> None:
    path = REPO / rel_path
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)

    # Find imports end (last import line)
    import_end = 0
    for i, line in enumerate(lines):
        if line.startswith("import ") or line.startswith("part "):
            import_end = i + 1

    # Providers / top-level before first class
    first_class = next(i for i, l in enumerate(lines) if l.startswith("class "))
    widget_class_end = first_class
    while widget_class_end < len(lines) and not lines[widget_class_end].startswith("class _"):
        widget_class_end += 1
    if widget_class_end >= len(lines):
        widget_class_end = first_class + 1
        while widget_class_end < len(lines) and not (
            lines[widget_class_end].startswith("class ") and lines[widget_class_end] != lines[first_class]
        ):
            widget_class_end += 1

    # State class: from first _Class to first private widget class at column 0
    state_start = next(
        i for i, l in enumerate(lines) if l.startswith("class _") and "State" in l
    )
    widgets_start = None
    for i in range(state_start + 1, len(lines)):
        if lines[i].startswith("class _") and "State" not in lines[i]:
            widgets_start = i
            break
    if widgets_start is None:
        widgets_start = len(lines)

    stem = path.stem
    state_part = f"{stem}_state.part.dart"
    widgets_part = f"{stem}_widgets.part.dart"

    entry = lines[:import_end]
    if not any("part '" in l for l in entry):
        entry.append(f"part '{state_part}';\n")
        if widgets_start < len(lines):
            entry.append(f"part '{widgets_part}';\n")
        entry.append("\n")
    entry.extend(lines[import_end:first_class])
    if widgets_start <= len(lines):
        # include widget class only
        entry.extend(lines[first_class:state_start])

    state_body = lines[state_start:widgets_start]
    widgets_body = lines[widgets_start:] if widgets_start < len(lines) else []

    path.write_text("".join(entry), encoding="utf-8")
    (path.parent / state_part).write_text(
        f"part of '{path.name}';\n\n" + "".join(state_body), encoding="utf-8"
    )
    if widgets_body:
        (path.parent / widgets_part).write_text(
            f"part of '{path.name}';\n\n" + "".join(widgets_body), encoding="utf-8"
        )


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "split":
        for target in sys.argv[2:]:
            split_screen(target)
            print(f"split {target}")
    elif len(sys.argv) > 1 and sys.argv[1] == "violations":
        fail = []
        for f in FEATURES.rglob("*_screen.dart"):
            rel = str(f.relative_to(REPO)).replace("\\", "/")
            if rel in EXCLUDE:
                continue
            entry = len(f.read_text(encoding="utf-8").splitlines())
            bundle = bundle_lines(f)
            has_parts = "part '" in f.read_text(encoding="utf-8")
            if entry > 900 or (bundle > 900 and not has_parts):
                fail.append((entry, bundle, has_parts, rel))
        fail.sort(key=lambda x: x[1], reverse=True)
        print(len(fail), "violations")
        for row in fail:
            print(row)
    else:
        for entry, bundle, rel in find_screens():
            print(f"{entry:4d} entry | {bundle:4d} bundle | {rel}")
