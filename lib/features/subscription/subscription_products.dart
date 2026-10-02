import 'models/subscription_plan.dart';

/// IDs oficiais para App Store Connect e Google Play Console.
enum SubscriptionBillingPeriod { monthly, yearly }

class SubscriptionProducts {
  SubscriptionProducts._();

  static const String proMonthly = 'focux_pro_monthly';
  static const String proYearly = 'focux_pro_yearly';
  static const String enterpriseMonthly = 'focux_enterprise_monthly';
  static const String enterpriseYearly = 'focux_enterprise_yearly';

  /// 1/6 de desconto sobre 12 mensalidades: anual = mensal × 12 × 5/6 =
  /// mensal × 10 (2 meses grátis).
  static const double annualDiscountRate = 1 / 6;

  static const Set<String> allStoreProductIds = {
    proMonthly,
    proYearly,
    enterpriseMonthly,
    enterpriseYearly,
  };

  static String productIdFor(
    SubscriptionPlan plan,
    SubscriptionBillingPeriod period,
  ) {
    return switch (plan) {
      SubscriptionPlan.PRO =>
        period == SubscriptionBillingPeriod.yearly ? proYearly : proMonthly,
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
    if (id.contains('_pro_') ||
        id.endsWith('_pro') ||
        id.contains('.pro.')) {
      return SubscriptionPlan.PRO;
    }
    return null;
  }

  static SubscriptionBillingPeriod? billingPeriodForProductId(
    String productId,
  ) {
    final id = productId.toLowerCase();
    if (id.contains('yearly') || id.contains('annual')) {
      return SubscriptionBillingPeriod.yearly;
    }
    if (id.contains('monthly')) return SubscriptionBillingPeriod.monthly;
    return null;
  }

  static double annualSavingsAmount(double monthlyPrice) => monthlyPrice * 2;

  static String annualSavingsCompactLabel(double monthlyPrice) {
    if (monthlyPrice <= 0) return '2 meses grátis';
    final saved = annualSavingsAmount(monthlyPrice);
    return '2 meses grátis · R\$ ${saved.toStringAsFixed(0)}';
  }

  static String annualSavingsCardLabel(double monthlyPrice) {
    if (monthlyPrice <= 0) return '';
    final saved = annualSavingsAmount(monthlyPrice);
    return 'Economize R\$ ${saved.toStringAsFixed(2).replaceAll('.', ',')}/ano';
  }
}
