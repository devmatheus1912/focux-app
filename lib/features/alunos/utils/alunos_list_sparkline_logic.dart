import 'aluno360_operacao_logic.dart';

/// Métricas de aderência para card da lista de alunos.
({List<double> sparkValues, int weeklyCheckins, int? aderenciaPercent})
alunosListSparklineMetrics({
  required List<AderenciaWeekPoint> points,
  int? cachedAderenciaPercent,
}) {
  final sparkValues = points.map((e) => e.checkins).toList(growable: false);
  final weeklyCheckins = sparkValues.fold<double>(0, (p, v) => p + v).round();
  final aderenciaPercent =
      cachedAderenciaPercent ??
      (sparkValues.isEmpty
          ? null
          : ((weeklyCheckins / 7.0) * 100).round().clamp(0, 100));
  return (
    sparkValues: sparkValues,
    weeklyCheckins: weeklyCheckins,
    aderenciaPercent: aderenciaPercent,
  );
}
