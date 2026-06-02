import '../../planos/data/planos_repository.dart';
import '../../planos/utils/plano_capability.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/plan_entitlements.dart';

/// Atalho do grid «Mais ferramentas» — capability alinhada ao [FeatureGate] da rota.
class DashboardToolShortcut {
  const DashboardToolShortcut({
    required this.icon,
    required this.label,
    this.route,
    this.capability,
    this.featureName,
    this.landingEditor = false,
  });

  final String icon;
  final String label;
  final String? route;
  final String? capability;
  final String? featureName;
  final bool landingEditor;

  String get displayFeatureName => featureName ?? label;

  bool isUnlocked(PlanoFeatures features) {
    if (capability == null) return true;
    return PlanoCapability.has(features, capability!);
  }

  SubscriptionPlan targetPlan() => PlanEntitlements.targetPlan(
    capability: capability,
    fallback: SubscriptionPlan.PREMIUM,
  );

  String tierBadgeLabel() {
    return switch (targetPlan()) {
      SubscriptionPlan.ENTERPRISE_PRO => 'Pro',
      SubscriptionPlan.ENTERPRISE => 'Enterprise',
      SubscriptionPlan.PREMIUM => 'Premium',
      _ => 'Premium',
    };
  }

  static const List<DashboardToolShortcut> moreTools = [
    DashboardToolShortcut(icon: 'dumbbell', label: 'Exercícios', route: '/exercicios'),
    DashboardToolShortcut(icon: 'article', label: 'Feed', route: '/feed'),
    DashboardToolShortcut(
      icon: 'trend',
      label: 'Leads',
      route: '/leads',
      capability: 'financeiro',
      featureName: 'CRM e Leads',
    ),
    DashboardToolShortcut(icon: 'home', label: 'Indique', route: '/referral'),
    DashboardToolShortcut(icon: 'spark', label: 'Ofertas', route: '/ofertas-upsell'),
    DashboardToolShortcut(
      icon: 'flame',
      label: 'Hábitos',
      route: '/habitos',
      capability: 'habitCoaching',
    ),
    DashboardToolShortcut(
      icon: 'zap',
      label: 'Automações',
      route: '/automacoes',
      capability: 'automacoes',
    ),
    DashboardToolShortcut(
      icon: 'plus',
      label: 'Desafios',
      route: '/desafios',
      capability: 'comunidadeGrupos',
      featureName: 'Desafios e ranking',
    ),
    DashboardToolShortcut(
      icon: 'coin',
      label: 'Loja',
      route: '/loja',
      capability: 'lojaDigital',
      featureName: 'Loja digital',
    ),
    DashboardToolShortcut(
      icon: 'users',
      label: 'Equipe',
      route: '/perfil/equipe',
      capability: 'equipeRbac',
      featureName: 'Equipe e RBAC',
    ),
    DashboardToolShortcut(icon: 'coin', label: 'Pacotes', route: '/pacotes'),
    DashboardToolShortcut(
      icon: 'message-circle',
      label: 'Lead Público',
      route: '/leads-publicos',
      capability: 'financeiro',
      featureName: 'Captura de leads',
    ),
    DashboardToolShortcut(
      icon: 'dollar-sign',
      label: 'Receita recorrente',
      route: '/relatorio/business',
      capability: 'relatorios',
      featureName: 'Relatórios de negócio',
    ),
    DashboardToolShortcut(
      icon: 'alert-triangle',
      label: 'Cobrança auto',
      route: '/dunning',
      capability: 'financeiro',
      featureName: 'Cobrança automática',
    ),
    DashboardToolShortcut(
      icon: 'route',
      label: 'Recuperação',
      route: '/winback',
      capability: 'automacoes',
      featureName: 'Automação win-back',
    ),
    DashboardToolShortcut(
      icon: 'sun',
      label: 'Landing',
      landingEditor: true,
      capability: 'landingCompleta',
      featureName: 'Landing page completa',
    ),
    DashboardToolShortcut(
      icon: 'calendar',
      label: 'Recorrência',
      route: '/recorrencia',
      capability: 'financeiro',
      featureName: 'Recorrência de alunos',
    ),
    DashboardToolShortcut(icon: 'star', label: 'Pesquisa NPS', route: '/nps'),
    DashboardToolShortcut(
      icon: 'chat',
      label: 'Grupo',
      route: '/grupo-aulas',
      capability: 'comunidadeGrupos',
      featureName: 'Turmas em grupo',
    ),
    DashboardToolShortcut(
      icon: 'arrow-left',
      label: 'Configuração inicial',
      route: '/onboarding/wizard',
    ),
    DashboardToolShortcut(icon: 'circle-check', label: 'Qualidade', route: '/dashboard/qualidade'),
    DashboardToolShortcut(icon: 'bell', label: 'Broadcasts', route: '/broadcasts'),
  ];

  static const List<DashboardToolShortcut> roiQuickLinks = [
    DashboardToolShortcut(icon: 'coin', label: 'Pacotes', route: '/pacotes'),
    DashboardToolShortcut(
      icon: 'message-circle',
      label: 'Captura pública',
      route: '/leads-publicos',
      capability: 'financeiro',
      featureName: 'Captura pública',
    ),
    DashboardToolShortcut(
      icon: 'moon',
      label: 'Marca própria',
      route: '/white-label',
      capability: 'whiteLabel',
      featureName: 'Identidade visual e marca própria',
    ),
    DashboardToolShortcut(
      icon: 'dollar-sign',
      label: 'Preços inteligentes',
      route: '/financeiro',
      capability: 'financeiro',
      featureName: 'Financeiro',
    ),
    DashboardToolShortcut(
      icon: 'article',
      label: 'Landing',
      landingEditor: true,
      capability: 'landingCompleta',
      featureName: 'Landing page completa',
    ),
  ];
}
