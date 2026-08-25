import '../../subscription/models/subscription_plan.dart';

/// Código curto do plano (ex.: PRO) — aliases da API.
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
