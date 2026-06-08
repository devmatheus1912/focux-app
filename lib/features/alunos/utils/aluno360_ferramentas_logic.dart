import '../data/aluno_repository.dart';
import 'aluno360_operacao_logic.dart';

/// Layout + copy helpers for the Ferramentas tab (Aluno 360).
abstract final class Aluno360FerramentasLogic {
  Aluno360FerramentasLogic._();

  static const double narrowBreakpoint = 360;

  static int measurementCrossAxisCount(double maxWidth) =>
      maxWidth < narrowBreakpoint ? 2 : 4;

  static double measurementGridChildAspectRatio({
    required int crossAxisCount,
    required bool needsRegistrarHint,
    required double textScale,
  }) {
    final aspectBase =
        crossAxisCount == 2
            ? (needsRegistrarHint ? 1.18 : 1.45)
            : (needsRegistrarHint ? 0.82 : 1.1);
    return aspectBase / textScale.clamp(1.0, 2.2);
  }

  static double modulesGridChildAspectRatio({
    required bool hasBadgeTile,
    required double textScale,
  }) {
    final aspectBase = hasBadgeTile ? 2.05 : 2.3;
    return aspectBase / textScale.clamp(1.0, 2.2);
  }

  static List<double> aderenciaSparklineValues(
    List<Map<String, dynamic>>? raw,
  ) {
    final points = parseAderenciaSemanal(raw);
    if (points.isEmpty) return const [];
    return points.map((p) => p.checkins).toList(growable: false);
  }

  static String aderenciaModuleSub({
    required Aluno aluno,
    List<Map<String, dynamic>>? aderenciaSemanal,
  }) {
    if (aluno.aderenciaPercent != null) {
      return '${aluno.aderenciaPercent}% na semana';
    }
    final summary = summarizeAderenciaWeek(parseAderenciaSemanal(aderenciaSemanal));
    if (summary.hasAnyCheckin) {
      final n = summary.totalCheckins;
      return '$n check-in${n == 1 ? '' : 's'} na semana';
    }
    return 'Sem dados de check-in';
  }

  static String aderenciaSparkSemanticsLabel(
    List<Map<String, dynamic>>? aderenciaSemanal,
  ) {
    final summary = summarizeAderenciaWeek(parseAderenciaSemanal(aderenciaSemanal));
    if (!summary.hasAnyCheckin) {
      return 'Sem check-ins registrados nesta semana';
    }
    final n = summary.totalCheckins;
    return 'Tendência semanal: $n check-in${n == 1 ? '' : 's'} nos últimos dias';
  }
}
