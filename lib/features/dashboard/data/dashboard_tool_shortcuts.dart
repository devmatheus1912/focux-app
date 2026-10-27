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

  /// Uma linha do servidor sobre a ferramenta; vazia ou igual ao nome não conta.
  String? get descricao {
    final texto = entrada.subtitulo?.trim();
    if (texto == null || texto.isEmpty) return null;
    if (texto.toLowerCase() == label.trim().toLowerCase()) return null;
    return texto;
  }

  bool isUnlocked(PlanoFeatures features) {
    if (!entrada.unlocked) return false;
    if (capability == null) {
      // Hub com abas: trancado só quando nenhuma aba está liberada.
      if (!entrada.isHubComAbas) return true;
      return entrada.abas.any((aba) => _abaUnlocked(aba, features));
    }
    return PlanoCapability.has(features, capability!);
  }

  static bool _abaUnlocked(CatalogoEntrada aba, PlanoFeatures features) {
    if (!aba.unlocked) return false;
    final cap = capabilityFromEntrada(aba);
    return cap == null || PlanoCapability.has(features, cap);
  }

  SubscriptionPlan targetPlan() {
    if (entrada.upgradePlano != null && entrada.upgradePlano!.isNotEmpty) {
      return subscriptionPlanFromApi(entrada.upgradePlano);
    }
    if (capability == null && entrada.isHubComAbas) {
      final plans = [for (final aba in entrada.abas) upgradePlanFromEntrada(aba)];
      return plans.reduce((a, b) => a.level <= b.level ? a : b);
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
    final capability = capabilityFromEntrada(entrada);
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

/// Folhas + portas de hub (itens com abas contam como 1).
List<DashboardToolShortcut> catalogLeavesFromHub(CatalogoHub hub) {
  return [
    for (final item in hub.itens) DashboardToolShortcut.fromEntrada(item),
  ];
}

