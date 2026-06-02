import '../../assinatura/data/plano.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/plan_entitlements.dart';
import '../data/planos_repository.dart';

/// Grupos colapsáveis de features por card de plano (paridade HTML).
class PaywallPlanFeatureSection {
  final String title;
  final List<PaywallPlanFeatureItem> items;
  final bool collapsible;
  final bool initiallyExpanded;

  const PaywallPlanFeatureSection({
    required this.title,
    required this.items,
    this.collapsible = false,
    this.initiallyExpanded = false,
  });
}

class PaywallPlanFeatureItem {
  final String label;
  final bool included;
  final bool highlight;
  final bool comingSoon;
  final String? capability;
  final SubscriptionPlan? upgradePlan;

  const PaywallPlanFeatureItem({
    required this.label,
    this.included = true,
    this.highlight = false,
    this.comingSoon = false,
    this.capability,
    this.upgradePlan,
  });
}

class PaywallPlanSections {
  PaywallPlanSections._();

  static List<PaywallPlanFeatureSection> forPlan(Plano plano, SubscriptionPlan plan) {
    final raw = switch (plan) {
      SubscriptionPlan.FREE => _free(plano),
      SubscriptionPlan.PREMIUM => _premium(plano),
      SubscriptionPlan.ENTERPRISE => _enterprise(plano),
      SubscriptionPlan.ENTERPRISE_PRO => _enterprisePro(plano),
    };
    return _PaywallPlanInclusion.applyCanonical(raw, plan, plano);
  }

  static String _alunosLabel(Plano plano) {
    final n = plano.limiteAlunos;
    if (n == null) return 'Alunos ILIMITADOS';
    if (n <= 5) return '$n alunos ativos';
    return '$n alunos ativos';
  }

  static List<PaywallPlanFeatureSection> _free(Plano plano) => [
    PaywallPlanFeatureSection(
      title: 'Alunos & Treinos',
      items: [
        PaywallPlanFeatureItem(label: _alunosLabel(plano), highlight: true),
        const PaywallPlanFeatureItem(label: 'Treinos + check-in + biblioteca 190+'),
        const PaywallPlanFeatureItem(label: 'Agenda básica'),
        const PaywallPlanFeatureItem(label: 'Focux Score™ (visualização)'),
      ],
    ),
    const PaywallPlanFeatureSection(
      title: 'Bloqueado no FREE',
      collapsible: true,
      items: [
        PaywallPlanFeatureItem(label: 'PIX com QR Code + cobrança no chat', included: false),
        PaywallPlanFeatureItem(label: 'CRM de leads + landing page', included: false),
        PaywallPlanFeatureItem(label: 'IA Copiloto', included: false),
        PaywallPlanFeatureItem(label: 'Alertas de risco & churn', included: false),
        PaywallPlanFeatureItem(label: 'Recovery Score + relógio', included: false),
      ],
    ),
  ];

  static List<PaywallPlanFeatureSection> _premium(Plano plano) => [
    PaywallPlanFeatureSection(
      title: 'Alunos & Treinos',
      items: [
        PaywallPlanFeatureItem(label: _alunosLabel(plano), highlight: true),
        const PaywallPlanFeatureItem(label: 'Treinos + check-in + biblioteca 190+'),
        const PaywallPlanFeatureItem(label: 'Agenda completa + lembretes automáticos'),
        const PaywallPlanFeatureItem(
          label: 'Focux Score™ + alertas de risco',
          highlight: true,
        ),
        const PaywallPlanFeatureItem(
          label: 'Recovery Score + Apple/Google/Garmin',
          highlight: true,
        ),
        const PaywallPlanFeatureItem(label: 'Form Check de vídeo'),
      ],
    ),
    PaywallPlanFeatureSection(
      title: 'Financeiro & Crescimento',
      collapsible: true,
      items: [
        PaywallPlanFeatureItem(
          label: 'PIX com QR Code + cobrança no chat',
          included: plano.temFinanceiro,
          highlight: true,
        ),
        PaywallPlanFeatureItem(
          label: 'Financeiro + dashboard + inadimplência',
          included: plano.temFinanceiro,
        ),
        const PaywallPlanFeatureItem(label: 'CRM de leads'),
        const PaywallPlanFeatureItem(label: 'Chat, feed e broadcasts'),
        const PaywallPlanFeatureItem(
          label: 'Habit coaching diário ✦',
        ),
        const PaywallPlanFeatureItem(
          label: 'Comunidade privada de alunos ✦',
        ),
      ],
    ),
    PaywallPlanFeatureSection(
      title: 'IA & Retenção',
      collapsible: true,
      items: [
        const PaywallPlanFeatureItem(
          label: 'IA Copiloto — 120 interações/mês',
          highlight: true,
        ),
        const PaywallPlanFeatureItem(label: 'Progressão de carga automática'),
        const PaywallPlanFeatureItem(
          label: 'Command Center + fila do dia',
          highlight: true,
        ),
        const PaywallPlanFeatureItem(label: 'Gamificação, ranking e badges'),
        const PaywallPlanFeatureItem(label: 'Referral + programa de indicação'),
      ],
    ),
    const PaywallPlanFeatureSection(
      title: 'No Enterprise',
      collapsible: true,
      items: [
        PaywallPlanFeatureItem(
          label: 'White-label — seu logo e suas cores',
          included: false,
          capability: 'whiteLabel',
        ),
        PaywallPlanFeatureItem(
          label: 'Automações sequenciais ✦',
          included: false,
          capability: 'automacoes',
        ),
        PaywallPlanFeatureItem(
          label: 'Equipe / RBAC (assistente) ✦',
          included: false,
          capability: 'equipeRbac',
        ),
        PaywallPlanFeatureItem(
          label: 'Comunidade + grupos ✦',
          included: false,
          capability: 'comunidadeGrupos',
        ),
      ],
    ),
  ];

  static List<PaywallPlanFeatureSection> _enterprise(Plano plano) => [
    PaywallPlanFeatureSection(
      title: 'Alunos & Treinos',
      items: [
        const PaywallPlanFeatureItem(label: 'Alunos ILIMITADOS', highlight: true),
        const PaywallPlanFeatureItem(label: 'Treinos + check-in + biblioteca 190+'),
        const PaywallPlanFeatureItem(label: 'Agenda completa + lembretes automáticos'),
        const PaywallPlanFeatureItem(
          label: 'Focux Score™ + motor de retenção IA',
          highlight: true,
        ),
        const PaywallPlanFeatureItem(
          label: 'Recovery Score + Apple/Google/Garmin',
          highlight: true,
        ),
        const PaywallPlanFeatureItem(label: 'Form Check de vídeo'),
      ],
    ),
    PaywallPlanFeatureSection(
      title: 'Financeiro & Crescimento',
      collapsible: true,
      items: [
        PaywallPlanFeatureItem(
          label: 'PIX com QR Code + cobrança no chat',
          included: plano.temFinanceiro,
          highlight: true,
        ),
        PaywallPlanFeatureItem(
          label: 'Financeiro + dashboard + inadimplência',
          included: plano.temFinanceiro,
        ),
        const PaywallPlanFeatureItem(label: 'CRM de leads'),
        PaywallPlanFeatureItem(
          label: 'White-label — seu logo e suas cores',
          included: plano.temWhiteLabel,
          highlight: true,
        ),
        const PaywallPlanFeatureItem(label: 'Domínio customizado'),
        const PaywallPlanFeatureItem(label: 'NFS-e automática (para PJ)'),
        const PaywallPlanFeatureItem(
          label: 'Automações sequenciais ✦',
        ),
      ],
    ),
    const PaywallPlanFeatureSection(
      title: 'Landing page · Enterprise Pro',
      collapsible: true,
      initiallyExpanded: false,
      items: [
        PaywallPlanFeatureItem(
          label: 'Editor completo — depoimentos, galeria e FAQ',
          included: false,
          capability: 'landingCompleta',
        ),
        PaywallPlanFeatureItem(
          label: 'Formulário Meta e link focux.app/p/seunome',
          included: false,
          capability: 'landingCompleta',
        ),
        PaywallPlanFeatureItem(
          label: 'Domínio customizado na landing',
          included: false,
          capability: 'landingCompleta',
        ),
      ],
    ),
    const PaywallPlanFeatureSection(
      title: 'Loja · Enterprise Pro',
      collapsible: true,
      initiallyExpanded: false,
      items: [
        PaywallPlanFeatureItem(
          label: 'Venda treinos avulsos e desafios',
          included: false,
          highlight: true,
          capability: 'lojaDigital',
        ),
        PaywallPlanFeatureItem(
          label: '"Desafio 30 dias" como produto digital',
          included: false,
          highlight: true,
          capability: 'lojaDigital',
        ),
        PaywallPlanFeatureItem(
          label: 'Checkout integrado com PIX',
          included: false,
          capability: 'lojaDigital',
        ),
        PaywallPlanFeatureItem(
          label: 'Receita passiva sem hora extra',
          included: false,
          highlight: true,
          capability: 'lojaDigital',
        ),
      ],
    ),
    PaywallPlanFeatureSection(
      title: 'IA & Retenção',
      collapsible: true,
      items: [
        const PaywallPlanFeatureItem(
          label: 'IA Copiloto — 400 interações/mês+',
          highlight: true,
        ),
        const PaywallPlanFeatureItem(label: 'Progressão de carga automática'),
        const PaywallPlanFeatureItem(
          label: 'Command Center + fila do dia',
          highlight: true,
        ),
        const PaywallPlanFeatureItem(label: 'Gamificação, ranking e badges'),
        const PaywallPlanFeatureItem(
          label: 'Habit coaching diário ✦',
        ),
        const PaywallPlanFeatureItem(
          label: 'Equipe / RBAC (assistente) ✦',
        ),
        const PaywallPlanFeatureItem(
          label: 'Comunidade + grupos ✦',
        ),
        const PaywallPlanFeatureItem(
          label: 'Pose Coach — análise ML ✦',
          included: false,
          capability: 'poseCoach',
        ),
      ],
    ),
  ];

  static List<PaywallPlanFeatureSection> _enterprisePro(Plano plano) => [
    const PaywallPlanFeatureSection(
      title: 'Tudo do Enterprise +',
      items: [
        PaywallPlanFeatureItem(label: 'Alunos ILIMITADOS', highlight: true),
        PaywallPlanFeatureItem(
          label: 'White-label completo — logo + cores',
          highlight: true,
        ),
        PaywallPlanFeatureItem(
          label: 'IA Copiloto — 400+/mês contexto avançado',
          highlight: true,
        ),
        PaywallPlanFeatureItem(
          label: 'Automações sequenciais avançadas ✦',
        ),
        PaywallPlanFeatureItem(
          label: 'Equipe / RBAC ilimitado ✦',
        ),
        PaywallPlanFeatureItem(
          label: 'Pose Coach — análise de postura ML ✦',
          capability: 'poseCoach',
        ),
      ],
    ),
    PaywallPlanFeatureSection(
      title: 'Landing Page COMPLETA',
      collapsible: true,
      items: [
        PaywallPlanFeatureItem(
          label: 'Depoimentos + galeria + FAQ ilimitados',
          included: plano.temLandingCompleta,
          highlight: true,
        ),
        PaywallPlanFeatureItem(
          label: 'Formulário rápido para anúncios (Meta)',
          included: plano.temLandingCompleta,
          highlight: true,
        ),
        PaywallPlanFeatureItem(
          label: 'focux.app/p/seunome 100% personalizada',
          included: plano.temLandingCompleta,
        ),
        const PaywallPlanFeatureItem(label: 'Domínio customizado + SEO'),
        const PaywallPlanFeatureItem(label: '50 fotos de migração/mês'),
      ],
    ),
    const PaywallPlanFeatureSection(
      title: 'Loja de Programas Digitais ✦',
      collapsible: true,
      items: [
        PaywallPlanFeatureItem(
          label: 'Venda treinos avulsos e desafios',
          highlight: true,
          capability: 'lojaDigital',
        ),
        PaywallPlanFeatureItem(
          label: '"Desafio 30 dias" como produto digital',
          highlight: true,
          capability: 'lojaDigital',
        ),
        PaywallPlanFeatureItem(
          label: 'Checkout integrado com PIX',
          capability: 'lojaDigital',
        ),
        PaywallPlanFeatureItem(
          label: 'Receita passiva sem hora extra',
          highlight: true,
          capability: 'lojaDigital',
        ),
      ],
    ),
  ];
}

/// Aplica a matriz canônica de tier às linhas da vitrine (paridade com [PlanoFeatures.normalizeForTier]).
class _PaywallPlanInclusion {
  _PaywallPlanInclusion._();

  static List<PaywallPlanFeatureSection> applyCanonical(
    List<PaywallPlanFeatureSection> sections,
    SubscriptionPlan cardPlan,
    Plano vitrinePlano,
  ) {
    final caps = PlanoFeatures.canonicalCapabilitiesFor(cardPlan);
    return [
      for (final section in sections)
        PaywallPlanFeatureSection(
          title: section.title,
          collapsible: section.collapsible,
          initiallyExpanded: section.initiallyExpanded,
          items: [
            for (final item in section.items)
              _patchItem(
                item,
                sectionTitle: section.title,
                caps: caps,
                vitrinePlano: vitrinePlano,
              ),
          ],
        ),
    ];
  }

  static PaywallPlanFeatureItem _patchItem(
    PaywallPlanFeatureItem item, {
    required String sectionTitle,
    required Map<String, bool> caps,
    required Plano vitrinePlano,
  }) {
    final capability = item.capability ?? _inferCapability(sectionTitle, item.label);
    final included = _resolveIncluded(
      item: item,
      sectionTitle: sectionTitle,
      caps: caps,
      vitrinePlano: vitrinePlano,
      capability: capability,
    );
    final upgradePlan = !included
        ? (item.upgradePlan ??
            (capability != null
                ? PlanEntitlements.targetPlan(capability: capability)
                : _defaultUpgradeForSection(sectionTitle)))
        : null;

    return PaywallPlanFeatureItem(
      label: item.label,
      included: included,
      highlight: item.highlight,
      comingSoon: item.comingSoon,
      capability: capability,
      upgradePlan: upgradePlan,
    );
  }

  static bool _resolveIncluded({
    required PaywallPlanFeatureItem item,
    required String sectionTitle,
    required Map<String, bool> caps,
    required Plano vitrinePlano,
    required String? capability,
  }) {
    final sectionLower = sectionTitle.toLowerCase();
    if (sectionLower.contains('bloqueado no free')) return false;

    if (sectionLower.contains('landing')) {
      return caps['landingCompleta'] ?? false;
    }
    if (sectionLower.contains('loja')) {
      return caps['lojaDigital'] ?? false;
    }

    if (capability != null && caps.containsKey(capability)) {
      return caps[capability]!;
    }

    if (item.label.toLowerCase().contains('white-label')) {
      return caps['whiteLabel']! && vitrinePlano.temWhiteLabel;
    }
    if (item.label.contains('PIX') ||
        item.label.contains('Financeiro + dashboard')) {
      return caps['financeiro']! && vitrinePlano.temFinanceiro;
    }

    return item.included;
  }

  static String? _inferCapability(String sectionTitle, String label) {
    final lower = label.toLowerCase();
    final sectionLower = sectionTitle.toLowerCase();

    if (sectionLower.contains('landing')) return 'landingCompleta';
    if (sectionLower.contains('loja')) return 'lojaDigital';
    if (lower.contains('pose coach')) return 'poseCoach';
    if (lower.contains('white-label')) return 'whiteLabel';
    if (lower.contains('automações sequenciais avançadas')) {
      return 'automacoesAvancadas';
    }
    if (lower.contains('automações sequenciais')) return 'automacoes';
    if (lower.contains('equipe / rbac')) return 'equipeRbac';
    if (lower.contains('comunidade + grupos')) return 'comunidadeGrupos';
    if (lower.contains('comunidade privada')) return 'comunidadePrivada';
    if (lower.contains('habit coaching')) return 'habitCoaching';
    if (label.contains('PIX') || label.contains('Financeiro + dashboard')) {
      return 'financeiro';
    }
    return null;
  }

  static SubscriptionPlan _defaultUpgradeForSection(String sectionTitle) {
    final s = sectionTitle.toLowerCase();
    if (s.contains('enterprise pro') || s.contains('loja') || s.contains('landing')) {
      return SubscriptionPlan.ENTERPRISE_PRO;
    }
    return SubscriptionPlan.PREMIUM;
  }
}
