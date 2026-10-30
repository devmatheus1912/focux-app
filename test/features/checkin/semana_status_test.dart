import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/utils/treinos_hub_view.dart';

ExecucaoTreino _feito(String quando, {String status = 'CONCLUIDO'}) =>
    ExecucaoTreino(
      id: 1,
      treinoId: 1,
      treinoNome: 'Treino A',
      status: status,
      iniciadoEm: quando,
      concluidoEm: quando,
      exercicios: const [],
    );

void main() {
  test('dias feitos: só concluídos da semana atual (segunda a domingo)', () {
    final quarta = DateTime(2026, 10, 28, 9); // quarta
    final dias = feitosDaSemana([
      _feito('2026-10-26T08:00:00'), // segunda desta semana
      _feito('2026-10-27T08:00:00', status: 'EM_ANDAMENTO'), // não concluído
      _feito('2026-10-25T08:00:00'), // domingo da semana passada
    ], quarta);
    expect(dias.keys, [1]);
  });

  test('dois treinos no mesmo dia aparecem os dois', () {
    final dias = feitosDaSemana([
      _feito('2026-10-26T08:00:00'),
      _feito('2026-10-26T18:00:00'),
    ], DateTime(2026, 10, 28, 9));
    expect(dias[1], hasLength(2));
  });
}
