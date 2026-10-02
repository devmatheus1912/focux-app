import '../../subscription/models/subscription_plan.dart';
import '../data/planos_repository.dart';

/// Resolve capabilities (legadas ou chaves de `recursos`) contra o plano atual.
class PlanoCapability {
  PlanoCapability._();

  static bool has(PlanoFeatures features, String capability) {
    switch (capability) {
      case 'agenda':
        return true;
      case 'comunidadePrivada':
        return false;
    }
    final key = PlanoRecursoKeys.fromCapability(capability);
    if (key == null) return false;
    return features.recurso(key).liberado;
  }

  /// Plano mínimo do recurso (servidor quando houver `recursos`, senão matriz).
  static SubscriptionPlan minimumPlan(
    PlanoFeatures features,
    String capability, {
    SubscriptionPlan fallback = SubscriptionPlan.PRO,
  }) {
    final key = PlanoRecursoKeys.fromCapability(capability);
    if (key == null) return fallback;
    return features.recurso(key).planoMinimo;
  }
}
