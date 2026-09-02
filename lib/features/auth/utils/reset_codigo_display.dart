String resetCodigoContinuarLabel() => 'Continuar';

String resetCodigoContinuandoLabel() => 'Validando…';

String resetCodigoVoltarLoginLabel() => 'Voltar ao login';

String resetCodigoReenviarConfirmTitle() => 'Reenviar código por e-mail?';

String resetCodigoReenviarConfirmMessage() =>
    'Mandamos 6 dígitos de novo. O código anterior deixa de valer.';

String resetCodigoHelpTitle() => 'Digite o código';

String resetCodigoHelpSubtitle() =>
    'Seis dígitos no e-mail. Depois você escolhe a senha nova.';

String resetCodigoHelpCodigoBody() =>
    'Confira spam. Reenviar invalida o código antigo.';

String resetCodigoHelpPapelBody() =>
    'Aluno precisa do ?p=slug. Sem o personal o código não fecha.';

String resetCodigoRoleQuery({required bool isAluno}) =>
    isAluno ? 'aluno' : 'personal';

String resetCodigoEmailHint(String email) {
  final trimmed = email.trim();
  final at = trimmed.indexOf('@');
  if (at <= 0) return 'seu e-mail';
  final local = trimmed.substring(0, at);
  final domain = trimmed.substring(at);
  final shown = local.length <= 1 ? local : '${local[0]}***';
  return '$shown$domain';
}

String resetCodigoNovaSenhaPath({
  required String nonce,
  required bool isAluno,
  String? personalSlug,
}) {
  final role = resetCodigoRoleQuery(isAluno: isAluno);
  final slug = personalSlug?.trim();
  final slugQ =
      slug != null && slug.isNotEmpty
          ? '&p=${Uri.encodeComponent(slug)}'
          : '';
  return '/resetar-senha?resetNonce=${Uri.encodeComponent(nonce)}&role=$role$slugQ';
}
