String exercicioVideoMetric({required bool hasVideo}) =>
    hasVideo ? 'Com vídeo' : 'Sem vídeo';

String exercicioDificuldadeHint(String? dificuldade) {
  final value = dificuldade?.trim();
  if (value == null || value.isEmpty) return 'Cadastro';
  return value;
}

String exercicioHubSubtitle({
  required String? grupo,
  String? freshness,
}) {
  final parts = <String>[];
  final group = grupo?.trim();
  if (group != null && group.isNotEmpty) parts.add(group);
  final stamp = freshness?.trim();
  if (stamp != null && stamp.isNotEmpty) parts.add(stamp);
  return parts.join(' · ');
}
