import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _alunoDetailLibrarySource() {
  const dir = 'lib/features/alunos/screens';
  const mainFile = '$dir/aluno_detail_screen.dart';
  const providersFile = 'lib/features/alunos/providers/aluno_detail_providers.dart';
  final main = File(mainFile).readAsStringSync();
  final providers = File(providersFile).readAsStringSync();
  final partPattern = RegExp(r"part '([^']+\.part\.dart)';");
  final parts = partPattern
      .allMatches(main)
      .map((m) => File('$dir/${m.group(1)!}').readAsStringSync())
      .join('\n');
  return '$main\n$providers\n$parts';
}

void main() {
  test('aluno detail exposes 360 view and prescriptive copilot actions', () {
    final screen = _alunoDetailLibrarySource();

    expect(screen, contains('class _Aluno360CopilotCard'));
    expect(screen, contains('Aluno 360'));
    expect(screen, contains('class _Aluno360TimelineCard'));
    expect(screen, contains("'Linha do tempo 360'"));
    expect(screen, contains('aluno360Provider'));
    expect(screen, contains('buscarAluno360'));
    expect(screen, contains('class _Timeline360Tile'));
    expect(screen, contains('alunoCopilotoActionProvider'));
    expect(screen, contains('proximaAcao(alunoId)'));
    expect(screen, contains('salvarAcaoCopiloto'));
    expect(screen, contains('commandCenterProvider'));
    expect(screen, contains('class _Aluno360SignalTile'));
    expect(screen, contains('class _CopilotPrescription'));
    expect(screen, contains('Clipboard.setData'));
    expect(screen, contains('_mensagemPronta'));
    expect(screen, contains("'Criar tarefa'"));
    expect(screen, contains("'Copiar'"));
    expect(screen, contains("'Mensagem sugerida'"));
    expect(screen, contains("'Abrir chat'"));
    expect(screen, contains('perfil, autonomia e financeiro'));
  });

  test('aluno 360 polish: tabs, unified status, refresh, altura, sparkline', () {
    final screen = _alunoDetailLibrarySource();

    expect(screen, contains('class _AlunoOperationalStatusSection'));
    expect(screen, contains('Status operacional'));
    expect(screen, contains('Índice operacional'));
    expect(screen, contains('Sinais atualizados para priorizar sua ação'));
    expect(screen, contains('Sugestão offline'));
    expect(screen, contains('invalidateAluno360Providers'));
    expect(screen, contains('alunoPesoHistoricoProvider'));
    expect(screen, contains('alunoAderenciaSemanalProvider'));
    expect(screen, contains('AnimatedSwitcher'));
    expect(screen, contains('hasOpenCopilotTask'));
    expect(screen, contains('Abrir no Command Center'));
    expect(screen, contains('class _WeightTrendSparkline'));
    expect(screen, contains('FxSparkline'));
    expect(screen, contains('formatAlturaDisplay'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('_AlunoDetailTabBarDelegate'));
    expect(screen, contains("Tab(text: 'Operação')"));
    expect(screen, contains("Tab(text: 'Evolução')"));
    expect(screen, contains("Tab(text: 'Ferramentas')"));
    expect(screen, contains('class _AlunoDetailOperacaoTab'));
    expect(screen, contains('class _AlunoDetailEvolucaoTab'));
    expect(screen, contains('class _AlunoDetailFerramentasTab'));
    expect(screen, contains('FxLoading.sectionShimmer'));
    expect(screen, contains('alunoCopilotoForceIaProvider'));
    expect(screen, contains('proximaAcao360'));
    expect(screen, contains('/financeiro?alunoId='));
    expect(screen, contains('_OperacaoStickyCtaBar'));
    expect(screen, isNot(contains('Pulso operacional')));
    expect(screen, isNot(contains('Score API')));
    expect(screen, contains('part \'aluno_detail_actions.part.dart\';'));
    expect(screen, contains('riscoMetricIcon'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('copySensitiveToClipboard'));
    expect(screen, isNot(contains('Erro: \$e')));
    expect(screen, isNot(contains('operational_metrics.part.dart')));
    expect(screen, contains('CollapseMode.parallax'));
  });

  test('aluno 360 fase 3: tabs, semantics, friendly errors, shared tile', () {
    final screen = _alunoDetailLibrarySource();

    expect(screen, contains('class _AlunoDetailOperacaoTab'));
    expect(screen, contains('_OperacaoStickyCtaBar'));
    expect(screen, contains('_AlunoOperationalStatusSection'));
    expect(screen, contains('Ações rápidas da aba operação'));
    expect(screen, contains('class _AlunoDetailEvolucaoTab'));
    expect(screen, contains('_Aluno360TimelineCard'));
    expect(screen, contains('Linha do tempo 360'));
    expect(screen, contains('Ver histórico completo da linha do tempo'));
    expect(screen, contains('class _AlunoDetailFerramentasTab'));
    expect(screen, contains("'Módulos'"));
    expect(screen, contains('class _ModuleTile'));
    expect(screen, contains('Abas do perfil do aluno'));
    expect(screen, contains('ValueKey(\'aluno360_operacao_status\')'));
    expect(screen, contains('ValueKey(\'aluno360_operacao_sticky_cta\')'));
    expect(screen, contains('ValueKey(\'aluno360_evolucao_empty\')'));
    expect(screen, contains('ValueKey(\'aluno360_timeline_empty\')'));
    expect(screen, contains('ValueKey(\'aluno360_ferramentas_modulos\')'));
    expect(screen, contains('class _Aluno360ActionEmptyPanel'));
    expect(screen, contains('Sem sinais de evolução ainda'));
    expect(screen, contains('Linha do tempo ainda vazia'));
    expect(screen, contains('friendlyError(e, fallback: \'Não foi possível gerar senha.\')'));
    expect(
      File('lib/core/widgets/operational_metric_tile.dart').readAsStringSync(),
      contains('class OperationalMetricTile'),
    );
    expect(
      File('lib/features/dashboard/widgets/dashboard_pulse_strip.dart').readAsStringSync(),
      contains('operationalMetricDecoration'),
    );
  });
}
