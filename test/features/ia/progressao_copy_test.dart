import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/models/progressao_sugestao.dart';
import 'package:focux_app/features/ia/utils/progressao_copy.dart';

void main() {
  test('progressaoPendingReviewLabel pluraliza corretamente', () {
    expect(progressaoPendingReviewLabel(0), 'Revisar sugestões pendentes');
    expect(progressaoPendingReviewLabel(1), 'Revisar 1 sugestão pendente');
    expect(progressaoPendingReviewLabel(3), 'Revisar 3 sugestões pendentes');
  });

  test('chrome e limites do pedido de progressão', () {
    expect(progressaoObservacoesMax, 500);
    expect(progressaoHubSubtitle(''), 'Sugestão de carga, só se você pedir');
    expect(progressaoHubSubtitle('  Ana  '), 'Ana · só se você pedir');
    expect(progressaoStickyLabel(hasResult: false), 'Gerar progressão');
    expect(progressaoStickyLabel(hasResult: true), 'Gerar outra');
    expect(progressaoPendingMetricHint(0), 'Nada pendente neste aluno');
    expect(progressaoPendingMetricHint(1), '1 sugestão para revisar');
    expect(progressaoStickyLoadingLabel(), 'Gerando…');
    expect(progressaoConfirmTitle(), 'Gerar progressão com IA?');
    expect(progressaoConfirmLabel(), 'Gerar');
  });

  test('objetivo manda o valor da API', () {
    expect(ProgressaoObjetivo.forca.api, 'FORCA');
    expect(ProgressaoObjetivo.resistencia.label, 'Resistência');
  });

  test('linha de contexto resume treino e execuções', () {
    const resumo = ProgressaoContextoResumo(
      treinos: ['Treino A', 'Treino B'],
      exercicios: 8,
      exerciciosComHistorico: 6,
      sessoes4Semanas: 5,
    );
    expect(
      progressaoContextoLine(resumo),
      'Treino A, Treino B · 8 exercícios · 5 treinos concluídos em 4 semanas',
    );
    const vazio = ProgressaoContextoResumo(
      treinos: ['Full body'],
      exercicios: 1,
      exerciciosComHistorico: 0,
      sessoes4Semanas: 0,
    );
    expect(
      progressaoContextoLine(vazio),
      'Full body · 1 exercício · sem treinos concluídos em 4 semanas',
    );
  });

  test('aceitar todas', () {
    expect(progressaoAceitarTodasLabel(1), 'Aceitar 1 sugestão');
    expect(progressaoAceitarTodasLabel(4), 'Aceitar todas (4)');
    expect(
      progressaoAceitarTodasSnack(
        const ProgressaoAceitarTodasResponse(aplicadas: 3, naoEncontradas: 0),
      ),
      '3 sugestões aplicadas no treino.',
    );
    expect(
      progressaoAceitarTodasSnack(
        const ProgressaoAceitarTodasResponse(aplicadas: 1, naoEncontradas: 2),
      ),
      '1 sugestão aplicada. 2 fora do treino ativo.',
    );
    expect(
      progressaoAceitarTodasSnack(
        const ProgressaoAceitarTodasResponse(aplicadas: 0, naoEncontradas: 16),
      ),
      'Nenhuma sugestão aplicada. 16 fora do treino ativo.',
    );
  });

  test('sugestões fora do treino têm resumo, descarte em lote e snack', () {
    expect(progressaoNaoEncontrada, 'Fora do treino ativo');
    expect(progressaoForaDoTreinoResumo(1), '1 sugestão fora do treino ativo');
    expect(progressaoForaDoTreinoResumo(16), '16 sugestões fora do treino ativo');
    expect(
      progressaoDescartarForaConfirm(16),
      'As 16 sugestões fora do treino ativo serão removidas.',
    );
    expect(progressaoDescartadasSnack(1), '1 sugestão descartada.');
    expect(progressaoDescartadasSnack(16), '16 sugestões descartadas.');
  });

  test('data e nome do PDF', () {
    final d = DateTime(2026, 9, 3, 7, 5);
    expect(progressaoGeradoLabel(d), 'Gerado em 03/09/2026 07:05');
    expect(progressaoSlug('  João da Conceição  '), 'joao-da-conceicao');
    expect(progressaoSlug('!!!'), 'aluno');
    expect(
      progressaoPdfFileName('Ana Lú', d),
      'progressao_ana-lu_2026-09-03.pdf',
    );
  });
}
