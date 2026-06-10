import '../subscription/models/subscription_plan.dart';
import '../subscription/subscription_products.dart';

/// Payload para `/assinatura/review` via GoRouter `extra`.
class AssinaturaReviewRouteArgs {
  const AssinaturaReviewRouteArgs({
    required this.plan,
    required this.billingPeriod,
    required this.priceDisplay,
    this.trialNote,
  });

  final SubscriptionPlan plan;
  final SubscriptionBillingPeriod billingPeriod;
  final String priceDisplay;
  final String? trialNote;
}

/// Payload para `/assinatura/success` via GoRouter `extra`.
class AssinaturaSuccessRouteArgs {
  const AssinaturaSuccessRouteArgs({required this.plan, this.transactionId});

  final SubscriptionPlan plan;
  final String? transactionId;
}

SubscriptionPlan? subscriptionPlanFromRouteName(String? name) {
  if (name == null || name.trim().isEmpty) return null;
  final normalized = name.trim().toLowerCase();
  for (final plan in SubscriptionPlan.values) {
    if (plan.apiName.toLowerCase() == normalized) return plan;
  }
  return null;
}
