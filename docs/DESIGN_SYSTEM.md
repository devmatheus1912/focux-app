# Focux — Design System (TOKENS STRIP v1.0.0)

Fonte única de tokens visuais e componentes compartilhados do app Flutter.

## Tipografia

| Arquivo | Responsabilidade |
|---------|------------------|
| `lib/core/theme/app_typography.dart` | `AppTypography` — Inter, JetBrains Mono, Barlow Condensed |
| `lib/core/theme/focux_typography.dart` | `FocuxTypography` — escala semântica (display, body, monoMetric, kpiCondensed) |
| `lib/core/theme/tokens_strip.dart` | Tamanhos: `fontH1` 32, `fontH2` 22, `fontBody` 15, `fontBodySm` 13 |
| `lib/features/financeiro/utils/financeiro_typography.dart` | Tipografia do módulo financeiro |

### Regras

1. **UI** — `AppTypography.inter` ou `Theme.of(context).textTheme`
2. **Métricas/números** — `AppTypography.mono` ou `FocuxTypography.monoMetric`
3. **KPI condensado** — `FocuxTypography.kpiCondensed`
4. **Proibido** — `GoogleFonts.*` direto em `lib/features/` (exc. QA showcase)
5. **Proibido** — `FontWeight.bold` (use `w700`/`w800`)

## Espaçamento & layout

| Arquivo | Responsabilidade |
|---------|------------------|
| `lib/core/theme/focux_spacing.dart` | `FocuxSpacing` — padding, gaps, radius helpers |
| `lib/core/theme/tokens_strip.dart` | Grade 8pt: `s1`–`s9` (4–80px), `rInput`/`rCard`/`rButton` |
| `lib/core/theme/design_tokens.dart` | `EagleTokens.radiusXs`–`radiusXl` |
| `lib/core/widgets/fx_content_width_limiter.dart` | Largura máx. 960px em desktop |
| `lib/features/alunos/constants/aluno_360_layout.dart` | Layout hub Aluno 360 |
| `lib/features/dashboard/constants/dashboard_layout.dart` | Layout hub personal |

### Regras

1. **Espaçamento** — `TokensStrip.s*` ou `FocuxSpacing`; evitar `SizedBox(height: 7)` fora da grade
2. **Radius** — `TokensStrip.rCard` / `EagleTokens.radiusMd`
3. **Desktop** — hubs com `FxContentWidthLimiter`
4. **Módulos grandes** — extrair `*_layout.dart` quando o hub passar de ~150 LOC de padding

## Cores & contraste

| Arquivo | Responsabilidade |
|---------|------------------|
| `lib/core/theme/focux_contrast.dart` | `FocuxContrast` — WCAG AA (≥4.5:1), `readableOn` |
| `lib/core/theme/design_tokens.dart` | `EagleTokens.semantic*` + variantes dark |
| `lib/core/theme/curated_brand_palettes.dart` | White-label seguro — `isReadablePrimary` |
| `lib/features/dashboard/utils/dashboard_readability.dart` | Muted/caption do hub personal |
| `lib/features/alunos/utils/aluno360_readability.dart` | Muted/caption do Aluno 360 |

### Regras

1. **Cores** — `EagleTokens.*`, `BrandPalette`, `Theme.of(context).colorScheme`; sem `Color(0x…)` nem `Colors.red/green/blue/…`.
2. **Contraste** — texto body ≥ **4.5:1** (WCAG AA); usar `FocuxContrast.meetsWcagAa` em testes de pares críticos.
3. **Semânticos** — `semanticGood/Warn/Bad` (+ soft/dark); scores via `aderenciaColor` / `scoreColor`.
4. **Legibilidade** — muted/caption via `dashboard_readability` ou `aluno360_readability`, não alpha arbitrário na UI.
5. **White-label** — primárias validadas por `CuratedBrandPalette.isReadablePrimary`.

## Hierarquia visual & foco

| Arquivo | Responsabilidade |
|---------|------------------|
| `lib/core/theme/focux_hierarchy.dart` | `FocuxHierarchy` — papéis tipográficos + camadas de elevação |
| `lib/core/theme/focux_typography.dart` | Escala semântica (display → caption) |
| `lib/core/theme/tokens_strip.dart` | `fontH1`/`fontH2`/`fontBody` + `elevation()` |
| `lib/core/theme/shell_chrome.dart` | Superfícies glass com `elevationLevel` |
| `lib/core/widgets/fx_input_deco.dart` | Anel de foco em inputs |
| `lib/features/dashboard/utils/dashboard_day_focus.dart` | Foco narrativo do dia (hub personal) |
| `lib/features/alunos/widgets/aluno360_operacao_focus_toggle.dart` | Modo foco da operação (Aluno 360) |

### Regras

1. **Títulos** — `FocuxHierarchy.pageTitle` / `sectionTitle`; evitar `fontSize: 32` cru em features.
2. **Cards** — `cardTitle` + `caption`; KPIs com `kpi` ou `monoMetric`.
3. **Elevação** — `layerRaised` (4) → `layerSticky` (8) → `layerOverlay` (16) → `layerModal` (24).
4. **Foco de input** — `FxInputDeco.focusedBorder`; proibido `OutlineInputBorder` fora do core.
5. **Foco operacional** — um banner/CTA primário por hub (`DashboardDayFocus`, sticky CTA Aluno 360).

## Componentes & consistência

| Arquivo | Responsabilidade |
|---------|------------------|
| `lib/core/widgets/focux_components.dart` | `FocuxComponents` — catálogo e padrões de hub |
| `lib/core/widgets/fx_loading.dart` | Loading — nunca `CircularProgressIndicator` direto |
| `lib/core/widgets/fx_empty_state.dart` | Estados vazios padronizados |
| `lib/core/widgets/fx_shell_scaffold.dart` | Shell com mesh/glass + `FxShellAppBar` |
| `lib/core/widgets/feedback_helper.dart` | SnackBar/toast — nunca `ScaffoldMessenger` direto |
| `lib/core/widgets/fx_input_deco.dart` | Inputs — nunca `OutlineInputBorder` cru |
| `lib/core/widgets/fx_bottom_sheet.dart` | `showFxBottomSheet` — entrada suave |
| `lib/core/widgets/fx_screen_a11y.dart` | `fxScreenA11yScope` — root semantics |

### Regras

1. **Feedback** — `FeedbackHelper`; proibido `ScaffoldMessenger.of` em features.
2. **Loading** — `FxLoading`, `SkeletonLoader` ou shimmer do módulo; proibido `CircularProgressIndicator` cru.
3. **Listas** — `fxListTileCardShell` / `FxSatelliteListTile`; proibido `ListTile` cru.
4. **Shell** — hubs com `FxShellScaffold` ou `FxShellAppBar` + `fxScreenA11yScope`.
5. **Catálogo** — ≥15 widgets `fx_*` em `lib/core/widgets/`; versão `FocuxComponents.version`.

## UX & feedback

| Arquivo | Responsabilidade |
|---------|------------------|
| `lib/core/ux/focux_feedback.dart` | `FocuxFeedback` — catálogo de toasts e estados |
| `lib/core/widgets/feedback_helper.dart` | `FeedbackHelper` — success/error/warn/info + haptics |
| `lib/core/utils/friendly_error.dart` | `friendlyError` — humaniza `DioException` e erros opacos |
| `lib/core/widgets/fx_empty_state.dart` | Estados vazios com CTA opcional |

### Regras

1. **Toasts** — `FeedbackHelper.showSuccess/Error/Warn/Info`; proibido `ScaffoldMessenger` e `SnackBar` em features.
2. **Erros** — `friendlyError(e)` em toasts e painéis; proibido interpolar `$e` / `$error` na UI.
3. **Vazios** — `FxEmptyState` ou widget de módulo (`DashboardErrorState`, `AlunoDetailErrorState`).
4. **Operação Aluno 360** — `FeedbackHelper.showOperacao*` com `FeedbackPlacement.operacaoTop`.
5. **Async** — telas com `.when` / loading devem ter estado de erro + loading DS (gate Tier S+).

## Acessibilidade

| Arquivo | Responsabilidade |
|---------|------------------|
| `lib/core/a11y/focux_a11y.dart` | `FocuxA11y` — catálogo e gates de leitor de tela |
| `lib/core/widgets/fx_screen_a11y.dart` | `fxScreenA11yScope` — escopo root Semantics |
| `lib/core/utils/a11y_announce.dart` | `fxAnnounce` — anúncios TalkBack/VoiceOver |
| `lib/features/dashboard/utils/dashboard_a11y.dart` | Labels PT-BR do hub personal |
| `lib/features/alunos/utils/aluno360_a11y.dart` | Labels PT-BR do Aluno 360 |

### Regras

1. **Root scope** — toda tela de produção com `fxScreenA11yScope` ou `Semantics(container: true)`.
2. **Labels** — botões/ícones com `tooltip`, `semanticsLabel` ou `Semantics(label:)` em PT-BR.
3. **Hubs** — utils dedicados (`dashboard_a11y`, `aluno360_a11y`) para carrosséis e seções.
4. **Anúncios** — mudanças de estado via `fxAnnounce` quando o contexto muda sem foco.
5. **Manual** — auditoria trimestral TalkBack/VoiceOver (`docs/MANUAL-TRIMESTRAL.md`).

## Tokens

| Arquivo | Responsabilidade |
|---------|------------------|
| `lib/core/theme/design_tokens.dart` | `EagleTokens` — cores, radius, spacing, semânticos |
| `lib/core/theme/tokens_strip.dart` | `TokensStrip` — tipografia, glass, spacing strip |
| `lib/core/theme/brand_palette.dart` | White-label — derivações da cor primária do personal |
| `lib/core/theme/app_theme.dart` | `ThemeData` light/dark |
| `lib/core/theme/app_typography.dart` | Inter + JetBrains Mono |
| `lib/core/theme/fx_chart_theme.dart` | Charts consistentes |

Versão canônica: `TokensStrip.version` (atualmente **1.0.0**).

## Componentes Fx (usar em features)

| Widget | Uso |
|--------|-----|
| `FxLoading` | Loading — nunca `CircularProgressIndicator` direto |
| `FxEmptyState` | Estados vazios |
| `fx_input_deco` | Inputs — nunca `OutlineInputBorder` cru |
| `feedback_helper` | SnackBar/toast — nunca `ScaffoldMessenger` direto |
| `FxShellScaffold` | Shell com mesh/glass |
| `fxListTileCardShell` / `FxSatelliteListTile` | Listas — nunca `ListTile` cru |
| `FxContentWidthLimiter` | Largura máxima em desktop |
| `fxScreenA11yScope` | Root semantics em telas |

Catálogo visual (debug): rota `/qa/tokens-strip` → `TokensStripShowcaseScreen`.

## Regras em features

1. **Cores** — `EagleTokens.*`, `BrandPalette`, `Theme.of(context).colorScheme`; sem `Color(0x…)` nem `Colors.red/green/blue/…`.
2. **Exceções permitidas** — `Colors.transparent`, `Colors.white`, `Colors.black` (com alpha) em superfícies glass/auth.
3. **Macros nutricionais** — `macroProtein`, `macroCarb`, `macroFat`.
4. **Feedback** — sempre via `FeedbackHelper` / `FxEmptyState`.

## Gates automatizados (CI)

| Teste | Pilar |
|-------|-------|
| `eagle_design_contract_test.dart` | Anti-patterns Fx |
| `features_color_tokens_contract_test.dart` | Sem hex cru |
| `design_system_pillar_contract_test.dart` | Catálogo + hubs + semânticos |
| `colors_contrast_pillar_contract_test.dart` | WCAG + semânticos + hubs |
| `focux_contrast_test.dart` | Pares críticos ≥4.5:1 |
| `visual_hierarchy_pillar_contract_test.dart` | Escala + elevação + foco hubs |
| `focux_hierarchy_test.dart` | Ordem tipográfica e camadas |
| `components_consistency_pillar_contract_test.dart` | Catálogo Fx + hubs |
| `focux_components_test.dart` | Paths do catálogo |
| `eagle_design_contract_test.dart` | Anti-patterns (loading/input/list) |
| `ux_feedback_pillar_contract_test.dart` | Toasts + friendlyError + hubs |
| `friendly_error_test.dart` | Humanização HTTP/timeout |
| `accessibility_pillar_contract_test.dart` | Escopo root + labels hubs |
| `a11y_labels_test.dart` | Rótulos PT-BR dashboard/aluno360 |
| `screen_a11y_contract_test.dart` | Root a11y em todas as telas |
| `a11y_controls_contract_test.dart` | Labels em controles |
| `screen_tier_s_plus_contract_test.dart` | Baseline S+ por tela |
| `screen_a11y_contract_test.dart` | Root a11y |

```powershell
flutter test test/core/design_system/
```
