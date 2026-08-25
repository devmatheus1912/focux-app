import '../../subscription/models/subscription_plan.dart';
import '../../subscription/plan_entitlements.dart';

/// Rótulos do plano na tela de perfil (badge e seção Conta).
String perfilPlanSectionLabel(String apiPlano) {
  return PlanEntitlements.displayPlanName(subscriptionPlanFromApi(apiPlano));
}

/// Código curto do plano (ex.: PRO) — usado em testes e mapeamento.
String perfilPlanPillLabel(String apiPlano) {
  return switch (subscriptionPlanFromApi(apiPlano)) {
    SubscriptionPlan.PRO => 'PRO',
    SubscriptionPlan.ENTERPRISE => 'ENTERPRISE',
    SubscriptionPlan.FREE => 'FREE',
  };
}

/// Valor à direita da linha Planos (ChatGPT/iOS).
String perfilPlanRowValue(String apiPlano) {
  return switch (perfilPlanPillLabel(apiPlano)) {
    'PRO' => 'Pro',
    'ENTERPRISE' => 'Enterprise',
    'FREE' => 'Grátis',
    final other => other,
  };
}
