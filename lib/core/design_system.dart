/// Design System Focux — ponto de entrada canônico.
///
/// Fonte da verdade: Home Personal (`/dashboard/personal`). Toda tela nova
/// ou refatorada importa DAQUI e usa apenas estes stacks:
///
/// ## Tokens
/// - [TokensStrip] — cor, spacing 8pt (s1–s9), raios (rInput 8 / rCard 12 /
///   rButton 50), blur (16/22/28), glassFill, coloredDepthGlow, elevation,
///   prefersReducedMotion. SEMPRE preferir a EagleTokens quando ambos tiverem
///   o mesmo papel.
/// - [EagleTokens] — semântica extra (good/warn/bad, dark ink/mute) e paleta
///   dark. A escala `radius*` dela é LEGADO: raio novo = TokensStrip.
/// - [BrandPalette] — cor do personal (white-label): softened/deep/accent e
///   papéis de seção. Nunca hardcode teal em tela white-label.
///
/// ## Tipografia
/// - [FocuxHubTypography] — pageTitle/sectionTitle/eyebrow/body/bodyMuted/
///   chip/cardTitle/metric/kpi. Proibido fontSize literal (18/20/22) na UI.
///
/// ## Superfícies
/// - [FxStripCard] / [fxStripCardDecoration] — card padrão (glass strip).
/// - [fxListTileCardShell] / [fxListCardDecoration] — linhas de lista.
/// - [FxShellScaffold] + [FxShellAppBar] — telas satélite (useMesh: true).
/// - [showFxHomeSheet] / [FxHomeSheetSurface] — bottom sheets (radius 28).
/// - [showFxConfirmSheet] — confirmar/cancelar (nunca `AlertDialog`).
/// - [showFxFormSheet] / [showFxNoticeSheet] — formulário curto e aviso.
/// - [CinematicMeshBackground] + [MeshScope] — atmosfera (shell provê;
///   scaffold da tela fica transparente).
///
/// ## Motion & estados
/// - [FxPremiumEntrance] — entrada de body (260/280ms, respeita
///   reduced motion). Toda animação nova checa
///   `TokensStrip.prefersReducedMotion`.
/// - [FxLiquidPrimaryButton] — CTA primário.
/// - Loading = skeleton/shimmer (nunca spinner isolado); erro =
///   `FxErrorState`/`friendlyError` + retry; vazio = `FxEmptyState` com CTA.
///
/// ## Catálogo de pilares (gates de contrato leem ESTE arquivo)
/// Acessibilidade — FocuxA11y — accessibility_pillar_contract_test —
/// TalkBack / VoiceOver.
/// Hierarquia visual & foco — FocuxHubTypography + TokensStrip.layer* —
/// visual_hierarchy_pillar_contract_test.
/// Navegação & arquitetura — FocuxNavigation —
/// navigation_architecture_pillar_contract_test.
/// Tipografia — AppTypography / FocuxTypography / FocuxHubTypography —
/// typography_pillar_contract_test.
/// Hardening mobile & web — FocuxSecurity —
/// security_pillar_contract_test.
/// Código limpo — FocuxCleanCode — Lógica fora da UI — Tipos explícitos —
/// clean_scalable_code_pillar_contract_test.
/// Data viz & conteúdo dinâmico — FocuxDataViz —
/// data_viz_dynamic_content_pillar_contract_test.
/// Densidade de informação — FocuxDensity —
/// information_density_pillar_contract_test.
/// Refatoração robusta — FocuxRefactoring —
/// robust_refactoring_pillar_contract_test.
/// Branding & personalidade — FocuxBranding —
/// branding_personality_pillar_contract_test.
/// Gestalt & percepção — FocuxGestalt — gestalt_perception_pillar_contract_test.
/// Adaptação de plataforma — FocuxPlatform —
/// platform_adaptation_pillar_contract_test.
/// Motion design — FocuxMotion — motion_design_pillar_contract_test.
/// Performance percebida — FocuxPerformance —
/// perceived_performance_pillar_contract_test.
/// UX & feedback — FocuxFeedback — ux_feedback_pillar_contract_test.
/// Componentes & consistência — FocuxComponents —
/// components_consistency_pillar_contract_test.
/// Cores & contraste — FocuxContrast — WCAG —
/// colors_contrast_pillar_contract_test.
/// Espaçamento — FocuxSpacing — FxContentWidthLimiter —
/// spacing_layout_pillar_contract_test.
/// Microcopy — FocuxMicrocopy — microcopy_pillar_contract_test.
/// Gates de produtividade: flutter test · Tier S+.
library;

export 'theme/tokens_strip.dart' show TokensStrip;
export 'theme/design_tokens.dart' show EagleTokens, AppTypography;
export 'theme/brand_palette.dart' show BrandPalette;
export 'theme/focux_hub_typography.dart' show FocuxHubTypography;
export 'theme/shell_chrome.dart' show ShellChrome;
export 'theme/hero_teal.dart';
export 'widgets/fx_shell_scaffold.dart'
    show
        FxShellScaffold,
        FxShellAppBar,
        ShellSurface,
        fxStripCardDecoration,
        fxListCardDecoration,
        fxListTileCardShell;
export 'widgets/fx_strip_card.dart' show FxStripCard;
export 'widgets/fx_home_sheet.dart';
export 'widgets/fx_confirm_sheet.dart' show showFxConfirmSheet;
export 'widgets/fx_form_sheet.dart' show showFxFormSheet, showFxNoticeSheet;
export 'widgets/fx_premium_entrance.dart' show FxPremiumEntrance;
export 'widgets/fx_motion.dart' show FxLiquidPrimaryButton, FxStaggerItem;
export 'widgets/fx_content_width_limiter.dart' show FxContentWidthLimiter;
export 'widgets/cinematic_mesh_background.dart' show CinematicMeshBackground;
export 'widgets/mesh_scope.dart' show MeshScope;
export 'widgets/fx_icon.dart' show FxIcon;
export 'widgets/fx_screen_a11y.dart';
