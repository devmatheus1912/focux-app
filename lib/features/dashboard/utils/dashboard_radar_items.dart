import '../data/command_center_data.dart';

/// Top-N scores for the Home “radar da base” strip.
List<AlunoScoreResumo> dashboardRadarItems(
  List<AlunoScoreResumo> scores, {
  int limit = 3,
}) {
  if (scores.isEmpty || limit <= 0) return const [];
  return scores.take(limit).toList(growable: false);
}
