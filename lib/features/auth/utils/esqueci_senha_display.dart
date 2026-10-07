import 'login_display.dart';

String esqueciEnviarLabel() => 'Enviar código';

String esqueciEnviandoLabel() => 'Enviando…';

String esqueciVoltarLoginLabel() => 'Voltar ao login';

String esqueciConfirmTitle() => 'Enviar código por e-mail?';

String esqueciConfirmMessage() =>
    'Mandamos 6 dígitos para redefinir a senha. Válido por 10 minutos.';

String esqueciHelpTitle() => 'Recuperar senha';

bool esqueciMostraCodigo({required bool isAluno}) => !isAluno;

String esqueciAlunoPedePersonalBody() =>
    'Peça um novo link de acesso ao seu personal.';

String esqueciPageSubtitle({required bool isAluno}) =>
    isAluno
        ? esqueciAlunoPedePersonalBody()
        : 'Digite seu e-mail e enviamos um código de 6 dígitos para redefinir sua senha.';

String esqueciHelpSubtitle({bool isAluno = false}) =>
    isAluno
        ? 'O personal envia um link para criar uma senha nova. Não há código por e-mail.'
        : 'Código no e-mail. Válido por 10 minutos.';

String esqueciHelpCodigoBody() =>
    'O app não diz se o e-mail existe. Se estiver cadastrado, o código chega.';

String esqueciHelpPapelBody({bool isAluno = false}) =>
    isAluno
        ? 'Peça ao personal um novo link de acesso. Pelo link você cria a senha e já entra.'
        : 'O código vale para a conta personal deste e-mail.';

String? esqueciAlunoOtpRedirect({required bool isAluno, String? personalSlug}) {
  if (!isAluno) return null;
  return loginEsqueciPath(isAluno: true, personalSlug: personalSlug);
}

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
      slug != null && slug.isNotEmpty ? '&p=${Uri.encodeComponent(slug)}' : '';
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
