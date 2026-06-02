import '../../subscription/models/subscription_plan.dart';
import '../../subscription/plan_entitlements.dart';

/// Rótulos do plano na tela de perfil (badge e seção Conta).
String perfilPlanSectionLabel(String apiPlano) {
  return PlanEntitlements.displayPlanName(subscriptionPlanFromApi(apiPlano));
}

/// Texto curto no pill do hero (ex.: PLANO PRO).
String perfilPlanPillLabel(String apiPlano) {
  return switch (subscriptionPlanFromApi(apiPlano)) {
    SubscriptionPlan.ENTERPRISE_PRO => 'PRO',
    SubscriptionPlan.PREMIUM => 'PRO',
    SubscriptionPlan.ENTERPRISE => 'ENTERPRISE',
    SubscriptionPlan.FREE => 'FREE',
  };
}
