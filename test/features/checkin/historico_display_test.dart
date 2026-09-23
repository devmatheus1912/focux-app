import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/utils/historico_display.dart';

void main() {
  test('historico count e status', () {
    expect(historicoCountLabel(1), '1 treino');
    expect(historicoCountLabel(4), '4 treinos');
    expect(historicoConcluido('CONCLUIDO'), isTrue);
    expect(historicoConcluido('EM_ANDAMENTO'), isFalse);
    expect(historicoStatusLabel('CONCLUIDO'), 'Concluído');
    expect(historicoStatusLabel('EM_ANDAMENTO'), 'Em andamento');
    expect(historicoChipLabel(HistoricoStatusChip.todos), 'Todos');
    expect(historicoStatusQuery(HistoricoStatusChip.todos), isNull);
    expect(historicoStatusQuery(HistoricoStatusChip.concluido), 'CONCLUIDO');
    expect(historicoStatusQuery(HistoricoStatusChip.andamento), 'EM_ANDAMENTO');
    expect(historicoDetalhePath(12), '/checkin/historico/12');
    expect(
      historicoDetalheSubtitle(
        status: 'CONCLUIDO',
        iniciadoEm: '2026-09-07T10:00:00',
      ),
      contains('Concluído'),
    );
    expect(historicoStickyLabel('CONCLUIDO'), 'Treinar de novo');
    expect(historicoStickyLabel('EM_ANDAMENTO'), 'Continuar treino');
    expect(
      historicoExerciciosMetric(done: 2, total: 5),
      '2/5',
    );
    expect(
      historicoExercicioSubtitle(
        seriesFeitas: 3,
        series: 4,
        concluido: true,
      ),
      '3/4 séries · Feito',
    );
    expect(
      historicoExercicioSubtitle(
        seriesFeitas: 3,
        series: 4,
        concluido: true,
        carga: '80 kg',
        rpe: 8,
        dor: true,
      ),
      '80 kg · 3/4 séries · RPE 8 · Dor · Feito',
    );
    expect(historicoRecordesCount(prs: 2, cargas: 1), 3);
    expect(historicoRecordesEmpty(), 'Nenhum recorde nesta sessão');
    expect(historicoDetalheSecoes, hasLength(3));
    expect(
      historicoNotaLine(observacoes: 'Cadência lenta', feedback: 'Boa'),
      'Cadência lenta · Boa',
    );
    expect(historicoNotaLine(), isNull);
    expect(historicoNotasEmpty(), 'Nenhuma nota nesta sessão');
    expect(historicoPrMetric(0), '0');
    expect(historicoPrHint(0), 'Sem recorde nesta sessão');
    expect(historicoPrHint(2), '2 recordes');
    expect(
      historicoDuracaoLabel('2026-09-07T10:00:00', '2026-09-07T11:15:00'),
      '1h 15min',
    );
    expect(
      historicoDuracaoLabel('2026-09-07T10:00:00', null),
      isNull,
    );
    expect(
      historicoExercicioSubtitle(
        seriesFeitas: 1,
        series: 4,
        concluido: false,
        sessaoConcluida: true,
      ),
      '1/4 séries · Parcial',
    );
    expect(
      historicoExercicioSubtitle(
        seriesFeitas: 0,
        series: 4,
        concluido: false,
        sessaoConcluida: true,
      ),
      '0/4 séries · Sem séries',
    );
    expect(
      historicoSeriesFeitasEfetivas(seriesFeitas: 0, seriesDetalhesCount: 3),
      3,
    );
    expect(
      historicoSeriesFeitasEfetivas(seriesFeitas: 4, seriesDetalhesCount: 2),
      4,
    );
    expect(
      historicoExercicioConcluidoEfetivo(
        concluido: false,
        seriesFeitas: 4,
        series: 4,
      ),
      isTrue,
    );
    expect(
      historicoPrLine(exercicioNome: 'Supino', mensagem: 'Carga nova'),
      'Supino · Carga nova',
    );
  });

  test('historicoGroupByStatus separa em andamento e concluídos', () {
    final items = [
      ExecucaoTreino(
        id: 1,
        treinoId: 10,
        treinoNome: 'A',
        status: 'EM_ANDAMENTO',
        iniciadoEm: '2026-09-18T10:00:00',
        exercicios: const [],
      ),
      ExecucaoTreino(
        id: 2,
        treinoId: 11,
        treinoNome: 'B',
        status: 'CONCLUIDO',
        iniciadoEm: '2026-09-17T10:00:00',
        exercicios: const [],
      ),
      ExecucaoTreino(
        id: 3,
        treinoId: 12,
        treinoNome: 'C',
        status: 'EM_ANDAMENTO',
        iniciadoEm: '2026-09-16T10:00:00',
        exercicios: const [],
      ),
    ];
    final grouped = historicoGroupByStatus(items);
    expect(grouped.andamento.map((e) => e.id), [1, 3]);
    expect(grouped.concluidos.map((e) => e.id), [2]);
  });

  test('historicoCollapseSamePlan agrupa plano e status iguais', () {
    final items = [
      ExecucaoTreino(
        id: 1,
        treinoId: 10,
        treinoNome: 'Full Body',
        status: 'CONCLUIDO',
        iniciadoEm: '2026-09-18T10:00:00',
        exercicios: const [],
      ),
      ExecucaoTreino(
        id: 2,
        treinoId: 10,
        treinoNome: 'Full Body',
        status: 'CONCLUIDO',
        iniciadoEm: '2026-09-17T10:00:00',
        exercicios: const [],
      ),
      ExecucaoTreino(
        id: 3,
        treinoId: 11,
        treinoNome: 'Push',
        status: 'CONCLUIDO',
        iniciadoEm: '2026-09-16T10:00:00',
        exercicios: const [],
      ),
    ];
    final clusters = historicoCollapseSamePlan(items);
    expect(clusters, hasLength(2));
    expect(clusters.first.newest.id, 1);
    expect(clusters.first.count, 2);
    expect(clusters.last.newest.id, 3);
    expect(historicoClusterSubtitle(dateLabel: '18 set', count: 2), '2 sessões · 18 set');
    expect(historicoStatusDisplayLabel(status: 'CONCLUIDO', seriesFeitas: 0), 'Concluído sem séries');
    expect(historicoEmptySeriesSummary(3), '3 exercícios sem séries');
  });
}
