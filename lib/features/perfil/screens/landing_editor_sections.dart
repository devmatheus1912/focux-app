/// Normalização de chaves legadas da landing → labels e ordem canônica.
library;

const landingEditorCanonicalSections = [
  'bio',
  'servicos',
  'processo',
  'pacotes',
  'depoimentos',
  'galeria',
  'faq',
  'contato',
];

const landingEditorSectionLabels = <String, String>{
  'hero': 'Abertura',
  'bio': 'Sobre você',
  'sobre': 'Sobre você',
  'servicos': 'Serviços',
  'serviços': 'Serviços',
  'processo': 'Como funciona',
  'metodo': 'Como funciona',
  'método': 'Como funciona',
  'pacotes': 'Planos e preços',
  'ofertas': 'Planos e preços',
  'depoimentos': 'Depoimentos',
  'prova': 'Depoimentos',
  'galeria': 'Galeria',
  'faq': 'Dúvidas frequentes',
  'contato': 'Contato',
  'especialidades': 'Especialidades',
  'app': 'App para alunos',
  'cta': 'Chamada final',
};

const _legacyToCanonical = <String, String>{
  'sobre': 'bio',
  'bio': 'bio',
  'servicos': 'servicos',
  'serviços': 'servicos',
  'processo': 'processo',
  'metodo': 'processo',
  'método': 'processo',
  'ofertas': 'pacotes',
  'pacotes': 'pacotes',
  'prova': 'depoimentos',
  'depoimentos': 'depoimentos',
  'galeria': 'galeria',
  'faq': 'faq',
  'contato': 'contato',
  'especialidades': 'servicos',
  'app': 'contato',
  'cta': 'contato',
  'hero': 'hero',
};

String normalizeLandingSectionKey(String raw) {
  final key = raw.trim().toLowerCase();
  return _legacyToCanonical[key] ?? key;
}

String landingSectionLabel(String key) {
  final normalized = normalizeLandingSectionKey(key);
  return landingEditorSectionLabels[normalized] ??
      landingEditorSectionLabels[key] ??
      _titleCase(key);
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

/// Ordem estável para o backend, deduplicada e com fallbacks.
List<String> normalizeLandingSectionOrder(List<String> raw) {
  final seen = <String>{};
  final result = <String>[];

  for (final item in raw) {
    final normalized = normalizeLandingSectionKey(item);
    if (normalized == 'hero') continue;
    if (seen.add(normalized)) {
      result.add(normalized);
    }
  }

  for (final fallback in landingEditorCanonicalSections) {
    if (seen.add(fallback)) {
      result.add(fallback);
    }
  }

  return result;
}

/// Seções editáveis na aba Conteúdo do editor.
enum LandingEditorContentSection { abertura, capa, botoes, servicos, faq }

String landingEditorContentSectionLabel(LandingEditorContentSection section) {
  return switch (section) {
    LandingEditorContentSection.abertura => 'Abertura',
    LandingEditorContentSection.capa => 'Capa',
    LandingEditorContentSection.botoes => 'Botões',
    LandingEditorContentSection.servicos => 'Serviços',
    LandingEditorContentSection.faq => 'FAQ',
  };
}
