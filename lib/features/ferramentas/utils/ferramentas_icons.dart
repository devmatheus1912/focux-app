import 'package:flutter/widgets.dart';

import '../../../core/theme/fx_icons.dart';
import '../data/ferramentas_catalogo_models.dart';

/// Deep link helper: `/ferramentas/hub/:id?aba=`
String ferramentasHubLocation(String itemId, {String? abaId}) {
  final base = '/ferramentas/hub/${Uri.encodeComponent(itemId)}';
  if (abaId == null || abaId.isEmpty) return base;
  return '$base?aba=${Uri.encodeQueryComponent(abaId)}';
}

/// Ícones FxIcon por rota/legacy — pele, não lista de ferramentas.
IconData ferramentasIconFor(CatalogoEntrada entrada) {
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
  return FxIcons.ia;
}

/// Ícone pelo significado da ferramenta (não pelo desenho que "parecia").
const _byKey = <String, IconData>{
  'exercicios': FxIcons.treino,
  '/exercicios': FxIcons.treino,
  'feed': FxIcons.feed,
  '/feed': FxIcons.feed,
  'habitos': FxIcons.habito,
  '/habitos': FxIcons.habito,
  'desafios': FxIcons.trofeu,
  '/desafios': FxIcons.trofeu,
  'leads': FxIcons.megafone,
  '/leads': FxIcons.megafone,
  'indique': FxIcons.presente,
  'referral': FxIcons.presente,
  '/referral': FxIcons.presente,
  'lead-publico': FxIcons.megafone,
  'lead_publico': FxIcons.megafone,
  'leads-publicos': FxIcons.megafone,
  '/leads-publicos': FxIcons.megafone,
  'captacao': FxIcons.megafone,
  'captação': FxIcons.megafone,
  'recuperacao': FxIcons.historico,
  'winback': FxIcons.historico,
  '/winback': FxIcons.historico,
  'landing': FxIcons.site,
  '/perfil/landing-editor': FxIcons.site,
  'nps': FxIcons.estrela,
  '/nps': FxIcons.estrela,
  'ofertas': FxIcons.oferta,
  '/ofertas-upsell': FxIcons.oferta,
  'pacotes': FxIcons.etiqueta,
  '/pacotes': FxIcons.etiqueta,
  'loja': FxIcons.loja,
  '/loja': FxIcons.loja,
  'vendas': FxIcons.loja,
  'receita-recorrente': FxIcons.grafico,
  'receita_recorrente': FxIcons.grafico,
  '/relatorio/business': FxIcons.grafico,
  'cobranca-auto': FxIcons.alerta,
  'cobranca_auto': FxIcons.alerta,
  '/dunning': FxIcons.alerta,
  'recorrencia': FxIcons.repetir,
  '/recorrencia': FxIcons.repetir,
  'financeiro': FxIcons.pagamento,
  'marca-propria': FxIcons.paleta,
  'white-label': FxIcons.paleta,
  '/white-label': FxIcons.paleta,
  'automacoes': FxIcons.raio,
  '/automacoes': FxIcons.raio,
  'equipe': FxIcons.grupo,
  '/perfil/equipe': FxIcons.grupo,
  'grupo': FxIcons.conversas,
  '/grupo-aulas': FxIcons.conversas,
  'configuracao-inicial': FxIcons.checklist,
  'onboarding': FxIcons.checklist,
  '/onboarding/wizard': FxIcons.checklist,
  'qualidade': FxIcons.verificado,
  '/dashboard/qualidade': FxIcons.verificado,
  'broadcasts': FxIcons.megafone,
  '/broadcasts': FxIcons.megafone,
  'operacao': FxIcons.treino,
  'retenção': FxIcons.alerta,
  'retencao': FxIcons.alerta,
  'engajamento': FxIcons.fogo,
  'studio': FxIcons.paleta,
  'conta': FxIcons.pessoa,
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
    case '/financeiro/cobranca-auto':
      return '/financeiro?aba=mensalidades&filtro=atrasadas';
    case '/financeiro/recorrencia':
      return '/financeiro?aba=recorrencias';
    case '/financeiro/receita':
      return '/relatorio/business';
    case '/retencao/recuperacao':
    case '/retencao/saude':
      return '/retencao';
    case '/retencao/nps':
      return '/nps';
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
