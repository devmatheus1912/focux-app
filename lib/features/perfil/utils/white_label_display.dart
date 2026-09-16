// Copy / gates da tela Marca própria (S2).

/// Verificar domínio só com host preenchido e ainda não verificado.
bool whiteLabelCanVerifyDomain({
  required String domainDraft,
  required bool dominioVerificado,
}) {
  if (dominioVerificado) return false;
  return domainDraft.trim().isNotEmpty;
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

String whiteLabelCnameHint(String domainDraft) {
  final host = domainDraft.trim().toLowerCase();
  if (host.isEmpty) {
    return 'CNAME do subdomínio → cname.focux.app · depois TXT _focux com o token.';
  }
  return 'CNAME $host → cname.focux.app';
}
