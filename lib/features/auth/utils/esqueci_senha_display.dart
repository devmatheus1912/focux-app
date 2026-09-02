String esqueciEnviarLabel() => 'Enviar código';

String esqueciEnviandoLabel() => 'Enviando…';

String esqueciVoltarLoginLabel() => 'Voltar ao login';

String esqueciConfirmTitle() => 'Enviar código por e-mail?';

String esqueciConfirmMessage() =>
    'Mandamos 6 dígitos para redefinir a senha. Válido por 10 minutos.';

String esqueciHelpTitle() => 'Recuperar senha';

String esqueciHelpSubtitle() =>
    'Código no e-mail. Personal e aluno usam o mesmo fluxo, com o slug do aluno.';

String esqueciHelpCodigoBody() =>
    'O app não diz se o e-mail existe. Se estiver cadastrado, o código chega.';

String esqueciHelpPapelBody() =>
    'Aluno precisa do link com ?p=slug. Sem o personal a recuperação não fecha.';

String esqueciAlunoSemSlugError() =>
    'Abra o link do seu personal (?p=slug) para recuperar a senha de aluno.';

String esqueciRoleQuery({required bool isAluno}) =>
    isAluno ? 'aluno' : 'personal';

String esqueciLoginPath({required bool isAluno, String? personalSlug}) {
  final role = esqueciRoleQuery(isAluno: isAluno);
  final slug = personalSlug?.trim();
  if (slug != null && slug.isNotEmpty) {
    return '/login?role=$role&p=${Uri.encodeComponent(slug)}';
  }
  return '/login?role=$role';
}

String esqueciVerificarCodigoPath({
  required String email,
  required bool isAluno,
  String? personalSlug,
}) {
  final role = esqueciRoleQuery(isAluno: isAluno);
  final encoded = Uri.encodeComponent(email.trim());
  final slug = personalSlug?.trim();
  final slugQ =
      slug != null && slug.isNotEmpty
          ? '&p=${Uri.encodeComponent(slug)}'
          : '';
  return '/resetar-senha/verificar-codigo?email=$encoded&role=$role$slugQ';
}

String esqueciEnvironmentTitle(String? issueTitle) {
  final title = issueTitle?.trim();
  if (title != null && title.isNotEmpty) return title;
  return 'E-mail de recuperação pendente';
}

String esqueciEnvironmentWarning({
  required bool hasIssue,
  String? issueDetail,
}) {
  if (hasIssue) {
    final detail = issueDetail?.trim();
    if (detail != null && detail.isNotEmpty) return detail;
    return 'O pedido de reset será registrado, mas a entrega do link depende da configuração de e-mail.';
  }
  return 'Envio de e-mail ainda não está ativo neste ambiente. O pedido será registrado, mas a entrega depende da configuração SMTP.';
}

String esqueciEnvironmentAction({
  String? issueAction,
  List<String> nextActions = const [],
}) {
  final action = issueAction?.trim();
  if (action != null && action.isNotEmpty) return action;
  for (final item in nextActions) {
    if (item.toLowerCase().contains('smtp')) return item;
  }
  return 'Configurar SMTP no ambiente real antes da publicação.';
}
