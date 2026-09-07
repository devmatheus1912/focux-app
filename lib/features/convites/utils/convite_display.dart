String conviteCountLabel({required bool ativo}) =>
    ativo ? '1 convite ativo' : 'Nenhum convite ativo';

String conviteRemainingLabel(DateTime? expiresAt, DateTime now) {
  if (expiresAt == null) return '24h';
  final left = expiresAt.difference(now);
  if (left <= Duration.zero) return 'Expirado';
  final hours = left.inHours;
  final minutes = left.inMinutes.remainder(60);
  if (hours > 0) return '${hours}h ${minutes}min';
  return '${minutes}min';
}

bool conviteAindaValido(DateTime? expiresAt, DateTime now) {
  if (expiresAt == null) return false;
  return expiresAt.isAfter(now);
}

String conviteGeradoLabel({required bool substituiu}) =>
    substituiu
        ? 'Link anterior deixou de valer.'
        : 'Link gerado.';

String conviteShareMessage({
  required String personalNome,
  required String shareLink,
}) {
  final nome = personalNome.trim();
  if (nome.isEmpty) {
    return 'Olá! Use este link para criar sua conta no app do seu personal: $shareLink';
  }
  return 'Olá! Sou $nome. Use este link para criar sua conta no app: $shareLink';
}
