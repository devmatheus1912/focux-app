String desafioHubSubtitle(String? freshness) {
  const base = 'Ranking e metas da comunidade';
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}

String desafioSubtitle({required String tipo, required int metaPontos}) {
  final kind = tipo.trim().isEmpty ? 'HABITOS' : tipo.trim();
  return '$kind · meta $metaPontos pts';
}

String desafioLeaderboardEmpty() => 'Nenhum participante com pontos ainda.';

String desafioLeaderboardName(String? nome) {
  final value = nome?.trim();
  if (value == null || value.isEmpty) return 'Aluno';
  return value;
}

String desafioLeaderboardPoints(Object? pontos) => '${pontos ?? 0} pts';
