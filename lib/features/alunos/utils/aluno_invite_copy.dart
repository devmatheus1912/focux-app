import '../../../l10n/app_localizations.dart';

/// Convite com link de ativação (cadastro, migração ou reenvio).
String alunoAtivacaoMessage(
  S s, {
  required String nome,
  required String link,
  bool reenvio = false,
}) {
  final first = nome.trim().split(RegExp(r'\s+')).first;
  final who = first.isEmpty ? s.alunoAtivacaoNomePadrao : first;
  return reenvio
      ? s.alunoAtivacaoReenvio(who, link)
      : s.alunoAtivacaoConvite(who, link);
}
