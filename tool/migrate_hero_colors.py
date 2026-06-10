#!/usr/bin/env python3
"""Replace inline Colors.white on teal heroes with dashboard_readability tokens."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGETS = [
    ROOT / "lib/features/treinos/screens/treinos_list_screen.dart",
    ROOT / "lib/features/checkin/screens/modo_presencial_screen.dart",
    ROOT / "lib/features/alertas/screens/alertas_screen.dart",
]

IMPORT = "import '../../dashboard/utils/dashboard_readability.dart';"
TOKENS_IMPORT = "import '../../../core/theme/tokens_strip.dart';"


def migrate(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    if IMPORT not in text and TOKENS_IMPORT in text:
        text = text.replace(TOKENS_IMPORT, f"{TOKENS_IMPORT}\n{IMPORT}")
    text = re.sub(
        r"Colors\.white\.withValues\(alpha: ([0-9.]+)\)",
        r"heroTealSurface(\1)",
        text,
    )
    replacements = [
        ("foregroundColor: Colors.white", "foregroundColor: heroTealInk()"),
        ("color: Colors.white", "color: heroTealInk()"),
        ("selected ? Colors.white :", "selected ? heroTealInk() :"),
        (": Colors.white,", ": heroTealInk(),"),
        (": Colors.white)", ": heroTealInk())"),
    ]
    for old, new in replacements:
        text = text.replace(old, new)
    path.write_text(text, encoding="utf-8")
    print(f"{path.name}: Colors. count = {text.count('Colors.')}")


def main() -> None:
    for path in TARGETS:
        migrate(path)


if __name__ == "__main__":
    main()
