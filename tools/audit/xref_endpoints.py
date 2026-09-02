#!/usr/bin/env python3
"""Cruza o inventario de endpoints do focux-backend contra as chamadas em lib/.

Responde, sem subir nada:
  - quais endpoints do backend nenhum cliente do app chama (meta 15);
  - quais chamadas do app apontam para endpoint inexistente ou verbo errado;
  - quais listas sem paginacao (flag L) o app realmente consome, e o bucket
    de prioridade de cada uma;
  - quais respostas de entidade JPA (flag E) tem contrato de app a preservar.

Uso:
    python3 tools/audit/xref_endpoints.py [--json saida.json]

O inventario vem do repo do backend; regerar la e substituir
tools/audit/backend_endpoints.tsv por inteiro. Formato e legenda das flags
estao no cabecalho daquele arquivo.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import defaultdict

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LIB = os.path.join(REPO, "lib")
INVENTORY = os.path.join(REPO, "tools", "audit", "backend_endpoints.tsv")

# O catalogo de smoke lista paths para o QA bater status anonimo. Referencia
# ali nao é consumo de produto, entao conta numa camada separada.
QA_CATALOG = "lib/features/qa/data/qa_smoke_catalog.dart"

# Chamada Dio: .get('/api/x'), .post<T>('/api/x'), com a string podendo cair
# na linha seguinte.
CALL_RE = re.compile(
    r"\.\s*(get|post|put|patch|delete)\s*(?:<[^>()]*>)?\s*\(\s*(['\"])(/[^'\"\n]*)\2",
    re.IGNORECASE,
)
# Path escrito como literal solto: constante, ternario, tabela de cache.
LITERAL_RE = re.compile(r"(['\"])(/api/[^'\"\n\s]*)\1")

# Endpoints que nenhum app alcanca por desenho: webhook servidor-a-servidor,
# arquivo lido pelo SO, e a superficie web publica de white-label.
NON_APP_PREFIXES = (
    "/api/webhooks/",
    "/.well-known/",
    "/api/public/personal/",
    "/api/public/ical/",
    "/api/public/resolve-domain",
    "/api/loja/publico/",
    "/api/pacotes/publico/",
    "/api/captura/publico/",
)
NON_APP_EXACT = ("/", "/p/{slug}", "/c/{slug}")

# Buckets de paginacao. Criterio e risco de crescimento da colecao por tenant,
# nao o modulo. Revisar quando uma tela nova passar a consumir a lista.
PAGINATE_FIRST = {
    "/api/alunos",
    "/api/alunos/{alunoId}/avaliacoes",
    "/api/alunos/{alunoId}/fotos",
    "/api/alunos/{alunoId}/medidas",
    "/api/alunos/{alunoId}/recordes",
    "/api/alunos/{id}/historico-mensalidades",
    "/api/broadcasts",
    "/api/captura",
    "/api/chat/inbox/archived",
    "/api/checkin/historico",
    "/api/feed",
    "/api/feed/aluno",
    "/api/feed/{postId}/comentarios",
    "/api/feedback-videos",
    "/api/feedback-videos/aluno/{alunoId}",
    "/api/feedback-videos/me",
    "/api/leads",
    "/api/ranking",
    "/api/retencao/base",
}
PAGINATE_LATER = {
    "/api/agenda/aluno/meus",
    "/api/aluno/medidas",
    "/api/automacoes/{fluxoId}/logs",
    "/api/coach-proativo/mensagens",
    "/api/depoimentos",
    "/api/habitos/compliance",
    "/api/habitos/me",
    "/api/leads/{id}/interacoes",
    "/api/loja/pedidos",
    "/api/personal/depoimentos",
    "/api/personal/gallery",
    "/api/suporte/tickets/meus",
    "/api/trilhas/aluno/{alunoId}",
    "/api/winback/log",
}
# Gemeo paginado existe e o cru esta liberado para remocao no backend: o app
# ja migrou para /page, entao estes dois saem como orfaos no relatorio.
DROP_RAW_LIST = {
    "/api/chat/aluno/historico",
    "/api/chat/historico/{alunoId}",
}


def normalize(path: str) -> str:
    """Reduz path do app e do backend a uma forma comparavel.

    `$id`, `${aluno.id}` e `{alunoId}` viram todos `{}`, e a query sai.
    """
    path = path.split("?")[0]
    path = re.sub(r"\$\{[^}]*\}", "{}", path)
    path = re.sub(r"\$[A-Za-z_][A-Za-z0-9_.]*", "{}", path)
    path = re.sub(r"\{[^}]*\}", "{}", path)
    if len(path) > 1 and path.endswith("/"):
        path = path[:-1]
    return path


def load_inventory(source: str) -> list[tuple[str, str, str, str]]:
    rows = []
    with open(source, encoding="utf-8") as handle:
        for number, line in enumerate(handle, 1):
            line = line.rstrip("\n")
            if not line or line.startswith("#"):
                continue
            parts = line.split("\t")
            if len(parts) < 4:
                raise SystemExit(f"{source}:{number}: esperava 4 colunas separadas por TAB")
            rows.append(tuple(parts[:4]))
    return rows


def scan_app() -> tuple[list, set, set, set, dict]:
    """Varre lib/ e separa consumo de produto de referencia so em QA."""
    calls = []
    product_literals = set()
    qa_literals = set()
    qa_endpoints = set()
    sites = defaultdict(list)

    for root, _dirs, files in os.walk(LIB):
        for name in sorted(files):
            if not name.endswith(".dart"):
                continue
            absolute = os.path.join(root, name)
            relative = os.path.relpath(absolute, REPO)
            with open(absolute, encoding="utf-8", errors="replace") as handle:
                text = handle.read()
            is_qa = relative == QA_CATALOG
            consumed_spans = []
            for match in CALL_RE.finditer(text):
                consumed_spans.append((match.start(3), match.end(3)))
                if is_qa:
                    continue
                verb = match.group(1).upper()
                path = normalize(match.group(3))
                line = text.count("\n", 0, match.start()) + 1
                calls.append((verb, path, relative, line))
                sites[(verb, path)].append(f"{relative}:{line}")
            for match in LITERAL_RE.finditer(text):
                if any(start <= match.start(2) < end for start, end in consumed_spans):
                    continue
                path = normalize(match.group(2))
                (qa_literals if is_qa else product_literals).add(path)

    qa_path = os.path.join(REPO, QA_CATALOG)
    if os.path.exists(qa_path):
        with open(qa_path, encoding="utf-8") as handle:
            qa_text = handle.read()
        for block in re.finditer(r"QaSmokeEndpoint\((.*?)\n  \)", qa_text, re.DOTALL):
            verb = re.search(r"method:\s*'([^']+)'", block.group(1))
            path = re.search(r"path:\s*'([^']+)'", block.group(1))
            if verb and path:
                qa_endpoints.add((verb.group(1).upper(), normalize(path.group(1))))

    return calls, product_literals, qa_literals, qa_endpoints, sites


def classify(rows, calls, product_literals, qa_literals, qa_endpoints):
    called = {(verb, path) for verb, path, _f, _l in calls}
    product_paths = {path for _v, path, _f, _l in calls} | product_literals

    tiers = {}
    for row in rows:
        verb, path, _flags, _src = row
        key = (verb, normalize(path))
        if key in called:
            tiers[row] = "product_call"
        elif key[1] in product_paths:
            tiers[row] = "path_in_product_other_verb"
        elif key in qa_endpoints or key[1] in qa_literals:
            tiers[row] = "qa_smoke_only"
        else:
            tiers[row] = "no_reference"
    return tiers, called


def is_non_app(path: str) -> bool:
    return path in NON_APP_EXACT or path.startswith(NON_APP_PREFIXES)


def bucket_for(path: str) -> str:
    if path in PAGINATE_FIRST:
        return "A_paginar_primeiro"
    if path in PAGINATE_LATER:
        return "B_paginar_depois"
    if path in DROP_RAW_LIST:
        return "D_remover_lista_crua"
    return "C_cap_de_size"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--inventory", default=INVENTORY)
    parser.add_argument("--json", dest="json_out")
    args = parser.parse_args()

    rows = load_inventory(args.inventory)
    calls, product_literals, qa_literals, qa_endpoints, sites = scan_app()
    tiers, called = classify(rows, calls, product_literals, qa_literals, qa_endpoints)

    inventory_keys = {(verb, normalize(path)) for verb, path, _f, _s in rows}
    inventory_paths = {normalize(path) for _v, path, _f, _s in rows}
    missing = sorted(k for k in called if k not in inventory_keys and k[1] not in inventory_paths)
    wrong_verb = sorted(k for k in called if k not in inventory_keys and k[1] in inventory_paths)

    counts = defaultdict(int)
    for tier in tiers.values():
        counts[tier] += 1

    print("=" * 72)
    print("cruzamento focux-backend x focux-app/lib")
    print("=" * 72)
    print(f"endpoints no inventario ............. {len(rows)}")
    print(f"call sites em codigo de produto ..... {len(calls)}")
    print(f"endpoints do catalogo de smoke ...... {len(qa_endpoints)}")
    print()
    for tier in sorted(counts):
        print(f"  {tier:30} {counts[tier]:4}")
    print()
    print(f"chamadas do app sem endpoint ........ {len(missing)}")
    print(f"chamadas do app com verbo divergente  {len(wrong_verb)}")
    for verb, path in missing:
        print(f"    SEM ENDPOINT  {verb:6} {path}")
    for verb, path in wrong_verb:
        print(f"    VERBO ERRADO  {verb:6} {path}")

    orphans = [row for row, tier in tiers.items() if tier == "no_reference"]
    reachable = [row for row in orphans if not is_non_app(row[1])]
    print()
    print(f"sem referencia no app ............... {len(orphans)}")
    print(f"  fora do app por desenho ........... {len(orphans) - len(reachable)}")
    print(f"  orfaos de fato (meta 15) .......... {len(reachable)}")

    by_module = defaultdict(list)
    for row in reachable:
        segments = [s for s in row[1].split("/") if s and s != "api"]
        by_module[segments[0] if segments else "(raiz)"].append(row)
    print("\n-- orfaos por modulo")
    for module in sorted(by_module, key=lambda m: (-len(by_module[m]), m)):
        listing = ", ".join(sorted(f"{r[0]} {r[1]}" for r in by_module[module]))
        print(f"  {module:16} {len(by_module[module]):3}  {listing}")

    print("\n-- backend pronto sem UI (so no catalogo de smoke)")
    for row, tier in sorted(tiers.items(), key=lambda kv: kv[0][1]):
        if tier == "qa_smoke_only":
            print(f"  {row[0]:6} {row[1]:56} {row[3]}")

    print("\n-- path no produto, este verbo nunca chamado")
    for row, tier in sorted(tiers.items(), key=lambda kv: kv[0][1]):
        if tier == "path_in_product_other_verb":
            print(f"  {row[0]:6} {row[1]:56} {row[3]}")

    lists_consumed = [
        row for row, tier in tiers.items() if tier == "product_call" and "L" in row[2]
    ]
    lists_total = sum(1 for row in rows if "L" in row[2])
    print(f"\n-- paginacao: {len(lists_consumed)} de {lists_total} listas flag-L tem consumidor")
    by_bucket = defaultdict(list)
    for row in lists_consumed:
        by_bucket[bucket_for(row[1])].append(row)
    for bucket in sorted(by_bucket):
        print(f"\n  {bucket}  ({len(by_bucket[bucket])})")
        for row in sorted(by_bucket[bucket], key=lambda r: r[1]):
            where = sorted({s.rsplit(':', 1)[0] for s in sites[(row[0], normalize(row[1]))]})
            trimmed = ", ".join(w.replace("lib/features/", "") for w in where)
            print(f"    {row[1]:58} {trimmed}")

    entities = [row for row, tier in tiers.items() if tier == "product_call" and "E" in row[2]]
    entities_total = sum(1 for row in rows if "E" in row[2])
    print(f"\n-- entidade JPA: {len(entities)} de {entities_total} com contrato de app a preservar")
    for row in sorted(entities, key=lambda r: r[1]):
        print(f"    {row[0]:6} {row[1]:56} {row[3]}")

    undocumented = sum(
        1 for row, tier in tiers.items() if tier == "product_call" and "O" not in row[2]
    )
    print(
        f"\n-- OpenAPI: {undocumented} dos {counts['product_call']} endpoints "
        "que o app chama nao tem @Operation"
    )

    if args.json_out:
        payload = {
            "inventory_total": len(rows),
            "product_call_sites": len(calls),
            "counts": dict(counts),
            "app_calls_without_endpoint": [list(k) for k in missing],
            "app_calls_wrong_verb": [list(k) for k in wrong_verb],
            "orphans_reachable": [list(r) for r in reachable],
            "pagination_buckets": {
                bucket: sorted(r[1] for r in group) for bucket, group in by_bucket.items()
            },
            "jpa_entity_with_app_contract": [list(r) for r in entities],
        }
        with open(args.json_out, "w", encoding="utf-8") as handle:
            json.dump(payload, handle, indent=1, ensure_ascii=False)
        print(f"\njson escrito em {args.json_out}")

    return 1 if missing or wrong_verb else 0


if __name__ == "__main__":
    sys.exit(main())
