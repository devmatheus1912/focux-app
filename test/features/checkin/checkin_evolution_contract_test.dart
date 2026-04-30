import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';

void main() {
  test('ExecucaoTreino parses automatic load evolution achievements', () {
    final treino = ExecucaoTreino.fromJson({
      'id': 7,
      'treinoId': 2,
      'treinoNome': 'Treino A',
      'status': 'CONCLUIDO',
      'exercicios': const [],
      'evolucoesCarga': [
        {
          'exercicioId': 10,
          'exercicioNome': 'Supino',
          'cargaAnteriorKg': 20,
          'cargaAtualKg': 22.5,
          'diferencaKg': 2.5,
          'percentual': 13,
          'mensagem': 'Boa! Voce evoluiu em Supino.',
        },
      ],
    });

    expect(treino.evolucoesCarga, hasLength(1));
    expect(treino.evolucoesCarga.single.exercicioNome, 'Supino');
    expect(treino.evolucoesCarga.single.cargaAtualKg, 22.5);
    expect(treino.evolucoesCarga.single.percentual, 13);
  });

  test('checkin screen surfaces automatic evolution feedback', () {
    final screen = File(
      'lib/features/checkin/screens/checkin_screen.dart',
    ).readAsStringSync();

    expect(screen, contains('Evolucao registrada'));
    expect(screen, contains('evolucoesCarga'));
    expect(screen, contains('mensagem tambem ficou salva no chat'));
  });
}
