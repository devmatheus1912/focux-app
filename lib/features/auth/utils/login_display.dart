String loginEntrarLabel() => 'Entrar';

String loginEntrandoLabel() => 'Entrando…';

String loginEsqueciLabel() => 'Esqueci minha senha';

String loginCriarContaLabel() => 'Criar conta grátis';

/// Rodapé do login: o aluno não cria conta sozinho, ele ativa com o convite.
String loginRodapeTexto({required bool isAluno}) =>
    isAluno ? 'Recebeu um convite? ' : 'Não tem conta? ';

String loginRodapeAcao({required bool isAluno}) =>
    isAluno ? 'Ativar conta' : loginCriarContaLabel();

String loginRoleQuery({required bool isAluno}) =>
    isAluno ? 'aluno' : 'personal';

String loginEsqueciPath({required bool isAluno, String? personalSlug}) {
  final role = loginRoleQuery(isAluno: isAluno);
  final slug = personalSlug?.trim();
  if (slug != null && slug.isNotEmpty) {
    return '/esqueci-senha?role=$role&p=${Uri.encodeComponent(slug)}';
  }
  return '/esqueci-senha?role=$role';
}

String loginRegisterPath({required bool isAluno, String? personalSlug}) {
  if (!isAluno) return '/register';
  final slug = personalSlug?.trim();
  if (slug != null && slug.isNotEmpty) {
    return '/register/aluno?p=${Uri.encodeComponent(slug)}';
  }
  return '/register/aluno';
}

String loginAjudaLabel() => 'Precisa de ajuda?';

String loginAlunoContexto() => 'Treinando com';

String loginTrocarLabel() => 'Trocar';

String loginSouPersonalLabel() => 'Sou personal';

String loginAlunoSemLinkTexto() => 'É aluno? Abra o link que seu personal enviou. ';

String loginDigitarCodigoLabel() => 'Digitar o código do personal';

String loginHelpTitle() => 'Entrar no Focux';

String loginHelpSubtitle() =>
    'Personal entra com e-mail, Apple ou Google. Aluno entra pelo link do personal.';

String loginHelpPersonalBody() =>
    'E-mail e senha, Apple ou Google. A Home abre depois do login.';

String loginHelpAlunoBody() =>
    'Abra o link de convite do seu personal ou digite o código do personal. Se já entrou antes, o app lembra dele.';

String loginSlugMissingError() =>
    'Informe o código do seu personal ou abra o link (?p=slug).';

String loginSlugFieldLabel() => 'Código do personal';

String loginSlugFieldHint() => 'O código que seu personal enviou';
