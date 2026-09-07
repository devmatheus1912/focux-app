import '../../ferramentas/data/ferramentas_catalogo_models.dart';
import '../../ferramentas/utils/ferramentas_icons.dart';
import '../../ferramentas/utils/ferramentas_gates.dart';
import '../../planos/data/planos_repository.dart';
import '../../planos/utils/plano_capability.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/plan_entitlements.dart';

/// Atalho derivado do BFF de catálogo (não lista flat hardcoded).
class DashboardToolShortcut {
  const DashboardToolShortcut({
    required this.icon,
    required this.label,
    required this.entrada,
    this.route,
    this.capability,
    this.featureName,
    this.landingEditor = false,
    this.preferredAbaId,
  });

  final String icon;
  final String label;
  final CatalogoEntrada entrada;
  final String? route;
  final String? capability;
  final String? featureName;
  final bool landingEditor;
  final String? preferredAbaId;

  String get displayFeatureName => featureName ?? label;

  bool isUnlocked(PlanoFeatures features) {
    if (!entrada.unlocked) return false;
    if (capability == null) return true;
    return PlanoCapability.has(features, capability!);
  }

  SubscriptionPlan targetPlan() {
    if (entrada.upgradePlano != null && entrada.upgradePlano!.isNotEmpty) {
      return subscriptionPlanFromApi(entrada.upgradePlano);
    }
    return PlanEntitlements.targetPlan(
      capability: capability,
      fallback: SubscriptionPlan.PRO,
    );
  }

  String tierBadgeLabel() {
    return switch (targetPlan()) {
      SubscriptionPlan.ENTERPRISE => 'Enterprise',
      SubscriptionPlan.PRO => 'Pro',
      _ => 'Pro',
    };
  }

  factory DashboardToolShortcut.fromEntrada(
    CatalogoEntrada entrada, {
    String? preferredAbaId,
  }) {
    final capability = capabilityFromFeatureGate(entrada.featureGate);
    final route =
        entrada.isHubComAbas
            ? ferramentasHubLocation(entrada.id, abaId: preferredAbaId)
            : normalizeFerramentasRotaApp(entrada.rotaApp);
    return DashboardToolShortcut(
      icon: ferramentasIconFor(entrada),
      label: entrada.titulo,
      entrada: entrada,
      route: route,
      capability: capability,
      featureName: entrada.titulo,
      landingEditor: route == '/perfil/landing-editor',
      preferredAbaId: preferredAbaId,
    );
  }
}

/// Atalhos da home a partir de `atalhosHome` (+ destaqueHome), filtrando
/// Configuração inicial quando onboarding já está completo.
List<DashboardToolShortcut> atalhosHomeFromCatalogo(
  FerramentasCatalogo catalogo, {
  bool hideOnboardingWizard = false,
}) {
  final raw = catalogo.atalhosHome;
  final list =
      raw.isNotEmpty
          ? raw
          : [
            for (final hub in catalogo.hubs)
              for (final item in hub.itens)
                if (item.destaqueHome) item,
          ];

  return [
    for (final entrada in list)
      if (!(hideOnboardingWizard && _isOnboardingWizard(entrada)))
        DashboardToolShortcut.fromEntrada(entrada),
  ];
}

/// Folhas + portas de hub (itens com abas contam como 1).
List<DashboardToolShortcut> catalogLeavesFromHub(CatalogoHub hub) {
  return [
    for (final item in hub.itens) DashboardToolShortcut.fromEntrada(item),
  ];
}

bool _isOnboardingWizard(CatalogoEntrada e) {
  final route = normalizeFerramentasRotaApp(e.rotaApp);
  if (route == '/onboarding/wizard') return true;
  final keys = [e.id, ...e.legacyIds, e.titulo.toLowerCase()];
  return keys.any(
    (k) =>
        k.toLowerCase().contains('configuracao') ||
        k.toLowerCase().contains('configuração') ||
        k.toLowerCase().contains('onboarding'),
  );
}
