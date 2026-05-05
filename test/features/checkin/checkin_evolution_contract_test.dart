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
      'evolucoesPerformance': [
        {
          'tipo': 'REPETICOES',
          'exercicioId': 10,
          'exercicioNome': 'Supino',
          'valorAnterior': 10,
          'valorAtual': 12,
          'diferenca': 2,
          'percentual': 20,
          'unidade': 'reps',
          'mensagem': 'Boa! Voce fez mais repeticoes em Supino.',
        },
        {
          'tipo': 'VOLUME',
          'exercicioId': 10,
          'exercicioNome': 'Supino',
          'valorAnterior': 200,
          'valorAtual': 270,
          'diferenca': 70,
          'percentual': 35,
          'unidade': 'kg',
          'mensagem': 'Volume maior em Supino.',
        },
      ],
    });

    expect(treino.evolucoesCarga, hasLength(1));
    expect(treino.evolucoesCarga.single.exercicioNome, 'Supino');
    expect(treino.evolucoesCarga.single.cargaAtualKg, 22.5);
    expect(treino.evolucoesCarga.single.percentual, 13);
    expect(treino.evolucoesPerformance, hasLength(2));
    expect(treino.evolucoesPerformance.first.tipo, 'REPETICOES');
    expect(treino.evolucoesPerformance.last.unidade, 'kg');
  });

  test('checkin screen surfaces automatic evolution feedback', () {
    final screen = File(
      'lib/features/checkin/screens/checkin_screen.dart',
    ).readAsStringSync();

    expect(screen, contains('Evolucao registrada'));
    expect(screen, contains('evolucoesPerformance'));
    expect(screen, contains('evolucoesCarga'));
    expect(screen, contains('mensagem tambem ficou salva no chat'));
  });

  test('student dashboard keeps persistent performance evolution card', () {
    final screen = File(
      'lib/features/dashboard/screens/aluno_dashboard_screen.dart',
    ).readAsStringSync();

    expect(screen, contains('Evolução real'));
    expect(screen, contains('Volume semana'));
    expect(screen, contains('Volume mês'));
    expect(screen, contains('evolucoesPerformance'));
  });
}
