/// Catálogo de refatoração robusta — decomposição de telas e camadas.
abstract final class FocuxRefactoring {
  FocuxRefactoring._();

  static const String version = '1.0.0';

  /// Telas acima disso devem usar `part` ou utils/widgets do módulo.
  static const int monolithicPartThreshold = 900;

  static const List<String> coreSources = [
    'lib/core/refactoring/focux_refactoring.dart',
    'tools/find_orphan_dart.dart',
    'test/support/screen_source_bundle.dart',
    'test/core/business_logic/business_logic_contract_test.dart',
  ];

  static const Map<String, String> hubDecompositionMarkers = {
    'lib/features/dashboard/screens/personal_dashboard_screen.dart':
        "part 'personal_dashboard_screen_state.part.dart'",
    'lib/features/alunos/screens/aluno_detail_screen.dart':
        'aluno360_operacao_logic.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart':
        "part 'alunos_list_screen_state.part.dart'",
    'lib/features/treinos/screens/treinos_list_screen.dart':
        "part 'treinos_list_screen_state.part.dart'",
    'lib/features/financeiro/screens/financeiro_screen.dart':
        'financeiro_mensalidades_tab.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart':
        "part 'ia_copiloto_screen_actions.part.dart'",
  };

  static const List<String> hubRefactoringPatterns = [
    '/utils/',
    '/widgets/',
    "part '",
    '/constants/',
    '../providers/',
  ];

  static const List<String> automatedGates = [
    'test/core/design_system/robust_refactoring_pillar_contract_test.dart',
    'test/core/business_logic/business_logic_contract_test.dart',
    'test/core/design_system/productivity_gates_contract_test.dart',
    'test/core/monolith/monolith_threshold_contract_test.dart',
  ];

  static bool requiresDecomposition(int lineCount) =>
      lineCount > monolithicPartThreshold;
}
