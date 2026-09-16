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

/// Passos do "Como funciona" — preenche o fundo do hub sem inventar regra.
const referralComoFuncionaPassos = [
  (
    titulo: '1. Compartilhe o convite',
    detalhe: 'Copie o texto ou só o link e envie para outro personal.',
  ),
  (
    titulo: '2. Ele entra com seu código',
    detalhe: 'O código identifica a indicação no cadastro dele.',
  ),
  (
    titulo: '3. Você ganha 30 dias',
    detalhe: 'Dias extras no seu plano a cada conversão.',
  ),
];

String referralHeaderSubtitle({
  required int usos,
  String? freshness,
}) {
  final parts = <String>[referralUsosLabel(usos)];
  final stamp = freshness?.trim();
  if (stamp != null && stamp.isNotEmpty) parts.add(stamp);
  return parts.join(' · ');
}
