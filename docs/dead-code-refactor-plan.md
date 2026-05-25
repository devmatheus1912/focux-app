# Focux — Auditoria de código morto e plano de refatoração

**Data:** 21/05/2026 · **Versão:** 2.0 (fases A–D concluídas)

---

## Resumo executivo

| Fase | Status |
|------|--------|
| A — Limpeza imediata | ✅ |
| B — Rotas / paywall / QA release | ✅ |
| C — Design system | ✅ |
| D — CI + ferramenta órfãos | ✅ |
| Testes | **155/155** passando |

---

## Fase A (concluída)

- Removidos: `cockpit_theme.dart`, `fx_strip_sub_screen.dart`, `planos_screen.dart`, `empty_state.dart`, `paywall_screen.dart` (~770 linhas)
- Removidos: `ShimmerCardLoading`, `_EmptyFeed`, params mortos em `_ClaudeInlineNote`
- Analyzer: zero `warning` em `lib/`

---

## Fase B (concluída)

### B.1 Funil único de assinatura
- `/paywall` e `/planos` → redirect para `/assinatura`
- `PaywallScreen` deletada; login/registro usam `/assinatura`
- `AnalyticsService.paywallOpened` na abertura de `AssinaturaScreen`

### B.2 QA alinhado ao router
- `qa_route_preview`: `/planos`, `/paywall`, `/assinatura` → `AssinaturaScreen`

### B.3 QA fora do release build
- `qa_routes.dart` + `qa_routes_stub.dart` com import condicional `dart.vm.product`
- Release não linka `features/qa` no router principal

---

## Fase C (concluída)

### C.1 Empty state
- `plano_sucesso_screen` → `FxEmptyState`; `empty_state.dart` removido

### C.2 fx_strip_components
- Movido para `lib/features/qa/widgets/` (só design lab)

### C.3 Tipografia
- `google_fonts` removido de telas avulsas; tema usa `AppTypography.inter` central

### Eagle anti-patterns
- `CircularProgressIndicator` / `OutlineInputBorder` raw → `FxLoading` / `FxInputDeco` em treinos e preview de vídeo

---

## Fase D (concluída)

- `.github/workflows/analyze.yml` — `dart analyze --fatal-warnings` + testes + scan órfãos
- `e2e.yml` — analyze com `--fatal-warnings`
- `tools/find_orphan_dart.dart` — detecta arquivos sem importadores

---

## Comandos

```bash
cd focux-app
dart analyze --fatal-warnings
flutter test
dart run tools/find_orphan_dart.dart
```

---

## Manutenção (D.3)

Revisar trimestralmente `dart run tools/find_orphan_dart.dart` e rotas em `app_router.dart`.

---

*Focux Personal · dead-code audit v2.0*
