import 'models/subscription_plan.dart';

/// IDs oficiais para App Store Connect e Google Play Console.
enum SubscriptionBillingPeriod { monthly, yearly }

class SubscriptionProducts {
  SubscriptionProducts._();

  static const String premiumMonthly = 'focux_premium_monthly';
  static const String premiumYearly = 'focux_premium_yearly';
  static const String enterpriseMonthly = 'focux_enterprise_monthly';
  static const String enterpriseYearly = 'focux_enterprise_yearly';

  /// Desconto de referência no anual vs 12× mensal (exibido na vitrine).
  static const double annualDiscountRate = 0.20;

  static const Set<String> allStoreProductIds = {
    premiumMonthly,
    premiumYearly,
    enterpriseMonthly,
    enterpriseYearly,
  };

  static String productIdFor(
    SubscriptionPlan plan,
    SubscriptionBillingPeriod period,
  ) {
    return switch (plan) {
      SubscriptionPlan.PREMIUM =>
        period == SubscriptionBillingPeriod.yearly
            ? premiumYearly
            : premiumMonthly,
      SubscriptionPlan.ENTERPRISE =>
        period == SubscriptionBillingPeriod.yearly
            ? enterpriseYearly
            : enterpriseMonthly,
      SubscriptionPlan.FREE => '',
    };
  }

  static SubscriptionPlan? planForProductId(String productId) {
    final id = productId.toLowerCase();
    if (id.contains('enterprise')) return SubscriptionPlan.ENTERPRISE;
    if (id.contains('premium') || id.contains('pro')) {
      return SubscriptionPlan.PREMIUM;
    }
    return null;
  }

  static SubscriptionBillingPeriod? billingPeriodForProductId(String productId) {
    final id = productId.toLowerCase();
    if (id.contains('yearly') || id.contains('annual')) {
      return SubscriptionBillingPeriod.yearly;
    }
    if (id.contains('monthly')) return SubscriptionBillingPeriod.monthly;
    return null;
  }

  static bool isYearlyProduct(String productId) =>
      billingPeriodForProductId(productId) == SubscriptionBillingPeriod.yearly;

  /// Preço anual de vitrine quando a loja ainda não retornou ProductDetails.
  static double referenceAnnualPrice(double monthlyPrice) =>
      (monthlyPrice * 12 * (1 - annualDiscountRate));

  static String savingsLabel() =>
      'Economize ${(annualDiscountRate * 100).round()}% no plano anual';

  /// Texto curto para o segmento Anual (ex.: −20% · R$ 192/ano).
  static String annualSavingsCompactLabel(double monthlyPrice) {
    if (monthlyPrice <= 0) {
      return 'Economize ${(annualDiscountRate * 100).round()}%';
    }
    final saved = monthlyPrice * 12 * annualDiscountRate;
    final pct = (annualDiscountRate * 100).round();
    return '−$pct% · R\$ ${saved.toStringAsFixed(0)}/ano';
  }

  static String periodLabel(SubscriptionBillingPeriod period) =>
      period == SubscriptionBillingPeriod.yearly ? 'Anual' : 'Mensal';
}
