#!/usr/bin/env python3
"""Batch TOKENS STRIP v1.0.0 migration for feature screens."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FEATURES = ROOT / "lib" / "features"

SKIP = {
    "tokens_strip_showcase_screen.dart",
}

REPLACEMENTS = [
    (r"\bEagleTokens\.ink\b(?!\w)", "TokensStrip.textPrimary"),
    (r"\bEagleTokens\.inkMute\b", "TokensStrip.textSecondary"),
    (r"\bEagleTokens\.paper\b", "TokensStrip.pageBg"),
    (r"\bEagleTokens\.card\b", "TokensStrip.cardBg"),
    (r"\bEagleTokens\.lineSoft\b", "TokensStrip.borderDefault"),
    (r"\bEagleTokens\.line\b", "TokensStrip.borderDefault"),
    (r"\bEagleTokens\.brandInk\b", "TokensStrip.primaryHover"),
    (r"\bEagleTokens\.brand\b", "TokensStrip.primary"),
    (r"\bEagleTokens\.radiusXs\b", "TokensStrip.rInput"),
    (r"\bEagleTokens\.radiusSm\b", "TokensStrip.rCard"),
    (r"\bEagleTokens\.radiusMd\b", "TokensStrip.rXl"),
    (r"\bEagleTokens\.radiusLg\b", "TokensStrip.r2xl"),
]

SCAFFOLD_PATTERNS = [
    (
        "return Scaffold(\n      extendBody: true,\n      backgroundColor: Colors.transparent,\n      appBar:",
        "return FxShellScaffold(\n      useMesh: true,\n      appBar:",
    ),
    (
        "return Scaffold(\n      backgroundColor: Colors.transparent,\n      extendBody: true,\n      appBar:",
        "return FxShellScaffold(\n      useMesh: true,\n      appBar:",
    ),
    (
        "return Scaffold(\n      backgroundColor: Colors.transparent,\n      appBar:",
        "return FxShellScaffold(\n      useMesh: true,\n      appBar:",
    ),
]


def import_path(file: Path, suffix: str) -> str:
    rel = file.relative_to(ROOT / "lib")
    depth = len(rel.parts) - 1
    prefix = "../" * depth
    return f"import '{prefix}{suffix}';"


def ensure_import(content: str, file: Path, suffix: str, needle: str) -> str:
    if needle in content:
        return content
    if suffix.split("/")[-1] in content:
        return content
    line = import_path(file, suffix)
    match = re.search(r"^import .+;\n", content, re.MULTILINE)
    if not match:
        return line + "\n" + content
    insert_at = match.end()
    while True:
        nxt = re.search(r"^import .+;\n", content[insert_at:], re.MULTILINE)
        if not nxt:
            break
        insert_at += nxt.end()
    return content[:insert_at] + line + "\n" + content[insert_at:]


def migrate_file(file: Path) -> bool:
    if file.name in SKIP:
        return False

    original = file.read_text(encoding="utf-8")
    content = original

    for pattern, repl in REPLACEMENTS:
        content = re.sub(pattern, repl, content)

    for old, new in SCAFFOLD_PATTERNS:
        if old in content:
            content = content.replace(old, new)

    if "TokensStrip." in content:
        content = ensure_import(content, file, "core/theme/tokens_strip.dart", "tokens_strip.dart")

    if "FxShellScaffold(" in content:
        content = ensure_import(content, file, "core/widgets/fx_shell_scaffold.dart", "fx_shell_scaffold.dart")

    if "FxStripCard(" in content or "FxStripSectionTitle(" in content or "FxStripSectionLabel(" in content:
        content = ensure_import(content, file, "core/widgets/fx_strip_components.dart", "fx_strip_components.dart")

    if "FxLiquidPrimaryButton(" in content and "fx_motion.dart" not in content:
        content = ensure_import(content, file, "core/widgets/fx_motion.dart", "fx_motion.dart")

    if content == original:
        return False

    file.write_text(content, encoding="utf-8")
    return True


def main() -> None:
    changed = 0
    for dart in sorted(FEATURES.rglob("*screen*.dart")):
        if migrate_file(dart):
            changed += 1
            print(f"migrated: {dart.relative_to(ROOT)}")
    print(f"\nDone. {changed} files updated.")


if __name__ == "__main__":
    main()
