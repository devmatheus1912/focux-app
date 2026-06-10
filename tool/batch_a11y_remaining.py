#!/usr/bin/env python3
"""Fix remaining screen patterns for a11y."""

from __future__ import annotations

import re
from pathlib import Path

IMPORT = "import '../../../core/widgets/fx_screen_a11y.dart';\n"

TARGETS = {
    "lib/features/leads/screens/add_lead_screen.dart": ("Novo Lead", r"Widget build\(BuildContext context\) => FxShellScaffold\("),
    "lib/features/auth/screens/login_screen.dart": ("Entrar no Focux", r"return AnnotatedRegion<SystemUiOverlayStyle>\("),
    "lib/features/auth/screens/register_screen.dart": ("Criar conta personal", r"return AnnotatedRegion<SystemUiOverlayStyle>\("),
    "lib/features/auth/screens/register_aluno_screen.dart": ("Criar conta aluno", r"return AnnotatedRegion<SystemUiOverlayStyle>\("),
    "lib/features/auth/screens/esqueci_senha_screen.dart": ("Recuperar senha", r"return AnnotatedRegion<SystemUiOverlayStyle>\("),
    "lib/features/auth/screens/resetar_senha_screen.dart": ("Nova senha", r"return AnnotatedRegion<SystemUiOverlayStyle>\("),
    "lib/features/auth/screens/splash_screen.dart": ("Focux", r"return Scaffold\("),
    "lib/features/perfil/screens/perfil_screen.dart": ("Perfil", r"return perfilAsync\.when\("),
    "lib/features/treinos/screens/treino_detail_screen.dart": ("Detalhe do treino", r"return PopScope\("),
    "lib/features/financeiro/screens/financeiro_dashboard_screen.dart": ("Dashboard financeiro", r"return RefreshIndicator\("),
    "lib/features/assinatura/screens/assinatura_screen.dart": ("Assinatura", r"Widget build\(BuildContext context\) => buildAssinaturaScreen\(context\)"),
    "lib/features/agenda/screens/agenda_aluno_screen.dart": ("Minha agenda", r"return FxShellScaffold\("),
    "lib/features/chat/screens/chat_screen.dart": ("Chat", r"return FxShellScaffold\("),
    "lib/features/chat/screens/chat_aluno_screen.dart": ("Chat", r"return FxShellScaffold\("),
    "lib/features/treinos/screens/add_exercicio_to_treino_screen.dart": ("Adicionar exercício", r"return FxShellScaffold\("),
}


def add_import(source: str) -> str:
    if "fx_screen_a11y.dart" in source:
        return source
    lines = source.splitlines(keepends=True)
    last_import = 0
    for idx, line in enumerate(lines):
        if line.startswith("import "):
            last_import = idx
    lines.insert(last_import + 1, IMPORT)
    return "".join(lines)


def wrap_arrow_assinatura(source: str, label: str) -> str:
    old = "Widget build(BuildContext context) => buildAssinaturaScreen(context);"
    new = (
        "Widget build(BuildContext context) => fxScreenA11yScope(\n"
        f"    label: '{label}',\n"
        "    child: buildAssinaturaScreen(context),\n"
        "  );"
    )
    return source.replace(old, new)


def wrap_pattern(source: str, label: str, pattern: str) -> str | None:
    if "fxScreenA11yScope(" in source:
        return None
    match = re.search(pattern, source)
    if not match:
        return None
    widget_start = match.start()
    if "return " in match.group(0):
        open_paren = source.index("(", match.end() - 1)
    else:
        # arrow function case handled separately
        return None
    depth = 0
    i = open_paren
    in_sq = in_dq = in_triple = False
    while i < len(source):
        ch = source[i]
        if in_triple:
            if source[i : i + 3] == "'''":
                in_triple = False
                i += 3
                continue
        elif in_sq:
            if ch == "'":
                in_sq = False
        elif in_dq:
            if ch == '"':
                in_dq = False
        else:
            if source[i : i + 3] == "'''":
                in_triple = True
                i += 3
                continue
            if ch == "'":
                in_sq = True
            elif ch == '"':
                in_dq = True
            elif ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0:
                    close_paren = i
                    break
        i += 1
    else:
        return None

    indent_match = re.match(r"(\s*)", source[:widget_start].split("\n")[-1])
    indent = indent_match.group(1) if indent_match else "    "
    original = source[widget_start : close_paren + 1]
    inner = original[len(f"{indent}return ") :]
    wrapped = (
        f"{indent}return fxScreenA11yScope(\n"
        f"{indent}  label: '{label}',\n"
        f"{indent}  child: {inner},\n"
        f"{indent});"
    )
    return source[:widget_start] + wrapped + source[close_paren + 1 :]


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    for rel, (label, pattern) in TARGETS.items():
        path = root / rel.replace("/", "\\")
        if not path.exists():
            path = root / rel
        source = path.read_text(encoding="utf-8")
        if "buildAssinaturaScreen(context)" in pattern:
            updated = wrap_arrow_assinatura(source, label)
        else:
            updated = wrap_pattern(source, label, pattern)
        if updated is None:
            print(f"SKIP {rel}")
            continue
        updated = add_import(updated)
        path.write_text(updated, encoding="utf-8")
        print(f"OK {rel}")


if __name__ == "__main__":
    main()
