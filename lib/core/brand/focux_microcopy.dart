/// Microcopy centralizado — PT-BR consistente.
abstract final class FocuxMicrocopy {
  FocuxMicrocopy._();

  static const String version = '1.0.0';

  static const List<String> coreSources = [
    'lib/core/brand/focux_microcopy.dart',
    'lib/core/utils/friendly_error.dart',
    'lib/features/dashboard/utils/dashboard_microcopy.dart',
  ];

  static const List<String> hubCopyPatterns = [
    'FocuxMicrocopy.',
    'friendlyError',
    'focux_microcopy.dart',
    'dashboard_microcopy.dart',
  ];

  static const List<String> automatedGates = [
    'test/core/design_system/microcopy_pillar_contract_test.dart',
    'test/core/ux/friendly_error_test.dart',
  ];

  static const cancelar = 'Cancelar';
  static const salvar = 'Salvar';
  static const tentarNovamente = 'Tentar novamente';
  static const algoSaiuDoAr = 'Algo saiu do ar';
  static const erroAoCarregarAlunos = 'Erro ao carregar alunos';
  static const naoFoiPossivelCarregar = 'Não foi possível carregar';
  static const iaErroGenerico = 'Não foi possível gerar agora. Tente novamente.';

  static const commandCenter = 'Centro de Comando';
  static const alunosEmRisco = 'Alunos em risco';
  static const painelPersonal = 'Painel do personal';

}
