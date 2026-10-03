// Copy / gates da tela Marca própria (S2).

const whiteLabelLandingModos = [
  (value: 'CAPTURA', label: 'Formulário'),
  (value: 'SITE', label: 'Página'),
];

/// Verificar só com host salvo (BE lê o domínio persistido) e ainda não verificado.
bool whiteLabelCanVerifyDomain({
  required String domainDraft,
  required String? dominioSalvo,
  required bool dominioVerificado,
}) {
  if (dominioVerificado) return false;
  final draft = domainDraft.trim().toLowerCase();
  if (draft.isEmpty) return false;
  final salvo = (dominioSalvo ?? '').trim().toLowerCase();
  if (salvo.isEmpty) return false;
  return draft == salvo;
}

/// Passos CNAME/TXT a partir de `dnsInstrucoes` do BE — sem inventar host.
List<String> whiteLabelDnsSteps(String dnsInstrucoes) {
  final raw = dnsInstrucoes.trim();
  if (raw.isEmpty) return const [];
  final lines =
      raw
          .split(RegExp(r'[\n\r]+'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .map((l) => l.replaceFirst(RegExp(r'^\d+\)\s*'), ''))
          .toList(growable: false);
  return lines;
}

/// Caption CNAME/TXT — host do draft + token do BE quando existir.
String whiteLabelCnameHint(
  String domainDraft, {
  String? verificacaoToken,
}) {
  final host = domainDraft.trim().toLowerCase();
  if (host.isEmpty) {
    return 'CNAME → cname.focux.app · depois TXT _focux.';
  }
  final token = (verificacaoToken ?? '').trim();
  if (token.isEmpty) {
    return 'CNAME $host → cname.focux.app · salve p/ TXT.';
  }
  final shortTok =
      token.length > 12 ? '${token.substring(0, 10)}…' : token;
  return 'CNAME $host → cname.focux.app · TXT _focux → $shortTok';
}

/// Encurta passo DNS denso do BE para o footer.
String whiteLabelDnsStepShort(String step, {int maxChars = 88}) {
  final t = step.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.length <= maxChars) return t;
  return '${t.substring(0, maxChars - 1)}…';
}

String whiteLabelChecklistValue(bool done) => done ? 'Pronto' : 'Pendente';

String whiteLabelLandingCaption(String modo) =>
    modo == 'CAPTURA'
        ? 'Link curto de captura no dashboard e anúncios.'
        : 'Página completa com foto, planos e depoimentos.';

/// Deep-link do passo pendente — null = já está nesta tela.
String? whiteLabelChecklistRoute(String id) {
  switch (id) {
    case 'entrevista':
    case 'gerado':
    case 'publicado':
      return '/perfil/landing-editor';
    case 'cta':
      return '/perfil/editar';
    default:
      return null;
  }
}

/// SITE exige LANDING_COMPLETA; CAPTURA não.
bool whiteLabelNeedsLandingCompleta(String modo) =>
    modo.trim().toUpperCase() == 'SITE';
