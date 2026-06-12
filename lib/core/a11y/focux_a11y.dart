/// Catálogo de acessibilidade — fonte única para gates de leitor de tela.
abstract final class FocuxA11y {
  FocuxA11y._();

  static const String version = '1.0.0';

  static const List<String> coreSources = [
    'lib/core/a11y/focux_a11y.dart',
    'lib/core/widgets/fx_screen_a11y.dart',
    'lib/core/utils/a11y_announce.dart',
  ];

  static const List<String> moduleSources = [
    'lib/features/dashboard/utils/dashboard_a11y.dart',
    'lib/features/alunos/utils/aluno360_a11y.dart',
  ];

  static const List<String> hubA11yPatterns = [
    'fxScreenA11yScope',
    'Semantics(',
    'dashboard_a11y',
    'aluno360_a11y',
    'semanticsLabel:',
    'Semantics(label:',
    'tooltip:',
  ];

  static const List<String> automatedGates = [
    'test/core/design_system/screen_a11y_contract_test.dart',
    'test/core/design_system/a11y_controls_contract_test.dart',
    'test/core/design_system/accessibility_pillar_contract_test.dart',
  ];
}
