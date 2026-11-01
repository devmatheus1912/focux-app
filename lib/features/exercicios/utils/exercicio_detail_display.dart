String exercicioVideoMetric({required bool hasVideo, bool emBreve = false}) =>
    hasVideo
        ? 'Com vídeo'
        : emBreve
        ? 'Em breve'
        : 'Sem vídeo';

String exercicioDificuldadeHint(String? dificuldade) {
  final value = dificuldade?.trim();
  if (value == null || value.isEmpty) return 'Cadastro';
  return value;
}

String exercicioHubSubtitle({required String? grupo}) {
  final group = grupo?.trim();
  if (group == null || group.isEmpty) return 'Exercício';
  return group;
}
