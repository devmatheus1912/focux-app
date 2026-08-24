import 'package:flutter/material.dart';

import '../theme/tokens_strip.dart';

/// Catálogo de densidade de informação — truncamento, compactação e disclosure.
abstract final class FocuxDensity {
  FocuxDensity._();

  static const String version = '1.0.0';

  /// Lista padrão — padding e gaps confortáveis.
  static const String tierComfortable = 'comfortable';

  /// Lista densa — menos padding vertical e gaps menores.
  static const String tierCompact = 'compact';

  /// Baseline global do Material (`app_theme.dart`).
  static const VisualDensity material = VisualDensity.compact;

  static const List<String> coreSources = [
    'lib/core/density/focux_density.dart',
    'lib/core/theme/app_theme.dart',
    'lib/core/theme/tokens_strip.dart',
    'lib/features/alunos/data/aluno_list_preferences_store.dart',
    'lib/features/dashboard/widgets/dashboard_collapsible_section.dart',
    'lib/features/dashboard/constants/dashboard_layout.dart',
    'lib/features/alunos/constants/aluno_360_layout.dart',
  ];

  static const List<String> hubDensityPatterns = [
    'maxLines',
    'TextOverflow.ellipsis',
    'DashboardCollapsibleSection',
    'collapsedHint',
    'AlunoListPreferences',
    '_listaCompacta',
    'compact:',
    'compactContactPriority',
    'TabBar',
    'VisualDensity',
    'DashboardLayout',
    'Aluno360Layout',
    'FocuxDensity',
  ];

  static const List<String> automatedGates = [
    'test/core/design_system/information_density_pillar_contract_test.dart',
    'test/core/design_system/spacing_layout_pillar_contract_test.dart',
    'test/core/design_system/gestalt_perception_pillar_contract_test.dart',
  ];

  static double listTileVerticalPadding(bool compact) =>
      compact ? TokensStrip.s2 + 2 : TokensStrip.s4;

  static double sectionGap(bool compact) =>
      compact ? TokensStrip.s2 : TokensStrip.s4;

  static double metricGap(bool compact) =>
      compact ? TokensStrip.s2 : TokensStrip.s3;
}
