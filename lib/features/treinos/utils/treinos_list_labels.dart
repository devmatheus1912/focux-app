/// Rótulos plurais da lista de treinos — lógica pura fora da UI.
abstract final class TreinosListLabels {
  TreinosListLabels._();

  static String readyPlans(int count) =>
      count == 1
          ? '1 plano pronto para uso.'
          : '$count planos prontos para uso.';

  static String readyCount(int count) =>
      count == 1 ? '1 pronto' : '$count prontos';

  static String templateCount(int count) =>
      count == 1 ? '1 template' : '$count templates';

  static String libraryCaption({
    required int prontos,
    required int exercises,
  }) => '${readyCount(prontos)} · $exercises exercícios';

  static String prettyField(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return value;
    final normalized = value
        .toUpperCase()
        .replaceAll('Á', 'A')
        .replaceAll('Ã', 'A')
        .replaceAll('Â', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Õ', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ç', 'C');
    const labels = {
      'FORCA': 'Força',
      'HIPERTROFIA': 'Hipertrofia',
      'EMAGRECIMENTO': 'Emagrecimento',
      'CONDICIONAMENTO': 'Condicionamento',
      'MOBILIDADE': 'Mobilidade',
      'INICIANTE': 'Iniciante',
      'INTERMEDIARIO': 'Intermediário',
      'AVANCADO': 'Avançado',
    };
    return labels[normalized] ??
        '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }

  static String cardMeta({
    required bool pronto,
    required int exercises,
    required int series,
    required String? nivel,
  }) {
    if (!pronto) return 'Em montagem';
    final nivelLabel = prettyField(
      (nivel ?? '').trim().isEmpty ? 'Iniciante' : nivel!.trim(),
    );
    final ex = exercises == 1 ? '1 exercício' : '$exercises exercícios';
    final ser = series == 1 ? '1 série' : '$series séries';
    return '$ex · $ser · $nivelLabel';
  }

  static String emptyTitle({String? alunoNome}) =>
      _firstName(alunoNome) == null
          ? 'Sua biblioteca começa aqui'
          : 'Nenhum treino atribuído';

  static String emptySubtitle({String? alunoNome}) {
    final firstName = _firstName(alunoNome);
    if (firstName == null) {
      return 'Crie um plano base, adicione exercícios e use como ponto de partida para seus alunos.';
    }
    return 'Atribua um plano a $firstName ou crie um treino e vincule ao perfil.';
  }

  static String? _firstName(String? alunoNome) {
    final trimmed = alunoNome?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed.split(RegExp(r'\s+')).first;
  }
}
