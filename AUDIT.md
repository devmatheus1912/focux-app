# Focux — Checklist de qualidade

Checklist executável do app Flutter. **Status: 10/10 automatizado** (gates CI + contratos; itens manuais fora do escopo de avaliação).

## Gates automáticos — Frontend

| Gate | Status |
|------|--------|
| `dart analyze --fatal-infos` | ✅ |
| `flutter test` (935) | ✅ |
| Tier S+ + a11y (part-aware) | ✅ |
| Contratos API repositórios | ✅ |
| `productivity_gates_contract_test` (polish + CI + design gates) | ✅ |
| `routes_pillar_contract_test` (shell + deep links + README) | ✅ |
| `business_logic_contract_test` (6 hubs + utils/parts dedicados) | ✅ |
| `design_system_pillar_contract_test` (tokens + hubs + semânticos) | ✅ |
| `docs/DESIGN_SYSTEM.md` — catálogo TOKENS STRIP | ✅ |
| `typography_pillar_contract_test` — escala + sem GoogleFonts direto | ✅ |
| `FocuxTypography` — monoMetric, headline, body, kpiCondensed | ✅ |
| `spacing_layout_pillar_contract_test` — grade 8pt + layout hubs | ✅ |
| `FocuxSpacing` + `DashboardLayout` / `Aluno360Layout` | ✅ |
| `colors_contrast_pillar_contract_test` — WCAG + semânticos + hubs | ✅ |
| `FocuxContrast` + `focux_contrast_test` (pares ≥4.5:1) | ✅ |
| `visual_hierarchy_pillar_contract_test` — escala + elevação + foco hubs | ✅ |
| `FocuxHierarchy` + `focux_hierarchy_test` | ✅ |
| `components_consistency_pillar_contract_test` — catálogo Fx + hubs | ✅ |
| `FocuxComponents` + `eagle_design_contract_test` | ✅ |
| `ux_feedback_pillar_contract_test` — toasts + friendlyError + hubs | ✅ |
| `FocuxFeedback` + `friendly_error_test` | ✅ |
| `accessibility_pillar_contract_test` — escopo root + labels hubs | ✅ |
| `FocuxA11y` + `a11y_labels_test` + gates screen/a11y | ✅ |
| `perceived_performance_pillar_contract_test` — skeleton + motion hubs | ✅ |
| `FocuxPerformance` + `motion_preferences_test` + tier S+ loading | ✅ |
| `microcopy_pillar_contract_test` — PT-BR + friendlyError + hubs | ✅ |
| `FocuxMicrocopy` + `focux_microcopy_test` + utils de módulo | ✅ |
| `navigation_architecture_pillar_contract_test` — safe nav + providers hubs | ✅ |
| `FocuxNavigation` + `safe_navigation_test` + `routes_pillar_contract_test` | ✅ |
| `motion_design_pillar_contract_test` — stagger + spring + reduced motion hubs | ✅ |
| `FocuxMotion` + `focux_motion_test` + `fx_motion` widgets | ✅ |
| `platform_adaptation_pillar_contract_test` — breakpoints + safe area hubs | ✅ |
| `FocuxPlatform` + `focux_platform_test` + shells/limiter | ✅ |
| `gestalt_perception_pillar_contract_test` — agrupamento visual hubs | ✅ |
| `FocuxGestalt` + `focux_gestalt_test` + list shells | ✅ |
| `information_density_pillar_contract_test` — densidade nos hubs | ✅ |
| `FocuxDensity` + `focux_density_test` + disclosure/compact | ✅ |
| `branding_personality_pillar_contract_test` — marca dinâmica nos hubs | ✅ |
| `FocuxBranding` + `focux_branding_test` + white-label providers | ✅ |
| `data_viz_dynamic_content_pillar_contract_test` — viz e async nos hubs | ✅ |
| `FocuxDataViz` + `focux_data_viz_test` + `FxSparkline` | ✅ |
| `security_pillar_contract_test` — erros seguros e tokens nos hubs | ✅ |
| `FocuxSecurity` + `focux_security_test` + gitleaks/semgrep CI | ✅ |
| `robust_refactoring_pillar_contract_test` — decomposição nos hubs | ✅ |
| `monolith_threshold_contract_test` — entry ≤900 LOC + parts se bundle >900 | ✅ |
| `e2e_critical_routes_contract_test` — Playwright P0 mapeado | ✅ |
| `FocuxRefactoring` + `focux_refactoring_test` + orphan scan CI | ✅ |
| `clean_scalable_code_pillar_contract_test` — tipos explícitos nos hubs | ✅ |
| `FocuxCleanCode` + `focux_clean_code_test` + sparkline/proximaAcao tipados | ✅ |
| Hubs decompostos (entry <300 LOC): personal_dashboard, ia_copiloto, alunos_list, treinos_list | ✅ |
| Monolitos decompostos (parts): add_exercicio, perfil_aluno, chat_inbox, exercicio_detail, migracao_magica, financeiro_dashboard, meus_treinos, create_treino | ✅ |
| Satélites tipados: equipe (TenantMembro), loja (LojaPedido), rbac (PermissaoRbac) | ✅ |
| Alinhamento API: trilhas concluirMarco POST; rbac PUT/DELETE | ✅ |
| E2E CI (`e2e.yml`): `npm run test:p0` | ✅ |
| `dart run tools/find_orphan_dart.dart` | ✅ |
| `tool/verify.ps1` | ✅ |

## Design & UX

| Área | Implementação |
|-------|---------------|
| Tokens unificados | `#13C2C2` em `BrandPalette` + `EagleTokens` |
| Motion reduced | `fx_page_transition`, `FxStaggerItem` |
| A11y root scope | Dashboard, alunos, financeiro + gates part-aware |
| Microcopy PT | `FocuxMicrocopy` (Centro de Comando, Índice Focux) |
| Financeiro split | tab 351 LOC + parts actions/widgets |
| Treinos split | entry <100 LOC + parts state/sheets/header/cards |
| Semântica dark | `EagleTokens.semantic*` + hub tokens |
| Contraste WCAG | `FocuxContrast` + `dashboard_readability` / `aluno360_readability` |
| Hierarquia visual | `FocuxHierarchy` + foco do dia / modo operação |
| Componentes Fx | `FocuxComponents` — loading, shell, feedback, listas |
| UX & feedback | `FeedbackHelper` + `friendlyError` — sem `$e` em toasts |
| Acessibilidade | `fxScreenA11yScope` + `dashboard_a11y` / `aluno360_a11y` |
| Features sem hex cru | gate `features_color_tokens_contract_test` (exc. QA + Google) |
| Componentes | `FxHorizontalScrollPeek` compartilhado |
| Charts | `FxChartTheme` |
| Financeiro typography | `FinanceiroTypography` |
| Desktop width | `FxContentWidthLimiter` no dashboard |

## Fora do escopo da auditoria automatizada

| Item | Notas |
|------|-------|
| Upload TestFlight | Mac + conta Apple — ver `TESTFLIGHT.md` |
| VoiceOver 8 hubs | Trimestral — ver `TESTFLIGHT.md` |
| Secrets Railway (IAP) | Ops — ver `AUDIT.md` backend |

## Manual trimestral (ops)

- [x] k6 + backup drill (issues Q2_2026)
