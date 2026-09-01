String alimentarKcalLabel(int? caloriasDia) {
  if (caloriasDia == null) return 'Sem meta';
  return '$caloriasDia kcal/dia';
}

String alimentarHubSubtitle({
  String? alunoNome,
  String? freshness,
}) {
  const base = 'Nutrição prescrita para o aluno';
  final nome = alunoNome?.trim();
  final stamp = freshness?.trim();
  if (nome != null && nome.isNotEmpty && stamp != null && stamp.isNotEmpty) {
    return '$base · $nome · $stamp';
  }
  if (stamp != null && stamp.isNotEmpty) return '$base · $stamp';
  return base;
}
