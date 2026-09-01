const trilhaMetaTipos = ['TREINOS', 'PESO', 'MEDIDA', 'CUSTOMIZADO'];

String trilhaMetaTipoLabel(String? tipo) {
  switch ((tipo ?? '').trim().toUpperCase()) {
    case 'TREINOS':
      return 'Número de treinos';
    case 'PESO':
      return 'Meta de peso';
    case 'MEDIDA':
      return 'Meta de medida';
    case 'CUSTOMIZADO':
      return 'Customizado';
    case '':
      return 'Tipo de meta';
    default:
      return tipo!.trim();
  }
}

String trilhaStatusLabel(bool concluida) =>
    concluida ? 'Concluída' : 'Em andamento';

String trilhaPercentLabel(double percentual) =>
    '${percentual.toStringAsFixed(0)}%';

String trilhaHubSubtitle({
  required String alunoNome,
  String? freshness,
}) {
  final nome = alunoNome.trim().isEmpty ? 'Aluno' : alunoNome.trim();
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return nome;
  return '$nome · $stamp';
}
