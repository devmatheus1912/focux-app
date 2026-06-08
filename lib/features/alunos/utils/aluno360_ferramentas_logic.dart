import '../../../core/theme/tokens_strip.dart';
import '../data/aluno_repository.dart';
import 'aluno360_operacao_logic.dart';

/// Layout + copy helpers for the Ferramentas tab (Aluno 360).
abstract final class Aluno360FerramentasLogic {
  Aluno360FerramentasLogic._();

  static const double narrowBreakpoint = 360;
  static const double sectionHeaderGap = TokensStrip.s2;
  static const double sectionDividerGap = TokensStrip.s3;
  static const double measurementRowGap = 10;

  static int measurementCrossAxisCount(double maxWidth) =>
      maxWidth < narrowBreakpoint ? 2 : 4;

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
      return '${aluno.aderenciaPercent}% · semana';
    }
    final summary = summarizeAderenciaWeek(parseAderenciaSemanal(aderenciaSemanal));
    if (summary.hasAnyCheckin) {
      final n = summary.totalCheckins;
      return '$n chk · sem';
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
