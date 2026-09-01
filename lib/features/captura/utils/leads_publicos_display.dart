import '../../../core/utils/fx_utils.dart';

String leadPublicoNome(String? nome) {
  final value = nome?.trim();
  if (value == null || value.isEmpty) return 'Lead';
  return fxTitleCaseName(value);
}

String leadPublicoSubtitle({
  String? telefone,
  String? email,
  String? objetivo,
}) {
  final parts = <String>[];
  final tel = telefone?.trim();
  if (tel != null && tel.isNotEmpty) parts.add(tel);
  final mail = email?.trim();
  if (mail != null && mail.isNotEmpty) parts.add(mail);
  final obj = objetivo?.trim();
  if (obj != null && obj.isNotEmpty) parts.add(obj);
  if (parts.isEmpty) return 'Sem contato extra';
  return parts.join(' · ');
}

String leadPublicoValue(bool convertido) =>
    convertido ? 'Convertido' : 'Novo';

String leadPublicoFxIcon(bool convertido) =>
    convertido ? 'circle-check' : 'users';

bool leadPublicoPodeCriarAluno(String? email) {
  final mail = email?.trim();
  return mail != null && mail.isNotEmpty;
}

String leadPublicoHubSubtitle(String? freshness) {
  const base = 'Contatos captados pela sua página';
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}
