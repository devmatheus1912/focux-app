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
| `screen_tier_s_plus_contract_test.dart` | Baseline S+ por tela |
| `screen_a11y_contract_test.dart` | Root a11y |

```powershell
flutter test test/core/design_system/
```
