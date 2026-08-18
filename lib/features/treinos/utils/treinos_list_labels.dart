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
