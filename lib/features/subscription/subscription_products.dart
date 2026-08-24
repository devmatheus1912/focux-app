import 'models/subscription_plan.dart';

/// IDs oficiais para App Store Connect e Google Play Console.
enum SubscriptionBillingPeriod { monthly, yearly }

class SubscriptionProducts {
  SubscriptionProducts._();

  static const String proMonthly = 'focux_pro_monthly';
  static const String proYearly = 'focux_pro_yearly';
  static const String enterpriseMonthly = 'focux_enterprise_monthly';
  static const String enterpriseYearly = 'focux_enterprise_yearly';

  /// SKUs legados ainda em voo (restore / receipts).
  static const String premiumMonthlyLegacy = 'focux_premium_monthly';
  static const String premiumYearlyLegacy = 'focux_premium_yearly';
  static const String enterpriseProMonthlyLegacy = 'focux_enterprise_pro_monthly';
  static const String enterpriseProYearlyLegacy = 'focux_enterprise_pro_yearly';

  /// Anual = 2 meses grátis ≈ 16,67% off sobre 12× mensal.
  static const double annualDiscountRate = 1 / 6;

  static const Set<String> allStoreProductIds = {
    proMonthly,
    proYearly,
    enterpriseMonthly,
    enterpriseYearly,
    premiumMonthlyLegacy,
    premiumYearlyLegacy,
    enterpriseProMonthlyLegacy,
    enterpriseProYearlyLegacy,
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
    if (id.contains('enterprise_pro') || id.contains('enterprise')) {
      return SubscriptionPlan.ENTERPRISE;
    }
    if (id.contains('premium') ||
        id.contains('_pro_') ||
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

  static bool isYearlyProduct(String productId) =>
      billingPeriodForProductId(productId) == SubscriptionBillingPeriod.yearly;

  /// Preço anual de vitrine quando a loja ainda não retornou ProductDetails.
  static double referenceAnnualPrice(double monthlyPrice) => monthlyPrice * 10;

  static String savingsLabel() => '2 meses grátis';

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

  static String periodLabel(SubscriptionBillingPeriod period) =>
      period == SubscriptionBillingPeriod.yearly ? 'Anual' : 'Mensal';
}
