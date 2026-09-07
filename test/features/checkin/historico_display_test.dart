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
  });

  test('historico filtra busca e chip no carregado', () {
    expect(
      historicoMatchesQuery(treinoNome: 'Peito A', query: 'peito'),
      isTrue,
    );
    expect(
      historicoMatchesQuery(treinoNome: 'Peito A', query: 'perna'),
      isFalse,
    );
    expect(
      historicoMatchesChip(
        status: 'CONCLUIDO',
        chip: HistoricoStatusChip.concluido,
      ),
      isTrue,
    );
    expect(
      historicoMatchesChip(
        status: 'CONCLUIDO',
        chip: HistoricoStatusChip.andamento,
      ),
      isFalse,
    );
  });
}
