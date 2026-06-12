# Focux — Auditoria 10/10 ✅

Checklist executável do monorepo. **Status: completo para lançamento TestFlight.**

## Gates automáticos — Frontend

| Gate | Status |
|------|--------|
| `dart analyze --fatal-infos` | ✅ |
| `flutter test` (694+) | ✅ |
| Tier S+ + a11y (part-aware) | ✅ |
| Contratos API repositórios | ✅ |
| `productivity_gates_contract_test` (polish + CI + design gates) | ✅ |
| `routes_pillar_contract_test` (shell + deep links + README) | ✅ |
| `business_logic_contract_test` (hubs + utils dedicados) | ✅ |
| `design_system_pillar_contract_test` (tokens + hubs + semânticos) | ✅ |
| `docs/DESIGN_SYSTEM.md` — catálogo TOKENS STRIP | ✅ |
| `typography_pillar_contract_test` — escala + sem GoogleFonts direto | ✅ |
| `FocuxTypography` — monoMetric, headline, body, kpiCondensed | ✅ |
| `dart run tools/find_orphan_dart.dart` | ✅ |
| `tool/verify.ps1` | ✅ |

## Design & UX — 10/10

| Pilar | Implementação |
|-------|---------------|
| Tokens unificados | `#13C2C2` em `BrandPalette` + `EagleTokens` |
| Motion reduced | `fx_page_transition`, `FxStaggerItem` |
| A11y root scope | Dashboard, alunos, financeiro + gates part-aware |
| Microcopy PT | `FocuxMicrocopy` (Centro de Comando, Índice Focux) |
| Financeiro split | tab 351 LOC + parts actions/widgets |
| Semântica dark | `EagleTokens.semantic*` + hub tokens |
| Features sem hex cru | gate `features_color_tokens_contract_test` (exc. QA + Google) |
| Componentes | `FxHorizontalScrollPeek` compartilhado |
| Charts | `FxChartTheme` |
| Financeiro typography | `FinanceiroTypography` |
| Desktop width | `FxContentWidthLimiter` no dashboard |

## App Store / TestFlight

Ver **`TESTFLIGHT.md`** — único passo manual após conta Apple.

- [x] Metadados, IAP StoreKit, ExportOptions, build script
- [ ] Upload TestFlight (você, no Mac)

## Manual trimestral

- [ ] VoiceOver 8 hubs (Passo 3 `TESTFLIGHT.md`)
- [x] k6 + backup drill (issues Q2_2026)
