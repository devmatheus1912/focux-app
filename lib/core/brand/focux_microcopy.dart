/// Microcopy centralizado — PT-BR consistente.
abstract final class FocuxMicrocopy {
  FocuxMicrocopy._();

  static const String version = '1.0.0';

  static const List<String> coreSources = [
    'lib/core/brand/focux_microcopy.dart',
    'lib/core/utils/friendly_error.dart',
    'lib/features/dashboard/utils/dashboard_microcopy.dart',
    'lib/features/alunos/utils/aluno360_microcopy.dart',
  ];

  static const List<String> hubCopyPatterns = [
    'FocuxMicrocopy.',
    'friendlyError',
    'focux_microcopy.dart',
    'dashboard_microcopy.dart',
    'aluno360_microcopy.dart',
  ];

  static const List<String> automatedGates = [
    'test/core/design_system/microcopy_pillar_contract_test.dart',
    'test/core/ux/friendly_error_test.dart',
  ];

  static const cancelar = 'Cancelar';
  static const salvar = 'Salvar';
  static const tentarNovamente = 'Tentar novamente';
  static const algoDeuErrado = 'Algo deu errado. Tente novamente.';
  static const algoSaiuDoAr = 'Algo saiu do ar';
  static const erroAoCarregarAlunos = 'Erro ao carregar alunos';
  static const naoFoiPossivelCarregar = 'Não foi possível carregar';
  static const iaErroGenerico = 'Não foi possível gerar agora. Tente novamente.';

  static const commandCenter = 'Centro de Comando';
  static const focuxScore = 'Índice Focux';
  static const commandCenterPlusFocuxScore = 'Centro de Comando + Índice Focux';
  static const commandCenterPlusFilaDoDia = 'Centro de Comando + fila do dia';
  static const commandCenterPlusScoreCompact = 'Centro de Comando+Índice Focux';
  static const focuxScoreVisualizacao = 'Índice Focux (visualização)';
  static const focuxScoreAlertasRisco = 'Índice Focux + alertas de risco';
  static const focuxScoreMotorRetencaoIa =
      'Índice Focux + motor de retenção IA';
  static const saudeDaBase = 'Saúde da base';
  static const painelPersonal = 'Painel do personal';

  static const periodoAgora = 'agora';
  static const periodoEsteMes = 'este mês';
  static const periodoMesAnterior = 'mês anterior';
  static const periodoAno = 'ano';
  static const financeiroEsteMes = 'ESTE MÊS';

  static const deslizeHorizontal = 'Deslize horizontalmente para ver mais';
}
