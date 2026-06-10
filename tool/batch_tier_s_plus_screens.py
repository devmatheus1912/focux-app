#!/usr/bin/env python3
"""Elevate feature screens toward Tier S+: FxContentWidthLimiter + error state polish."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FEATURES = ROOT / "lib" / "features"

SKIP = {"qa_smoke_screen.dart", "tokens_strip_showcase_screen.dart"}
WIDTH_LIMITER_EXEMPT = {
    "personal_dashboard_screen.dart",
    "alunos_list_screen.dart",
    "treinos_list_screen.dart",
    "aluno_detail_screen.dart",
    "modo_presencial_screen.dart",
    "checkin_screen.dart",
    "meus_treinos_screen.dart",
    "historico_screen.dart",
    "splash_screen.dart",
    "login_screen.dart",
    "register_screen.dart",
    "register_aluno_screen.dart",
    "esqueci_senha_screen.dart",
    "resetar_senha_screen.dart",
    "definir_senha_aluno_screen.dart",
}


def rel_import(path: Path, suffix: str) -> str:
    depth = len(path.relative_to(ROOT).parts) - 1
    return ("../" * depth) + suffix


def add_import(source: str, import_path: str) -> str:
    line = f"import '{import_path}';"
    if import_path in source:
        return source
    lines = source.splitlines(keepends=True)
    last = 0
    for i, ln in enumerate(lines):
        if ln.startswith("import "):
            last = i
    lines.insert(last + 1, line + "\n")
    return "".join(lines)


def wrap_body_with_limiter(source: str) -> str:
    if "FxContentWidthLimiter" in source:
        return source
    m = re.search(r"(\n\s*body:\s*)(\S)", source)
    if not m:
        return source
    start = m.end(1)
    # Already wrapped?
    snippet = source[start : start + 40]
    if snippet.strip().startswith("FxContentWidthLimiter"):
        return source

    indent = m.group(1).split("body:")[0] + "  "
    child_indent = indent + "  "
    # Insert opening
    source = (
        source[: m.start(1)]
        + m.group(1)
        + "FxContentWidthLimiter(\n"
        + child_indent
        + "child: "
        + source[start:]
    )
    # Close before FxShellScaffold's closing — find last `),` before final `);` of build method
    # Pattern: limiter opened after body: — add `),` before scaffold close
    marker = "\n      ),\n    );"
    pos = source.rfind(marker)
    if pos > 0:
        source = source[:pos] + child_indent + "),\n" + source[pos:]
    return source


def main() -> None:
    changed = 0
    for path in sorted(FEATURES.rglob("*_screen.dart")):
        if path.name in SKIP or path.name in WIDTH_LIMITER_EXEMPT:
            continue
        original = path.read_text(encoding="utf-8")
        if "FxShellScaffold" not in original:
            continue
        updated = original
        if "FxContentWidthLimiter" not in updated:
            updated = add_import(
                updated, rel_import(path, "core/widgets/fx_content_width_limiter.dart")
            )
            updated = wrap_body_with_limiter(updated)
        if updated != original:
            path.write_text(updated, encoding="utf-8")
            changed += 1
            print(f"upgraded {path.relative_to(ROOT)}")
    print(f"done: changed={changed}")


if __name__ == "__main__":
    main()
