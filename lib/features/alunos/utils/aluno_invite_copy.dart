import '../../../core/config/env.dart';

/// Convite pós-cadastro / senha provisória — e-mail + senha + link com slug.
String alunoInviteMessage({
  required String nome,
  required String email,
  required String senhaProvisoria,
  String? personalSlug,
}) {
  final first = nome.trim().split(RegExp(r'\s+')).first;
  final who = first.isEmpty ? 'aluno' : first;
  final slug = personalSlug?.trim();
  final linkBlock =
      (slug != null && slug.isNotEmpty)
          ? 'Abra o link do seu personal (obrigatório):\n'
              '${Env.alunoLoginUrl(slug)}\n\n'
          : 'Peça ao personal o link de acesso (?p=slug) antes de entrar.\n\n';
  return 'Olá $who! Seu perfil no Focux foi criado.\n\n'
      '$linkBlock'
      'Acesse com seu e-mail: $email\n'
      'Senha provisória: $senhaProvisoria\n\n'
      'Altere a senha no primeiro acesso.';
}

String alunoSenhaProvisoriaMessage({
  required String nome,
  required String email,
  required String senha,
  String? personalSlug,
}) {
  final primeiroNome =
      nome.trim().isEmpty ? 'tudo bem' : nome.trim().split(RegExp(r'\s+')).first;
  final slug = personalSlug?.trim();
  final linkBlock =
      (slug != null && slug.isNotEmpty)
          ? 'Abra o link do seu personal (obrigatório):\n'
              '${Env.alunoLoginUrl(slug)}\n\n'
          : 'Peça ao personal o link de acesso (?p=slug) antes de entrar.\n\n';
  return 'Olá $primeiroNome! Redefinimos seu acesso ao Focux.\n\n'
      '$linkBlock'
      'Entre com seu e-mail: $email\n'
      'Senha provisória: $senha\n\n'
      'No primeiro acesso, troque por uma senha sua.';
}
