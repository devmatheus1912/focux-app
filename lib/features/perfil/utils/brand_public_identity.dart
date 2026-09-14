/// Heurísticas espelhando BE `GoogleSignupSanitizer` (gate de marca pública).
bool isPrivateRelayEmail(String? email) {
  final e = (email ?? '').trim().toLowerCase();
  return e.contains('privaterelay.appleid.com') || e.contains('privaterelay');
}

String suggestSlugFromNome(String nome) {
  var base = nome
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[àáâãä]'), 'a')
      .replaceAll(RegExp(r'[èéêë]'), 'e')
      .replaceAll(RegExp(r'[ìíîï]'), 'i')
      .replaceAll(RegExp(r'[òóôõö]'), 'o')
      .replaceAll(RegExp(r'[ùúûü]'), 'u')
      .replaceAll(RegExp(r'[ç]'), 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (base.isEmpty || base == 'personal') return '';
  if (base.length > 72) {
    base = base.substring(0, 72).replaceAll(RegExp(r'-+$'), '');
  }
  return base;
}

String? validateBrandSlug(String raw) {
  final s = raw.trim().toLowerCase();
  if (s.isEmpty) return 'Informe o link público.';
  if (s.contains('@') ||
      s.contains('privaterelay') ||
      s.contains('appleid')) {
    return 'Use um link de marca, não o e-mail.';
  }
  if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(s)) {
    return 'Só letras minúsculas, números e hífen.';
  }
  if (s.length > 80) return 'Link muito longo (máx. 80).';
  return null;
}
