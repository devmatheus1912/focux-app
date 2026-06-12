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
| `screen_tier_s_plus_contract_test.dart` | Baseline S+ por tela |
| `screen_a11y_contract_test.dart` | Root a11y |

```powershell
flutter test test/core/design_system/
```
