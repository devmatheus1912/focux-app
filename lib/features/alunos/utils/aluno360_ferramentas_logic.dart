import '../../../core/theme/tokens_strip.dart';
import '../data/aluno_repository.dart';
import 'aluno360_operacao_logic.dart';

/// Layout + copy helpers for the Ferramentas tab (Aluno 360).
abstract final class Aluno360FerramentasLogic {
  Aluno360FerramentasLogic._();

  static const double sectionHeaderGap = TokensStrip.s2;
  static const double sectionDividerGap = TokensStrip.s3;

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
    final summary = summarizeAderenciaWeek(
      parseAderenciaSemanal(aderenciaSemanal),
    );
    if (summary.hasAnyCheckin) {
      final n = summary.totalCheckins;
      return '$n check-in${n == 1 ? '' : 's'} na semana';
    }
    final dias = aluno.diasSemTreino;
    if (dias != null && dias >= 7) {
      return '$dias dias sem treino';
    }
    return 'Sem check-ins nesta semana';
  }

  static int measurementsPendingCount({
    required Aluno aluno,
    String? bf,
    String? massaMagra,
  }) {
    var pending = 0;
    if (aluno.idade == null) pending++;
    if (aluno.altura == null) pending++;
    if (bf == null) pending++;
    if (massaMagra == null) pending++;
    return pending;
  }

  static String measurementsSummary({
    required Aluno aluno,
    String? bf,
    String? massaMagra,
  }) {
    final pending = measurementsPendingCount(
      aluno: aluno,
      bf: bf,
      massaMagra: massaMagra,
    );
    if (pending == 0) return 'Perfil e composição completos';
    if (pending == 4) return 'Nenhuma medida registrada ainda';
    return '$pending de 4 campos pendentes';
  }

  static String aderenciaSparkSemanticsLabel(
    List<Map<String, dynamic>>? aderenciaSemanal,
  ) {
    final points = parseAderenciaSemanal(aderenciaSemanal);
    final summary = summarizeAderenciaWeek(points);
    if (points.isEmpty) {
      return 'Sem dados de aderência nesta semana';
    }
    if (!summary.hasAnyCheckin) {
      return 'Sem check-ins nos últimos 7 dias';
    }
    final dayParts = <String>[];
    for (final point in points) {
      final day = weekdayNameFromIso(point.date);
      if (day.isEmpty) continue;
      final status =
          point.checkins > 0
              ? '${point.checkins.round()} check-in${point.checkins == 1 ? '' : 's'}'
              : 'sem registro';
      dayParts.add('$day $status');
    }
    if (dayParts.isNotEmpty) {
      return 'Aderência semanal: ${dayParts.join(', ')}';
    }
    final n = summary.totalCheckins;
    return 'Tendência semanal: $n check-in${n == 1 ? '' : 's'} nos últimos dias';
  }
}
