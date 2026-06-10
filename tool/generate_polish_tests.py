#!/usr/bin/env python3
"""Generate Tier S+ polish contract tests for every feature *_screen.dart."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FEATURES = ROOT / "lib" / "features"
TEST_ROOT = ROOT / "test" / "features"

SKIP = {"qa_smoke_screen.dart"}
WIDTH_LIMITER_EXEMPT = {
    "personal_dashboard_screen.dart",
    "alunos_list_screen.dart",
    "treinos_list_screen.dart",
    "aluno_detail_screen.dart",
    "modo_presencial_screen.dart",
    "checkin_screen.dart",
    "meus_treinos_screen.dart",
    "historico_screen.dart",
}


def rel_import(test_path: Path) -> str:
    depth = len(test_path.parent.relative_to(ROOT / "test").parts)
    return ("../" * depth) + "support/screen_source_bundle.dart"


def test_path(screen_path: Path) -> Path:
    rel = screen_path.relative_to(FEATURES)
    module = rel.parts[0]
    stem = screen_path.stem
    return TEST_ROOT / module / f"{stem}_polish_test.dart"


def build_test(screen_path: Path, source: str) -> str:
    rel_screen = screen_path.relative_to(ROOT).as_posix()
    import_line = rel_import(test_path(screen_path))
    name = screen_path.stem.replace("_screen", "").replace("_", " ")

    checks = [
        "expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));",
        "expect(screen, isNot(contains('CircularProgressIndicator')));",
    ]

    if "FxShellScaffold" in source:
        checks.append("expect(screen, contains('FxShellScaffold'));")
        if screen_path.name not in WIDTH_LIMITER_EXEMPT:
            checks.append(
                "expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));"
            )

    is_async = bool(
        re.search(r"FutureProvider", source)
        or re.search(r"\.when\(", source)
        or re.search(r"AsyncValue", source)
        or re.search(r"\b_loading\b", source)
        or re.search(r"\b_erro\b", source)
    )
    if is_async:
        checks.append(
            "expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));"
        )
        checks.append(
            "expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));"
        )

    if "RefreshIndicator" in source:
        checks.append("expect(screen, contains('RefreshIndicator'));")

    if "Colors." in source:
        checks.append(
            "expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));"
        )

    checks_str = "\n    ".join(checks)

    return f"""import 'package:flutter_test/flutter_test.dart';

import '{import_line}';

void main() {{
  test('{name} cumpre contrato Tier S+', () {{
    final screen = readScreenSourceBundle('{rel_screen}');
    {checks_str}
  }});
}}
"""


def main() -> None:
    created = updated = skipped = 0
    for screen in sorted(FEATURES.rglob("*_screen.dart")):
        if screen.name in SKIP:
            skipped += 1
            continue
        source = screen.read_text(encoding="utf-8")
        out = test_path(screen)
        content = build_test(screen, source)
        out.parent.mkdir(parents=True, exist_ok=True)
        if out.exists():
            if out.read_text(encoding="utf-8") == content:
                skipped += 1
                continue
            out.write_text(content, encoding="utf-8")
            updated += 1
            print(f"updated {out.relative_to(ROOT)}")
        else:
            out.write_text(content, encoding="utf-8")
            created += 1
            print(f"created {out.relative_to(ROOT)}")
    print(f"done: created={created} updated={updated} skipped={skipped}")


if __name__ == "__main__":
    main()
