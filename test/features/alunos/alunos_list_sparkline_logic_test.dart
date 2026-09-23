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

  test('builds level sparkline from cached percent without week points', () {
    final metrics = alunosListSparklineMetrics(
      points: const [],
      cachedAderenciaPercent: 72,
    );
    expect(metrics.sparkValues, [72.0, 72.0]);
    expect(metrics.weeklyCheckins, 0);
    expect(metrics.aderenciaPercent, 72);
  });
}
