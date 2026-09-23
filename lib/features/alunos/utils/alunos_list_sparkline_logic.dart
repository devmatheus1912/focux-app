import '../../../core/data_viz/focux_data_viz.dart';
import 'aluno360_operacao_logic.dart';

/// Teto por dia — evita spark/percent destrambados se a API mandar lixo.
const alunosListSparklineMaxCheckinsPerDay = 24.0;

/// Sanitiza série semanal da lista (finite, ≥0, capped).
List<AderenciaWeekPoint> alunosListSparklinePointsFromRaw(
  List<double> raw,
) {
  if (raw.isEmpty) return const [];
  return [
    for (final v in raw)
      AderenciaWeekPoint(checkins: _sanitizeCheckins(v)),
  ];
}

double _sanitizeCheckins(double value) {
  if (!value.isFinite || value <= 0) return 0;
  if (value > alunosListSparklineMaxCheckinsPerDay) {
    return alunosListSparklineMaxCheckinsPerDay;
  }
  return value;
}

/// Métricas de aderência para card da lista de alunos.
({List<double> sparkValues, int weeklyCheckins, int? aderenciaPercent})
alunosListSparklineMetrics({
  required List<AderenciaWeekPoint> points,
  int? cachedAderenciaPercent,
}) {
  final raw =
      points.map((e) => _sanitizeCheckins(e.checkins)).toList(growable: false);
  final weeklyCheckins = raw.fold<double>(0, (p, v) => p + v).round();
  final aderenciaPercent =
      cachedAderenciaPercent?.clamp(0, 100) ??
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
