import '../data/command_center_data.dart';

/// Top-N scores for the Home “radar da base” strip.
List<AlunoScoreResumo> dashboardRadarItems(
  List<AlunoScoreResumo> scores, {
  int limit = 3,
}) {
  if (scores.isEmpty || limit <= 0) return const [];
  return scores.take(limit).toList(growable: false);
}

/// Ícone leading do radar — triângulo só no risco alto.
String dashboardRadarIcon(String risco) {
  final normalized = risco.toLowerCase();
  if (normalized.contains('alto')) return 'alert-triangle';
  if (normalized.contains('médio') || normalized.contains('medio')) {
    return 'trend';
  }
  return 'target';
}

String dashboardRadarCaption(int count) {
  if (count <= 0) return '';
  if (count == 1) return '1 aluno · toque para abrir a ficha';
  return '$count alunos · toque para abrir a ficha';
}
