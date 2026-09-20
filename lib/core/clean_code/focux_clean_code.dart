/// Catálogo de código limpo e escalável — tipos explícitos e composição.
abstract final class FocuxCleanCode {
  FocuxCleanCode._();

  static const String version = '1.0.0';

  /// Extrair quando layout e regra de negócio coexistem no mesmo arquivo.
  static const int mixedResponsibilityLineThreshold = 150;

  static const List<String> coreSources = [
    'lib/core/clean_code/focux_clean_code.dart',
    'test/core/business_logic/business_logic_contract_test.dart',
    'lib/core/refactoring/focux_refactoring.dart',
    'lib/features/alunos/utils/alunos_list_sparkline_logic.dart',
    'lib/features/ia/models/ia_copilot_proxima_acao.dart',
    'lib/features/loja/models/loja_pedido.dart',
    'lib/features/trilhas/models/trilha.dart',
    'lib/features/admin/models/permissao_rbac.dart',
  ];

  static const List<String> hubCompositionPatterns = [
    'design_tokens.dart',
    'tokens_strip.dart',
    'FxShellScaffold',
    'ShellChrome',
    'Aluno360Layout',
    'DashboardLayout',
  ];

  static const List<String> forbiddenHubPatterns = [
    'Map<String, dynamic>',
    'jsonDecode(',
    r"FeedbackHelper.showError(context, '$e')",
    r'FeedbackHelper.showError(context, $e)',
  ];

  static const List<String> automatedGates = [
    'test/core/design_system/clean_scalable_code_pillar_contract_test.dart',
    'test/core/business_logic/business_logic_contract_test.dart',
    'test/core/design_system/robust_refactoring_pillar_contract_test.dart',
    'test/core/design_system/productivity_gates_contract_test.dart',
  ];
}
