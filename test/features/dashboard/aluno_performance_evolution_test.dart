import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/aluno_performance_evolution.dart';

void main() {
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

    test('um ponto só não vira gráfico', () {
      expect(alunoTrendPlot(const [0, 0, 0, 0, 0, 0, 0, 90]), isNull);
      expect(alunoTrendPontos(const [0, 0, 0, 0, 0, 0, 0, 90]), 1);
      expect(alunoTrendPlot(const [0, 0, 0, 0, 0, 0, 88, 90]), isNotNull);
    });

    test('min/max ignora zeros nas pontas', () {
      final plot = alunoTrendPlot(const [0, 5, 8, 0]);
      expect(plot!.minVal, 5);
      expect(plot.maxVal, 8);
      expect(plot.indexes, [1, 2]);
    });
  });
}
