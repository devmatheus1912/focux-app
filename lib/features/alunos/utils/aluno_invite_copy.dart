/// Convite pós-cadastro — copy único, sem PII extra além do job (e-mail + senha).
String alunoInviteMessage({
  required String nome,
  required String email,
  required String senhaProvisoria,
}) {
  final first = nome.trim().split(RegExp(r'\s+')).first;
  final who = first.isEmpty ? 'aluno' : first;
  return 'Olá $who! Seu perfil no Focux foi criado.\n\n'
      'Acesse com seu e-mail: $email\n'
      'Senha provisória: $senhaProvisoria\n\n'
      'Altere a senha no primeiro acesso.';
}
