import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/aluno360_operacao_logic.dart';
import 'package:focux_app/features/alunos/utils/alunos_list_sparkline_logic.dart';

void main() {
  test('computes weekly checkins and aderencia percent', () {
    final metrics = alunosListSparklineMetrics(
      points: const [
        AderenciaWeekPoint(checkins: 1),
        AderenciaWeekPoint(checkins: 2),
        AderenciaWeekPoint(checkins: 0),
      ],
    );
    expect(metrics.sparkValues, [1, 2, 0]);
    expect(metrics.weeklyCheckins, 3);
    expect(metrics.aderenciaPercent, 43);
  });

  test('uses cached aderencia when provided', () {
    final metrics = alunosListSparklineMetrics(
      points: const [AderenciaWeekPoint(checkins: 7)],
      cachedAderenciaPercent: 88,
    );
    expect(metrics.aderenciaPercent, 88);
  });

  test('empty sparkline when only percent proxy (no week points)', () {
    final metrics = alunosListSparklineMetrics(
      points: const [],
      cachedAderenciaPercent: 72,
    );
    expect(metrics.sparkValues, isEmpty);
    expect(metrics.weeklyCheckins, 0);
    expect(metrics.aderenciaPercent, 72);
  });

  test('sanitiza negativos, NaN e valores absurdos', () {
    final points = alunosListSparklinePointsFromRaw(const [
      -3,
      double.nan,
      double.infinity,
      99,
      2,
    ]);
    expect(points.map((e) => e.checkins).toList(), [
      0,
      0,
      0,
      alunosListSparklineMaxCheckinsPerDay,
      2,
    ]);
    final metrics = alunosListSparklineMetrics(points: points);
    expect(metrics.weeklyCheckins, 26);
    expect(metrics.aderenciaPercent, inInclusiveRange(0, 100));
  });
}
