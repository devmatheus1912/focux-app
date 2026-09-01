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

String alimentarDetailSubtitle(String? freshness) {
  const base = 'Refeições e macros do plano';
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}

String alimentarRefeicaoKcalLabel(int? calorias) {
  if (calorias == null) return 'Sem kcal';
  return '$calorias kcal';
}
