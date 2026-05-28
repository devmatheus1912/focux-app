/// Validação leve de qualidade do conteúdo antes de publicar a landing.
library;

bool landingTextLooksLikePlaceholder(String text) {
  final clean = text.trim().toLowerCase();
  if (clean.isEmpty) return false;
  if (clean.length < 3) return true;

  if (RegExp(r'^(dad|ada|test|asdf|xxx|qwerty|lorem)').hasMatch(clean)) {
    return true;
  }

  final letters = clean.replaceAll(RegExp(r'[^a-záàâãéêíóôõúç]'), '');
  if (letters.length >= 6) {
    final unique = letters.split('').toSet().length;
    if (unique <= 3) return true;
  }

  return false;
}

List<String> landingContentWarnings({
  required List<({String pergunta, String resposta})> faq,
  required String primaryCta,
  required String heroTitle,
}) {
  final warnings = <String>[];

  if (landingTextLooksLikePlaceholder(heroTitle)) {
    warnings.add('Título principal parece incompleto ou genérico.');
  }

  if (primaryCta.toLowerCase().contains('avaliacao') &&
      !primaryCta.toLowerCase().contains('avaliação')) {
    warnings.add('Botão principal: prefira "avaliação" com acento.');
  }

  for (var i = 0; i < faq.length; i++) {
    final p = faq[i].pergunta.trim();
    final r = faq[i].resposta.trim();
    if (p.isEmpty && r.isEmpty) continue;
    if (landingTextLooksLikePlaceholder(p) || landingTextLooksLikePlaceholder(r)) {
      warnings.add('Pergunta ${i + 1} parece texto de teste — revise antes de publicar.');
    }
  }

  return warnings;
}
