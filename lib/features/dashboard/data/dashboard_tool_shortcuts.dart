import '../../planos/data/planos_repository.dart';
import '../../planos/utils/plano_capability.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/plan_entitlements.dart';

/// Bucket visual da Home «Mais ferramentas».
enum DashboardToolGroup {
  operacao('Operação'),
  receita('Receita'),
  crescimento('Crescimento'),
  sistema('Sistema');

  const DashboardToolGroup(this.title);
  final String title;
}

/// Atalho do grid «Mais ferramentas» — capability alinhada ao [FeatureGate] da rota.
class DashboardToolShortcut {
  const DashboardToolShortcut({
    required this.icon,
    required this.label,
    required this.group,
    this.route,
    this.capability,
    this.featureName,
    this.landingEditor = false,
  });

  final String icon;
  final String label;
  final DashboardToolGroup group;
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
    DashboardToolShortcut(
      icon: 'dumbbell',
      label: 'Exercícios',
      route: '/exercicios',
      group: DashboardToolGroup.operacao,
    ),
    DashboardToolShortcut(
      icon: 'article',
      label: 'Feed',
      route: '/feed',
      group: DashboardToolGroup.operacao,
    ),
    DashboardToolShortcut(
      icon: 'flame',
      label: 'Hábitos',
      route: '/habitos',
      capability: 'habitCoaching',
      group: DashboardToolGroup.operacao,
    ),
    DashboardToolShortcut(
      icon: 'plus',
      label: 'Desafios',
      route: '/desafios',
      capability: 'comunidadeGrupos',
      featureName: 'Desafios e ranking',
      group: DashboardToolGroup.operacao,
    ),
    DashboardToolShortcut(
      icon: 'trend',
      label: 'Leads',
      route: '/leads',
      capability: 'financeiro',
      featureName: 'CRM e Leads',
      group: DashboardToolGroup.crescimento,
    ),
    DashboardToolShortcut(
      icon: 'home',
      label: 'Indique',
      route: '/referral',
      group: DashboardToolGroup.crescimento,
    ),
    DashboardToolShortcut(
      icon: 'message-circle',
      label: 'Lead Público',
      route: '/leads-publicos',
      capability: 'financeiro',
      featureName: 'Captura de leads',
      group: DashboardToolGroup.crescimento,
    ),
    DashboardToolShortcut(
      icon: 'route',
      label: 'Recuperação',
      route: '/winback',
      capability: 'automacoes',
      featureName: 'Automação win-back',
      group: DashboardToolGroup.crescimento,
    ),
    DashboardToolShortcut(
      icon: 'sun',
      label: 'Landing',
      landingEditor: true,
      capability: 'landingCompleta',
      featureName: 'Landing page completa',
      group: DashboardToolGroup.crescimento,
    ),
    DashboardToolShortcut(
      icon: 'star',
      label: 'Pesquisa NPS',
      route: '/nps',
      group: DashboardToolGroup.crescimento,
    ),
    DashboardToolShortcut(
      icon: 'spark',
      label: 'Ofertas',
      route: '/ofertas-upsell',
      group: DashboardToolGroup.receita,
    ),
    DashboardToolShortcut(
      icon: 'coin',
      label: 'Pacotes',
      route: '/pacotes',
      group: DashboardToolGroup.receita,
    ),
    DashboardToolShortcut(
      icon: 'coin',
      label: 'Loja',
      route: '/loja',
      capability: 'lojaDigital',
      featureName: 'Loja digital',
      group: DashboardToolGroup.receita,
    ),
    DashboardToolShortcut(
      icon: 'dollar-sign',
      label: 'Preços',
      route: '/financeiro',
      capability: 'financeiro',
      featureName: 'Financeiro e preços',
      group: DashboardToolGroup.receita,
    ),
    DashboardToolShortcut(
      icon: 'dollar-sign',
      label: 'Receita recorrente',
      route: '/relatorio/business',
      capability: 'relatorios',
      featureName: 'Relatórios de negócio',
      group: DashboardToolGroup.receita,
    ),
    DashboardToolShortcut(
      icon: 'alert-triangle',
      label: 'Cobrança auto',
      route: '/dunning',
      capability: 'financeiro',
      featureName: 'Cobrança automática',
      group: DashboardToolGroup.receita,
    ),
    DashboardToolShortcut(
      icon: 'calendar',
      label: 'Recorrência',
      route: '/recorrencia',
      capability: 'financeiro',
      featureName: 'Recorrência de alunos',
      group: DashboardToolGroup.receita,
    ),
    DashboardToolShortcut(
      icon: 'moon',
      label: 'Marca própria',
      route: '/white-label',
      capability: 'whiteLabel',
      featureName: 'Identidade visual e marca própria',
      group: DashboardToolGroup.sistema,
    ),
    DashboardToolShortcut(
      icon: 'zap',
      label: 'Automações',
      route: '/automacoes',
      capability: 'automacoes',
      group: DashboardToolGroup.sistema,
    ),
    DashboardToolShortcut(
      icon: 'users',
      label: 'Equipe',
      route: '/perfil/equipe',
      capability: 'equipeRbac',
      featureName: 'Equipe e RBAC',
      group: DashboardToolGroup.sistema,
    ),
    DashboardToolShortcut(
      icon: 'chat',
      label: 'Grupo',
      route: '/grupo-aulas',
      capability: 'comunidadeGrupos',
      featureName: 'Turmas em grupo',
      group: DashboardToolGroup.sistema,
    ),
    DashboardToolShortcut(
      icon: 'arrow-left',
      label: 'Configuração inicial',
      route: '/onboarding/wizard',
      group: DashboardToolGroup.sistema,
    ),
    DashboardToolShortcut(
      icon: 'circle-check',
      label: 'Qualidade',
      route: '/dashboard/qualidade',
      group: DashboardToolGroup.sistema,
    ),
    DashboardToolShortcut(
      icon: 'bell',
      label: 'Broadcasts',
      route: '/broadcasts',
      group: DashboardToolGroup.sistema,
    ),
  ];
}
