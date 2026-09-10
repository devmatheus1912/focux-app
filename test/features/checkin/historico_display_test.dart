import 'package:flutter_test/flutter_test.dart';
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
      '3/4 séries · 80 kg · RPE 8 · Dor · Feito',
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
      historicoPrLine(exercicioNome: 'Supino', mensagem: 'Carga nova'),
      'Supino · Carga nova',
    );
  });
}
