import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/models/checkin_execucao_models.dart';
import 'package:focux_app/core/widgets/fx_week_strip.dart';
import 'package:focux_app/features/dashboard/utils/aluno_semana_faixa.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';

RotinaFila _ficha(Map<int, String> treinosPorDia) => RotinaFila(
  itens: [
    for (final (i, e) in treinosPorDia.entries.indexed)
      RotinaItem(
        id: i + 1,
        tipo: RotinaItemTipo.treino,
        treinoId: i + 10,
        nome: e.value,
        diaSemana: e.key,
      ),
  ],
);

ExecucaoTreino _feito(String concluidoEm) => ExecucaoTreino(
  id: 1,
  treinoId: 10,
  treinoNome: 'Peito',
  status: 'CONCLUIDO',
  concluidoEm: concluidoEm,
  exercicios: const [],
);

// 28/10/2026 é quarta; 29 é quinta.
final _quarta = DateTime(2026, 10, 28, 12);
final _quinta = DateTime(2026, 10, 29, 12);

void main() {
  final ficha = _ficha({1: 'Peito', 3: 'Costas', 5: 'Pernas'});

  test('ficha sem dia de treino não desenha a faixa', () {
    expect(faixaDaSemana(RotinaFila.vazia, const [], _quarta), isEmpty);
  });

  test('sete dias: treino, descanso e hoje marcado', () {
    final dias = faixaDaSemana(ficha, const [], _quarta);
    expect(dias, hasLength(7));
    expect(dias[0].estado, FxWeekDayState.treino);
    expect(dias[1].estado, FxWeekDayState.descanso);
    expect(dias[2].hoje, isTrue);
    expect(dias.where((d) => d.hoje), hasLength(1));
    expect(dias[2].estado, FxWeekDayState.treino);
  });

  test('treino concluído na semana vira concluído, mesmo dia da semana passado', () {
    final dias = faixaDaSemana(
      ficha,
      [_feito(DateTime(2026, 10, 26, 18).toIso8601String())],
      _quarta,
    );
    expect(dias[0].estado, FxWeekDayState.concluido);
    expect(dias[2].estado, FxWeekDayState.treino);
  });

  test('conclusão da semana passada não conta', () {
    final dias = faixaDaSemana(
      ficha,
      [_feito(DateTime(2026, 10, 19, 18).toIso8601String())],
      _quarta,
    );
    expect(dias[0].estado, FxWeekDayState.treino);
  });

  test('hoje de descanso aponta o próximo dia de treino', () {
    final dias = faixaDaSemana(ficha, const [], _quinta);
    expect(dias[3].hoje, isTrue);
    expect(dias[3].estado, FxWeekDayState.descanso);
    expect(dias.where((d) => d.proximo).map((d) => d.dia), [5]);
  });

  test('hoje de treino não marca próximo', () {
    final dias = faixaDaSemana(ficha, const [], _quarta);
    expect(dias.any((d) => d.proximo), isFalse);
  });

  test('descanso explícito no dia não conta como treino', () {
    final dias = faixaDaSemana(
      RotinaFila(
        itens: [
          const RotinaItem(
            id: 1,
            tipo: RotinaItemTipo.treino,
            treinoId: 1,
            nome: 'Peito',
            diaSemana: 1,
          ),
          const RotinaItem(id: 2, tipo: RotinaItemTipo.descanso, diaSemana: 2),
        ],
      ),
      const [],
      _quarta,
    );
    expect(dias[1].estado, FxWeekDayState.descanso);
  });
}
