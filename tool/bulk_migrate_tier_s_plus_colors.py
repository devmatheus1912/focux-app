#!/usr/bin/env python3
"""Migrate Colors.* to dashboard_readability tokens for Tier S+ gates."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IMPORT = "import '../../dashboard/utils/dashboard_readability.dart';"
IMPORT_DEEP = "import '../../../features/dashboard/utils/dashboard_readability.dart';"
IMPORT_PART = "import '../../dashboard/utils/dashboard_readability.dart';"

TARGETS = [
    ROOT / "lib/features/onboarding/screens/onboarding_screen.dart",
    ROOT / "lib/features/onboarding/screens/onboarding_screen_widgets.part.dart",
    ROOT / "lib/features/perfil/screens/identidade_visual_screen.dart",
    ROOT / "lib/features/perfil/screens/identidade_visual_screen_widgets.part.dart",
    ROOT / "lib/features/treinos/screens/treino_detail_screen.dart",
    ROOT / "lib/features/treinos/screens/treino_detail_screen_body.part.dart",
    ROOT / "lib/features/treinos/screens/treino_detail_screen_exercises.part.dart",
    ROOT / "lib/features/treinos/screens/treino_detail_screen_rows.part.dart",
    ROOT / "lib/features/treinos/screens/treino_detail_screen_sheets.part.dart",
    ROOT / "lib/features/treinos/screens/treino_detail_screen_states.part.dart",
    ROOT / "lib/features/qa/screens/tokens_strip_showcase_screen.dart",
]


def pick_import(path: Path) -> str:
    rel = path.relative_to(ROOT / "lib").parts
    ups = len(rel) - 2
    return f"import '{'../' * ups}dashboard/utils/dashboard_readability.dart';"


def migrate(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    imp = pick_import(path)
    if "dashboard_readability.dart" not in text and not path.name.endswith(".part.dart"):
        anchor = "import '../../../core/theme/tokens_strip.dart';"
        if anchor in text:
            text = text.replace(anchor, f"{anchor}\n{imp}")
        elif "import '../../../core/widgets/fx_screen_a11y.dart';" in text:
            text = text.replace(
                "import '../../../core/widgets/fx_screen_a11y.dart';",
                f"import '../../../core/widgets/fx_screen_a11y.dart';\n{imp}",
            )

    text = re.sub(
        r"Colors\.white\.withValues\(alpha: ([0-9.]+)\)",
        r"heroTealSurface(\1)",
        text,
    )
    text = re.sub(
        r"Colors\.black\.withValues\(alpha: ([0-9.]+)\)",
        r"heroScrim(\1)",
        text,
    )
    replacements = [
        ("foregroundColor: Colors.white", "foregroundColor: heroTealInk()"),
        ("color: Colors.white", "color: heroTealInk()"),
        ("selected ? Colors.white :", "selected ? heroTealInk() :"),
        ("isDark ? Colors.white :", "isDark ? heroTealInk() :"),
        ("? Colors.white,", "? heroTealInk(),"),
        ("? Colors.white)", "? heroTealInk())"),
        (": Colors.white,", ": heroTealInk(),"),
        (": Colors.white)", ": heroTealInk())"),
        ("backgroundColor: Colors.white", "backgroundColor: heroTealInk()"),
        ("Colors.transparent", "fxTransparent"),
        ("const IconThemeData(color: Colors.white)", "IconThemeData(color: heroTealInk())"),
    ]
    for old, new in replacements:
        text = text.replace(old, new)

    # Remove const where heroTeal* breaks const eval
    text = re.sub(
        r"const (Icon|Text)\(([^)]*heroTeal[^)]*)\)",
        lambda m: f"{m.group(1)}({m.group(2)})",
        text,
        flags=re.DOTALL,
    )

    path.write_text(text, encoding="utf-8")
    print(f"{path.relative_to(ROOT)}: Colors.={text.count('Colors.')}")


def main() -> None:
    for path in TARGETS:
        if path.exists():
            migrate(path)


if __name__ == "__main__":
    main()
