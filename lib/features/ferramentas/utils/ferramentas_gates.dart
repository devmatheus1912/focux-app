import '../../subscription/models/subscription_plan.dart';
import '../../subscription/plan_entitlements.dart';
import '../data/ferramentas_catalogo_models.dart';

String? capabilityFromFeatureGate(String? featureGate) {
  if (featureGate == null || featureGate.trim().isEmpty) return null;
  final raw = featureGate.trim();
  return PlanEntitlements.capabilityFromBackendFeature(raw) ??
      (raw.contains('_') ? null : raw);
}

SubscriptionPlan upgradePlanFromEntrada(CatalogoEntrada entrada) {
  if (entrada.upgradePlano != null && entrada.upgradePlano!.isNotEmpty) {
    return subscriptionPlanFromApi(entrada.upgradePlano);
  }
  return PlanEntitlements.targetPlan(
    capability: capabilityFromFeatureGate(entrada.featureGate),
    fallback: SubscriptionPlan.PRO,
  );
}
