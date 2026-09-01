String referralCodigoLabel(String? codigo) {
  final value = codigo?.trim();
  if (value == null || value.isEmpty) return '—';
  return value;
}

String referralUsosLabel(int usos) {
  if (usos <= 0) return 'Nenhuma ainda';
  if (usos == 1) return '1 convertida';
  return '$usos convertidas';
}

String referralInviteText({
  required String codigo,
  required String link,
}) {
  return 'Use meu código $codigo e ganhe vantagens no Focux Personal!\n$link';
}

bool referralTemLink(String? link) {
  final value = link?.trim();
  return value != null && value.isNotEmpty;
}

String referralHubSubtitle(String? freshness) {
  const base = '30 dias extras no plano';
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}
