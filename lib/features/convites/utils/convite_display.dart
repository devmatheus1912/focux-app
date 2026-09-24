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

/// O link só aparece logo depois de gerar; o servidor guarda só o hash.
String conviteVigenteHint({required bool linkVisivel, String? email}) {
  final destino =
      (email ?? '').trim().isEmpty ? 'Um uso' : 'Só para ${email!.trim()}';
  return linkVisivel
      ? '$destino. Some da área de transferência em 1 min.'
      : '$destino. Por segurança o link só aparece ao gerar. Gere outro para reenviar.';
}

const conviteEmailLabel = 'E-mail do aluno (opcional)';
const conviteEmailHint = 'Com e-mail, só essa pessoa consegue usar o link';

String? conviteCadastroEmailDica(String? emailDica) {
  final v = emailDica?.trim() ?? '';
  if (v.isEmpty) return null;
  return 'Este convite é para $v. Use esse e-mail e crie sua senha.';
}

String? conviteEmailInvalido(String raw) {
  final v = raw.trim();
  if (v.isEmpty) return null;
  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
  return ok ? null : 'E-mail inválido';
}

String conviteGeradoLabel({required bool substituiu}) =>
    substituiu ? 'Link anterior deixou de valer.' : 'Link gerado.';

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
