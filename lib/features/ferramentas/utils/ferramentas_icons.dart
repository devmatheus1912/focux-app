import '../data/ferramentas_catalogo_models.dart';

/// Deep link helper: `/ferramentas/hub/:id?aba=`
String ferramentasHubLocation(String itemId, {String? abaId}) {
  final base = '/ferramentas/hub/${Uri.encodeComponent(itemId)}';
  if (abaId == null || abaId.isEmpty) return base;
  return '$base?aba=${Uri.encodeQueryComponent(abaId)}';
}

/// Ícones FxIcon por rota/legacy — pele, não lista de ferramentas.
String ferramentasIconFor(CatalogoEntrada entrada) {
  final keys = <String>[
    entrada.id.toLowerCase(),
    ...entrada.legacyIds.map((e) => e.toLowerCase()),
    (entrada.rotaApp ?? '').toLowerCase(),
    entrada.titulo.toLowerCase(),
  ];

  for (final key in keys) {
    final mapped = _byKey[key];
    if (mapped != null) return mapped;
  }
  for (final key in keys) {
    for (final entry in _byKey.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }
  }
  return 'spark';
}

const _byKey = <String, String>{
  'exercicios': 'dumbbell',
  '/exercicios': 'dumbbell',
  'feed': 'article',
  '/feed': 'article',
  'habitos': 'flame',
  '/habitos': 'flame',
  'desafios': 'plus',
  '/desafios': 'plus',
  'leads': 'trend',
  '/leads': 'trend',
  'indique': 'home',
  'referral': 'home',
  '/referral': 'home',
  'lead-publico': 'message-circle',
  'lead_publico': 'message-circle',
  'leads-publicos': 'message-circle',
  '/leads-publicos': 'message-circle',
  'captacao': 'message-circle',
  'captação': 'message-circle',
  'recuperacao': 'route',
  'winback': 'route',
  '/winback': 'route',
  'landing': 'sun',
  '/perfil/landing-editor': 'sun',
  'nps': 'star',
  '/nps': 'star',
  'ofertas': 'spark',
  '/ofertas-upsell': 'spark',
  'pacotes': 'coin',
  '/pacotes': 'coin',
  'loja': 'pix',
  '/loja': 'pix',
  'vendas': 'coin',
  'receita-recorrente': 'trend',
  'receita_recorrente': 'trend',
  '/relatorio/business': 'trend',
  'cobranca-auto': 'alert-triangle',
  'cobranca_auto': 'alert-triangle',
  '/dunning': 'alert-triangle',
  'recorrencia': 'calendar',
  '/recorrencia': 'calendar',
  'financeiro': 'coin',
  'marca-propria': 'moon',
  'white-label': 'moon',
  '/white-label': 'moon',
  'automacoes': 'zap',
  '/automacoes': 'zap',
  'equipe': 'users',
  '/perfil/equipe': 'users',
  'grupo': 'chat',
  '/grupo-aulas': 'chat',
  'configuracao-inicial': 'arrow-left',
  'onboarding': 'arrow-left',
  '/onboarding/wizard': 'arrow-left',
  'qualidade': 'circle-check',
  '/dashboard/qualidade': 'circle-check',
  'broadcasts': 'bell',
  '/broadcasts': 'bell',
  'operacao': 'dumbbell',
  'retenção': 'route',
  'retencao': 'route',
  'engajamento': 'flame',
  'studio': 'moon',
  'conta': 'users',
};

/// Normaliza `rotaApp` do BFF para path GoRouter.
String? normalizeFerramentasRotaApp(String? rotaApp) {
  if (rotaApp == null) return null;
  var path = rotaApp.trim();
  if (path.isEmpty) return null;
  if (!path.startsWith('/')) path = '/$path';
  switch (path) {
    case '/landing':
    case '/landing-editor':
    case '/perfil/landing':
      return '/perfil/landing-editor';
    case '/lead-publico':
    case '/captura':
      return '/leads-publicos';
    case '/receita-recorrente':
    case '/business-reports':
      return '/relatorio/business';
    case '/cobranca-auto':
    case '/cobranca':
      return '/dunning';
    case '/marca-propria':
      return '/white-label';
    case '/indique':
      return '/referral';
    case '/configuracao-inicial':
    case '/onboarding':
      return '/onboarding/wizard';
    default:
      return path;
  }
}
