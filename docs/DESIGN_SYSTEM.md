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

## Performance percebida

| Arquivo | Responsabilidade |
|---------|------------------|
| `lib/core/performance/focux_performance.dart` | `FocuxPerformance` — catálogo loading + motion |
| `lib/core/utils/motion_preferences.dart` | `reduceMotionOf`, `fxMotionDuration` — reduced motion OS |
| `lib/core/router/fx_page_transition.dart` | `fxTransitionPage` — transições shell sem animação quando reduzida |
| `lib/core/widgets/skeleton_loader.dart` | `SkeletonLoader`, `SkeletonList` — placeholder estático se reduced motion |
| `lib/core/widgets/fx_loading.dart` | `FxLoading`, `sectionShimmer` — spinner e skeleton de seção |
| `lib/core/widgets/fx_motion.dart` | `FxStaggerItem` — entrada em lista respeitando reduced motion |
| `lib/features/dashboard/widgets/dashboard_shimmer_loading.dart` | Skeleton do hub personal |

### Regras

1. **Async** — estados `loading` usam skeleton/shimmer (`SkeletonList`, `DashboardShimmer`, `FxLoading`); proibido `CircularProgressIndicator` em `lib/features/`.
2. **Reduced motion** — `reduceMotionOf` / `prefersReducedMotion` antes de animar; skeletons estáticos quando `MediaQuery.disableAnimations`.
3. **Listas** — `FxStaggerItem` para entrada progressiva (já desliga com reduced motion).
4. **Navegação** — rotas shell via `fxTransitionPage` (fade/slide ou child direto).
5. **Backend** — API não embute `skeletonDelay` / hints de loading em DTOs.

## Microcopy / UX writing

| Arquivo | Responsabilidade |
|---------|------------------|
| `lib/core/brand/focux_microcopy.dart` | `FocuxMicrocopy` — ações e rótulos globais PT-BR |
| `lib/core/utils/friendly_error.dart` | `friendlyError` — mensagens humanizadas de API/rede |
| `lib/features/dashboard/utils/dashboard_microcopy.dart` | Títulos e CTAs do hub personal |
| `lib/features/alunos/utils/aluno360_microcopy.dart` | Rótulos do hub Aluno 360 |

### Regras

1. **Ações** — `FocuxMicrocopy.tentarNovamente`, `cancelar`, `salvar`; evitar literais duplicados.
2. **Erros** — `friendlyError(e)` em painéis e toasts; títulos via `FocuxMicrocopy` ou utils de módulo.
3. **Hubs** — utils dedicados (`dashboard_microcopy`, `aluno360_microcopy`) para seções recorrentes.
4. **Idioma** — PT-BR em UI de produção; proibido inglês cru (`Loading`, `Retry`, `Save`).
5. **Backend** — API não embute `buttonLabel` / `ctaText` / chaves de microcopy em DTOs.

## Navegação & arquitetura

| Arquivo | Responsabilidade |
|---------|------------------|
| `lib/core/navigation/focux_navigation.dart` | `FocuxNavigation` — catálogo shell + padrões de hub |
| `lib/core/router/safe_navigation.dart` | `safePopOrGo`, `goPersonalShellTab` — back e troca de aba |
| `lib/core/router/role_home.dart` | `goToRoleHome`, `roleHomePath` — home por papel |
| `lib/core/router/fx_page_transition.dart` | Transições de rota no shell |
| `lib/core/router/app_router.dart` | GoRouter — shells Personal e Aluno |

### Regras

1. **Rotas** — `context.push` / `context.go` (GoRouter); proibido `Navigator.push` + `MaterialPageRoute` em hubs.
2. **Back** — `safePopOrGo(context, fallback)` ou `safePopOr` com fallback explícito.
3. **Shell tabs** — `/alunos`, `/treinos`, `/agenda`, `/ia/copiloto` via `goPersonalShellTab`; deep links (`/financeiro`) via `context.go`.
4. **Estado** — hubs com `ref.watch` + `providers/`; lógica pesada em `utils/` (Pilar 3).
5. **Catálogo de rotas** — `routes_pillar_contract_test` + `README.md`; BE sem `deepLinkPath` em DTOs.

## Motion design

| Arquivo | Responsabilidade |
|---------|------------------|
| `lib/core/motion/focux_motion.dart` | `FocuxMotion` — durações, curvas e catálogo de widgets |
| `lib/core/utils/motion_preferences.dart` | `fxMotionDuration`, `reduceMotionOf` — reduced motion OS |
| `lib/core/widgets/fx_motion.dart` | `FxStaggerItem`, `FxSpringButton`, `FxInteractiveGlow`, `FxLiquidPrimaryButton` |
| `lib/core/router/fx_page_transition.dart` | Transições de página (320ms / easeOutCubic) |
| `lib/features/dashboard/utils/dashboard_entry_motion.dart` | Entrada fade/slide do hub personal |

### Regras

1. **Listas** — `FxStaggerItem` (stagger 60ms, entrada 400ms); não animar manualmente item a item.
2. **CTAs** — `FxSpringButton` ou `FxLiquidPrimaryButton`; spring desliga com reduced motion.
3. **Duração** — `fxMotionDuration` / `FocuxMotion.uiTransitionMs` (220ms); zero se `disableAnimations`.
4. **Glow/pulse** — `FxInteractiveGlow` respeita `prefersReducedMotion`.
5. **Backend** — API não embute `animationDuration` / presets de motion em DTOs.

## Adaptação de plataforma

| Arquivo | Responsabilidade |
|---------|------------------|
| `lib/core/platform/focux_platform.dart` | `FocuxPlatform` — breakpoints, safe area, catálogo shell |
| `lib/core/widgets/fx_content_width_limiter.dart` | Largura máx. 960px em tablet/desktop |
| `lib/core/widgets/fx_shell_scaffold.dart` | Scaffold com SafeArea + limiter opcional |
| `lib/core/theme/shell_chrome.dart` | Superfícies glass light/dark |
| `lib/core/screens/main_shell.dart` / `aluno_shell.dart` | Dock + clearance por safe area |
| `lib/core/theme/fx_page_transitions_builder.dart` | Transições em todas as `TargetPlatform` |

### Regras

1. **Breakpoints** — compacto `< 390px` via `FocuxPlatform.isCompact`; desktop `960px` max content.
2. **Safe area** — `FocuxPlatform.safeBottomInset` / `safeTopInset`; `SafeArea` em scrolls full-bleed.
3. **Hubs desktop** — `FxContentWidthLimiter` ou `FxShellScaffold(constrainWidth: true)`.
4. **Módulos** — `DashboardLayout`, `Aluno360Layout` alinhados a `FocuxPlatform.desktopMaxContent`.
5. **Backend** — API não embute `platformSpecific` / layouts por OS em DTOs.

## Gestalt & percepção

| Arquivo | Responsabilidade |
|---------|------------------|
| `lib/core/gestalt/focux_gestalt.dart` | `FocuxGestalt` — princípios e padrões de agrupamento |
| `lib/core/theme/focux_hierarchy.dart` | Hierarquia tipográfica (complementa proximidade) |
| `lib/core/widgets/fx_shell_scaffold.dart` | `fxListTileCardShell`, `fxListCardDecoration` |
| `lib/core/widgets/fx_horizontal_scroll_peek.dart` | Continuidade em carrosséis horizontais |
| `lib/features/alunos/widgets/aluno360_section_header.dart` | Cabeçalho de seção Aluno 360 |
| `lib/features/dashboard/utils/dashboard_screen_helpers.dart` | `dashboardSectionKickerStyle` |

### Regras

1. **Proximidade** — blocos relacionados no mesmo card/seção (`Aluno360SectionHeader`, `DashboardCollapsibleSection`).
2. **Similaridade** — listas via `fxListTileCardShell`; proibido `ListTile` cru (`eagle_design_contract_test`).
3. **Continuidade** — carrosséis com `FxHorizontalScrollPeek` / `DashboardHorizontalScrollPeek`.
4. **Figura-fundo** — cards com `fxListCardDecoration` + `ShellChrome` sobre mesh.
5. **Backend** — API não embute `visualGrouping` / clusters de UI em DTOs.

## Densidade de informação

| Arquivo | Responsabilidade |
|---------|------------------|
| `lib/core/density/focux_density.dart` | `FocuxDensity` — tiers, helpers e padrões de hub |
| `lib/core/theme/app_theme.dart` | `VisualDensity.compact` — baseline global |
| `lib/features/alunos/data/aluno_list_preferences_store.dart` | Preferência de lista compacta (alunos) |
| `lib/features/dashboard/widgets/dashboard_collapsible_section.dart` | Disclosure progressivo no hub personal |
| `lib/features/dashboard/constants/dashboard_layout.dart` | Gaps de seção controlados |
| `lib/features/alunos/constants/aluno_360_layout.dart` | Hero compacto (`compactContactPriority`) |

### Regras

1. **Truncamento** — títulos e métricas com `maxLines` + `TextOverflow.ellipsis`.
2. **Compactação** — listas densas via toggle (`AlunoListPreferences`) ou `compact:` local.
3. **Disclosure** — seções longas colapsáveis (`DashboardCollapsibleSection`, `IaExpandableCopy`).
4. **Segmentação** — hubs grandes divididos em abas (`TabBar`) para reduzir carga cognitiva.
5. **Espaçamento** — densidade via `TokensStrip` / `FocuxDensity.sectionGap`, não padding arbitrário.
6. **Backend** — API não embute `infoDensity` / `maxVisibleItems` em DTOs.

## Branding & personalidade

| Arquivo | Responsabilidade |
|---------|------------------|
| `lib/core/brand/focux_branding.dart` | `FocuxBranding` — catálogo white-label e personalidade |
| `lib/core/brand/focux_brand_copy.dart` | `FocuxBrandCopy` — taglines e tom de produto |
| `lib/core/theme/brand_palette.dart` | Derivações de cor a partir de `corPrimaria` |
| `lib/core/theme/curated_brand_palettes.dart` | Paletas premium com `isReadablePrimary` |
| `lib/core/widgets/focux_brand_tagline.dart` | Tagline unificada (auth/onboarding) |
| `lib/core/providers/personal_brand_provider.dart` | Identidade do personal (`/api/aluno/personal-brand`) |
| `lib/core/theme/theme_provider.dart` | `primaryColorProvider`, `hideFocuxBrandingProvider` |

### Regras

1. **Identidade** — hubs usam `Theme.colorScheme.primary` + `BrandPalette`; proibido hex fixo da marca.
2. **Chrome** — superfícies com `ShellChrome` / `FxShellScaffold` respeitam primária dinâmica.
3. **Copy de marca** — taglines e onboarding só em `FocuxBrandCopy` + `FocuxBrandTagline`.
4. **White-label** — `hideFocuxBranding` / `whiteLabelActive` ocultam marca Focux quando ativo.
5. **Paleta segura** — primárias custom via `CuratedBrandPalette.isReadablePrimary`.
6. **Backend** — identidade (`corPrimaria`, `logoUrl`) só em DTOs de perfil/landing; hubs operacionais sem `brandTagline` em DTOs.

## Data viz & conteúdo dinâmico

| Arquivo | Responsabilidade |
|---------|------------------|
| `lib/core/data_viz/focux_data_viz.dart` | `FocuxDataViz` — tipos de viz e helpers de série |
| `lib/core/theme/fx_chart_theme.dart` | `FxChartTheme` — cores/eixos para `fl_chart` |
| `lib/core/widgets/fx_sparkline.dart` | `FxSparkline` — mini-séries em cards |
| `lib/features/dashboard/utils/dashboard_sparkline_helpers.dart` | Séries check-in/receita do hub personal |
| `lib/features/alunos/utils/aluno360_evolucao_inteligente_logic.dart` | Série de volume Aluno 360 |

### Regras

1. **Séries** — transformação numérica em `utils/` (`dashboard_sparkline_helpers`, `aluno360_evolucao_inteligente_logic`).
2. **Sparklines** — `FxSparkline`; séries vazias degradam para trilho neutro, não quebram layout.
3. **Gráficos** — `fl_chart` ou barras custom com tokens (`FxChartTheme`, `BrandPalette`).
4. **Conteúdo dinâmico** — hubs com `ref.watch` + `.when` (loading/erro/dados); insights IA via `insightsProvider`.
5. **Ponto único** — `FocuxDataViz.ensureRenderableSeries` duplica valor para linha visível.
6. **Backend** — API entrega dados (`evolucaoMensal`, métricas); sem `chartType` / `axisConfig` em DTOs.

## Segurança

| Arquivo | Responsabilidade |
|---------|------------------|
| `lib/core/security/focux_security.dart` | `FocuxSecurity` — catálogo e padrões de hub |
| `lib/core/storage/secure_storage.dart` | JWT/role em `FlutterSecureStorage` |
| `lib/core/api/api_client.dart` | Bearer token, refresh, idempotency, retry |
| `lib/core/api/tls_certificate_pinning.dart` | Pinning opcional (`API_CERT_PINS`) |
| `lib/core/auth/session_invalidator.dart` | Logout seguro (`clearAll`) |
| `lib/core/utils/friendly_error.dart` | Erros humanizados — sem vazar stack/Dio cru |
| `lib/core/widgets/ia_safety_disclaimer.dart` | Disclaimer obrigatório em telas IA |
| `lib/features/assinatura/services/subscription_device_guard.dart` | Bloqueio jailbreak/dev mode em IAP |

### Regras

1. **Tokens** — só `SecureStorage`; features não instanciam `FlutterSecureStorage` direto.
2. **HTTP** — `ApiClient` injeta `Authorization: Bearer`; pinning em pagamentos/IAP.
3. **Erros** — `friendlyError(e)` em toasts/painéis; proibido `$e` em `FeedbackHelper`.
4. **Async** — hubs com `.when` para loading/erro; sem dados sensíveis em logs de UI.
5. **IA** — `IaSafetyDisclaimer` em fluxos generativos.
6. **CI** — `security.yml` (gitleaks) + `semgrep.yml` (SAST).
7. **Backend** — isolamento multi-tenant (`CrossTenantIsolationTest`) + `ApiErrorResponse` uniforme.

## Refatoração robusta

| Arquivo | Responsabilidade |
|---------|------------------|
| `lib/core/refactoring/focux_refactoring.dart` | `FocuxRefactoring` — limiares e mapa de módulos |
| `tools/find_orphan_dart.dart` | Detecta arquivos Dart órfãos em `lib/` |
| `test/support/screen_source_bundle.dart` | Bundle de `part` para gates |
| `test/core/business_logic/business_logic_contract_test.dart` | Lógica fora de hubs críticos |

### Regras

1. **Lógica fora da UI** — regras em `utils/`; widgets só renderizam (`business_logic_contract_test`).
2. **Telas grandes** — acima de 900 LOC: `part` ou `utils/` do módulo (`FocuxRefactoring.monolithicPartThreshold`).
3. **Parts** — `readScreenSourceBundle` inclui `*.part.dart` do mesmo stem nos gates.
4. **Módulos** — financeiro/alunos usam tabs/parts; dashboard/aluno 360 com `*_logic.dart`.
5. **Órfãos** — CI executa `find_orphan_dart.dart`.
6. **Backend** — controllers tier-1 sem `Repository`; services extraídos (`BusinessLogicContractTest`).

## Código limpo & escalável

| Arquivo | Responsabilidade |
|---------|------------------|
| `lib/core/clean_code/focux_clean_code.dart` | `FocuxCleanCode` — padrões de composição e anti-padrões |
| `lib/features/ia/models/ia_copilot_proxima_acao.dart` | DTO imutável — parse na borda API |
| `lib/features/alunos/utils/alunos_list_sparkline_logic.dart` | Métricas puras do sparkline da lista |
| `test/core/business_logic/business_logic_contract_test.dart` | Lógica fora da UI nos hubs críticos |
| `test/core/design_system/clean_scalable_code_pillar_contract_test.dart` | Gate tipos explícitos nos 6 hubs |
| `docs/CODING_STANDARDS.md` | Princípios de código limpo e escalável |

### Regras

1. **Tipos explícitos** — hubs sem `Map<String, dynamic>`; parse em models/DTOs na borda.
2. **Lógica fora da UI** — formatação e regras em `utils/` testáveis (`business_logic_contract_test`).
3. **Composição** — hubs usam `TokensStrip`, `FxShellScaffold`, `Aluno360Layout` / `DashboardLayout`.
4. **Providers finos** — estado derivado calculado fora de `build()`.
5. **Single responsibility** — extrair ao misturar layout + regra (~150 LOC úteis).
6. **Backend** — DTOs imutáveis, services pequenos (`CleanScalableCodeContractTest`).

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
| `perceived_performance_pillar_contract_test.dart` | Skeleton + motion + hubs |
| `microcopy_pillar_contract_test.dart` | PT-BR + friendlyError + hubs |
| `focux_microcopy_test.dart` | Catálogo e utils de módulo |
| `navigation_architecture_pillar_contract_test.dart` | Safe nav + providers + hubs |
| `safe_navigation_test.dart` | `safePopOrGo` e `goPersonalShellTab` |
| `routes_pillar_contract_test.dart` | Shell tabs + deep links (Pilar 2) |
| `motion_design_pillar_contract_test.dart` | Stagger + spring + hubs |
| `focux_motion_test.dart` | Durações e widgets do catálogo |
| `platform_adaptation_pillar_contract_test.dart` | Breakpoints + safe area + hubs |
| `focux_platform_test.dart` | Breakpoints e shells |
| `gestalt_perception_pillar_contract_test.dart` | Agrupamento + list shells + hubs |
| `focux_gestalt_test.dart` | Princípios e widgets de seção |
| `information_density_pillar_contract_test.dart` | Truncamento + compactação + hubs |
| `focux_density_test.dart` | Tiers e helpers de densidade |
| `branding_personality_pillar_contract_test.dart` | White-label + paleta dinâmica nos hubs |
| `focux_branding_test.dart` | Catálogo e providers de marca |
| `data_viz_dynamic_content_pillar_contract_test.dart` | Sparklines + gráficos + async nos hubs |
| `focux_data_viz_test.dart` | Séries e helpers de visualização |
| `security_pillar_contract_test.dart` | Tokens + erros seguros + IA disclaimer |
| `focux_security_test.dart` | Storage, pinning e workflows CI |
| `robust_refactoring_pillar_contract_test.dart` | Parts/utils + hubs decompostos |
| `focux_refactoring_test.dart` | Limiares e orphan scan |
| `motion_preferences_test.dart` | Reduced motion helpers |
| `screen_tier_s_plus_contract_test.dart` | Baseline S+ por tela |
| `screen_a11y_contract_test.dart` | Root a11y |

```powershell
flutter test test/core/design_system/
```
