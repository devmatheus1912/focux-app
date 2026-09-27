import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/aluno_performance_evolution.dart';

void main() {
  group('alunoPerformanceForcaDeltaInsight', () {
    test('usa o delta de 1RM estimado do servidor', () {
      expect(
        alunoPerformanceForcaDeltaInsight(forcaDeltaPercent: 4.5),
        'Força (1RM est.) +4,5% vs semana passada',
      );
      expect(
        alunoPerformanceForcaDeltaInsight(forcaDeltaPercent: -2),
        'Força (1RM est.) -2% vs semana passada',
      );
    });

    test('sem delta não inventa comparação a partir das séries', () {
      expect(
        alunoPerformanceForcaDeltaInsight(
          forcaDeltaPercent: null,
          forcaPorSemana: const [20, 22, 24, 26, 28, 30, 32, 40],
        ),
        'Volume e força nas últimas semanas',
      );
      expect(
        alunoPerformanceForcaDeltaInsight(forcaDeltaPercent: 0, volumePorSemana: const [0, 10]),
        'Volume e força nas últimas semanas',
      );
    });

    test('sem série nenhuma pede registro', () {
      expect(
        alunoPerformanceForcaDeltaInsight(forcaDeltaPercent: null),
        'Registre as séries para ver carga e volume.',
      );
    });
  });

  group('buildAlunoPerformanceEvolutionView', () {
    test('monta insight e chart a partir das séries', () {
      final view = buildAlunoPerformanceEvolutionView(
        historico: const [],
        volumeSemanaKg: 240,
        volumeMesKg: 1800,
        volumePorSemana: const [10, 20, 30, 40, 50, 60, 70, 80],
        forcaPorSemana: const [20, 22, 24, 26, 28, 30, 32, 40],
        forcaDeltaPercent: 25,
      );
      expect(view.hasChart, isTrue);
      expect(view.insight, 'Força (1RM est.) +25% vs semana passada');
    });

    test('insight não usa jargão de sinal verde', () {
      final view = buildAlunoPerformanceEvolutionView(
        historico: const [],
        volumeSemanaKg: 0,
        volumeMesKg: 0,
        volumePorSemana: const [],
        forcaPorSemana: const [],
        forcaDeltaPercent: null,
      );
      expect(view.insight, 'Registre as séries para ver carga e volume.');
      expect(view.insight, isNot(contains('Sinal verde')));
      expect(view.ultimoPrLabel, '—');
    });
  });

  group('alunoTrendPlot', () {
    test('série vazia ou sem valor positivo não plota', () {
      expect(alunoTrendPlot(const []), isNull);
      expect(alunoTrendPlot(const [0, 0, -1]), isNull);
    });

    test('zeros são buracos: fora do min/max e quebram o traço', () {
      final plot = alunoTrendPlot(const [0, 10, 0, 20, 30]);
      expect(plot, isNotNull);
      expect(plot!.indexes, [1, 3, 4]);
      expect(plot.values, [10.0, 20.0, 30.0]);
      expect(plot.minVal, 10);
      expect(plot.maxVal, 30);
      expect(plot.slotCount, 5);
      expect(plot.startsSegment(0), isTrue);
      expect(plot.startsSegment(1), isTrue);
      expect(plot.startsSegment(2), isFalse);
      expect(plot.isIsolated(0), isTrue);
      expect(plot.isIsolated(1), isFalse);
      expect(plot.isIsolated(2), isFalse);
    });

    test('min/max ignora zeros nas pontas', () {
      final plot = alunoTrendPlot(const [0, 5, 8, 0]);
      expect(plot!.minVal, 5);
      expect(plot.maxVal, 8);
      expect(plot.indexes, [1, 2]);
    });
  });
}
