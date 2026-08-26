/// Catálogo Gestalt — agrupamento, continuidade e figura-fundo nos hubs.
abstract final class FocuxGestalt {
  FocuxGestalt._();

  static const String version = '1.0.0';

  /// Proximidade — itens relacionados no mesmo card/seção.
  static const String principleProximity = 'proximity';

  /// Similaridade — list tiles e cards com o mesmo shell visual.
  static const String principleSimilarity = 'similarity';

  /// Continuidade — scroll horizontal com peek de conteúdo.
  static const String principleContinuity = 'continuity';

  /// Figura-fundo — superfícies glass/cards sobre mesh do shell.
  static const String principleFigureGround = 'figure_ground';

  static const List<String> coreSources = [
    'lib/core/gestalt/focux_gestalt.dart',
    'lib/core/theme/focux_hub_typography.dart',
    'lib/core/widgets/fx_shell_scaffold.dart',
    'lib/core/widgets/fx_horizontal_scroll_peek.dart',
    'lib/features/alunos/widgets/aluno360_section_header.dart',
    'lib/features/dashboard/utils/dashboard_screen_helpers.dart',
  ];

  static const List<String> hubGestaltPatterns = [
    'Aluno360SectionHeader',
    'aluno360_section_header',
    'dashboardSectionKickerStyle',
    'FxSettingsGroup',
    'FxHorizontalScrollPeek',
    'fxListTileCardShell',
    'fxListCardDecoration',
    'DashboardSectionHeader',
    'dashboard_section_header',
    'TabBar',
    '_FxChip',
    'FocuxHubTypography',
    'sectionTitle',
  ];

  static const List<String> automatedGates = [
    'test/core/design_system/gestalt_perception_pillar_contract_test.dart',
    'test/core/design_system/visual_hierarchy_pillar_contract_test.dart',
    'test/core/design_system/eagle_design_contract_test.dart',
  ];
}
