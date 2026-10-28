import '../../../l10n/app_localizations.dart';

/// Quem assina o convite: o personal, o nome do app que o aluno vai baixar e
/// (com white-label) o slogan. Sem isso, o convite fala só de "Focux".
class ConviteMarca {
  const ConviteMarca({
    required this.nomePersonal,
    this.nomeApp = 'Focux',
    this.slogan,
  });

  final String nomePersonal;
  final String nomeApp;
  final String? slogan;

  bool get temPersonal => nomePersonal.trim().isNotEmpty;
}

/// Convite com link de ativação (cadastro, migração ou reenvio).
String alunoAtivacaoMessage(
  S s, {
  required String nome,
  required String link,
  bool reenvio = false,
  ConviteMarca? marca,
}) {
  final first = nome.trim().split(RegExp(r'\s+')).first;
  final who = first.isEmpty ? s.alunoAtivacaoNomePadrao : first;
  if (marca == null || !marca.temPersonal) {
    return reenvio
        ? s.alunoAtivacaoReenvio(who, link)
        : s.alunoAtivacaoConvite(who, link);
  }
  final frase = marca.slogan?.trim() ?? '';
  final slogan = frase.isEmpty ? '' : '\n\u201c$frase\u201d';
  final app = marca.nomeApp.trim().isEmpty ? 'Focux' : marca.nomeApp.trim();
  return reenvio
      ? s.alunoAtivacaoReenvioMarca(who, app, slogan, link)
      : s.alunoAtivacaoConviteMarca(who, marca.nomePersonal.trim(), app, slogan, link);
}
