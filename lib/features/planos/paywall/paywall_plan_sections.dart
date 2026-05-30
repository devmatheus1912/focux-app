import '../../assinatura/data/plano.dart';
import '../../subscription/models/subscription_plan.dart';

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

  const PaywallPlanFeatureItem({
    required this.label,
    this.included = true,
    this.highlight = false,
    this.comingSoon = false,
  });
}

class PaywallPlanSections {
  PaywallPlanSections._();

  static List<PaywallPlanFeatureSection> forPlan(Plano plano, SubscriptionPlan plan) =>
      switch (plan) {
        SubscriptionPlan.FREE => _free(plano),
        SubscriptionPlan.PREMIUM => _premium(plano),
        SubscriptionPlan.ENTERPRISE => _enterprise(plano),
        SubscriptionPlan.ENTERPRISE_PRO => _enterprisePro(plano),
      };

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
      items: [
        PaywallPlanFeatureItem(
          label: 'Editor completo — depoimentos, galeria e FAQ',
          included: false,
        ),
        PaywallPlanFeatureItem(
          label: 'Formulário Meta e link focux.app/p/seunome',
          included: false,
        ),
        PaywallPlanFeatureItem(
          label: 'Domínio customizado na landing',
          included: false,
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
        ),
        PaywallPlanFeatureItem(
          label: '"Desafio 30 dias" como produto digital',
          highlight: true,
        ),
        PaywallPlanFeatureItem(
          label: 'Checkout integrado com PIX',
        ),
        PaywallPlanFeatureItem(
          label: 'Receita passiva sem hora extra',
          highlight: true,
        ),
      ],
    ),
  ];
}
