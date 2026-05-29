/// Labels amigáveis e destinos do checklist de vendas da landing.
library;

const landingChecklistFriendlyLabels = <String, String>{
  'slug': 'Link público configurado',
  'marca': 'Logo ou cor da marca',
  'cref': 'CREF informado no perfil',
  'hero': 'Título de abertura preenchido',
  'cta': 'Texto do botão principal definido',
  'captura': 'Formulário rápido disponível',
  'servicos': 'Serviços ou dúvidas frequentes',
  'pacotes': 'Planos publicados na vitrine',
};

const landingChecklistActionHints = <String, String>{
  'slug': 'Abrir configurações de link',
  'marca': 'Ir para fotos e identidade visual',
  'cref': 'Aparece no hero e na bio — editar perfil',
  'hero': 'Ir para abertura da página',
  'cta': 'Ir para o botão principal',
  'captura': 'Ver link do formulário rápido',
  'servicos': 'Ir para serviços e FAQ',
  'pacotes': 'Abrir vitrine de planos',
};

String landingChecklistLabel(String id, String fallback) =>
    landingChecklistFriendlyLabels[id] ?? fallback;

String landingChecklistHint(String id) =>
    landingChecklistActionHints[id] ?? 'Toque para ir ao campo';

/// Destino ao tocar em um item do checklist.
enum LandingChecklistTarget {
  linksTab,
  conteudoHero,
  conteudoServicos,
  conteudoFaq,
  identidadeVisual,
  editProfile,
  whiteLabel,
  pacotes,
}

LandingChecklistTarget? landingChecklistTarget(String id) {
  return switch (id) {
    'slug' => LandingChecklistTarget.whiteLabel,
    'marca' => LandingChecklistTarget.identidadeVisual,
    'cref' => LandingChecklistTarget.editProfile,
    'hero' => LandingChecklistTarget.conteudoHero,
    'cta' => LandingChecklistTarget.conteudoHero,
    'captura' => LandingChecklistTarget.linksTab,
    'servicos' => LandingChecklistTarget.conteudoServicos,
    'pacotes' => LandingChecklistTarget.pacotes,
    _ => null,
  };
}
