import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/aluno_autonomy_plan.dart';
import 'package:focux_app/features/dashboard/utils/aluno_performance_evolution.dart';

void main() {
  group('alunoPerformanceScoreLabel', () {
    test('mapeia faixas', () {
      expect(alunoPerformanceScoreLabel(92), 'Excelente');
      expect(alunoPerformanceScoreLabel(75), 'Em boa forma');
      expect(alunoPerformanceScoreLabel(55), 'No ritmo');
      expect(alunoPerformanceScoreLabel(35), 'Aquecendo');
      expect(alunoPerformanceScoreLabel(10), 'Começando');
    });
  });

  group('buildAlunoPerformanceEvolutionView', () {
    test('monta insight e chart a partir das séries', () {
      final view = buildAlunoPerformanceEvolutionView(
        score: const FocuxScore(
          value: 92,
          rhythmLabel: 'Ritmo alto',
          riskLabel: 'Baixo risco',
          nextSignal: 'Siga no treino A',
        ),
        historico: const [],
        volumeSemanaKg: 240,
        volumeMesKg: 1800,
        volumePorSemana: const [10, 20, 30, 40, 50, 60, 70, 80],
        forcaPorSemana: const [20, 22, 24, 26, 28, 30, 32, 40],
      );
      expect(view.scoreLabel, 'Excelente');
      expect(view.hasChart, isTrue);
      expect(view.insight, contains('Força'));
      expect(view.insight, contains('%'));
    });

    test('insight não usa jargão de sinal verde', () {
      final view = buildAlunoPerformanceEvolutionView(
        score: const FocuxScore(
          value: 40,
          rhythmLabel: 'Ritmo construindo',
          riskLabel: 'Baixo risco',
          nextSignal: 'Sinal verde para evolução',
        ),
        historico: const [],
        volumeSemanaKg: 0,
        volumeMesKg: 0,
        volumePorSemana: const [],
        forcaPorSemana: const [],
      );
      expect(view.insight, 'Registre as séries para ver carga e volume.');
      expect(view.insight, isNot(contains('Sinal verde')));
      expect(view.ultimoPrLabel, '—');
    });
  });
}
