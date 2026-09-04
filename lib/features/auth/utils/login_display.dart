String loginEntrarLabel() => 'Entrar';

String loginEntrandoLabel() => 'Entrando…';

String loginEsqueciLabel() => 'Esqueci minha senha';

String loginCriarContaLabel() => 'Criar conta grátis';

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

String loginHelpTitle() => 'Entrar no Focux';

String loginHelpSubtitle() =>
    'Personal usa e-mail da conta. Aluno entra pelo link do personal.';

String loginHelpPersonalBody() =>
    'E-mail e senha, ou Google. A Home abre depois do login.';

String loginHelpAlunoBody() =>
    'Abra o link do personal (?p=slug) ou digite o código do personal abaixo.';

String loginSlugMissingError() =>
    'Informe o código do seu personal ou abra o link (?p=slug).';

String loginSlugFieldLabel() => 'Código do personal';

String loginSlugFieldHint() => 'ex.: joao-silva';
