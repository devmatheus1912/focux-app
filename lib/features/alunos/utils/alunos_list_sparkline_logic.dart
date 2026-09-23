import '../../../core/data_viz/focux_data_viz.dart';
import 'aluno360_operacao_logic.dart';

/// Métricas de aderência para card da lista de alunos.
({List<double> sparkValues, int weeklyCheckins, int? aderenciaPercent})
alunosListSparklineMetrics({
  required List<AderenciaWeekPoint> points,
  int? cachedAderenciaPercent,
}) {
  final raw = points.map((e) => e.checkins).toList(growable: false);
  final weeklyCheckins = raw.fold<double>(0, (p, v) => p + v).round();
  final aderenciaPercent =
      cachedAderenciaPercent ??
      (raw.isEmpty
          ? null
          : ((weeklyCheckins / 7.0) * 100).round().clamp(0, 100));
  // Sem série semanal: empty track honesto (não inventa ritmo com % proxy).
  final sparkValues =
      raw.any((v) => v > 0)
          ? FocuxDataViz.ensureRenderableSeries(raw)
          : const <double>[];
  return (
    sparkValues: sparkValues,
    weeklyCheckins: weeklyCheckins,
    aderenciaPercent: aderenciaPercent,
  );
}
