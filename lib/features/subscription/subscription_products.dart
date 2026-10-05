import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

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
    // SKUs legados ainda em voo (restore / receipts): focux_premium_*.
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

  /// Tag da oferta de indicação no Play Console (20% no primeiro mês pago).
  static const String referralOfferTag = 'indicacao';

  static const Set<String> referralDiscountProductIds = {
    proMonthly,
    enterpriseMonthly,
  };

  static bool _isReferralOffer(ProductDetails item) {
    if (item is! GooglePlayProductDetails) return false;
    final index = item.subscriptionIndex;
    final offers = item.productDetails.subscriptionOfferDetails;
    if (index == null || offers == null || index >= offers.length) return false;
    return offers[index].offerTags.contains(referralOfferTag);
  }

  /// No Google Play cada oferta chega como um item com o mesmo id; o preço de
  /// vitrine é o do plano base (primeira fase paga).
  static Map<String, ProductDetails> displayById(
    Iterable<ProductDetails> items,
  ) {
    final out = <String, ProductDetails>{};
    for (final item in items) {
      if (_isReferralOffer(item)) continue;
      final current = out[item.id];
      if (current == null || (current.rawPrice <= 0 && item.rawPrice > 0)) {
        out[item.id] = item;
      }
    }
    return out;
  }

  /// Ofertas grátis que o Google Play devolve só para quem tem direito.
  static Map<String, ProductDetails> freeTrialOffersById(
    Iterable<ProductDetails> items,
  ) => {
    for (final item in items)
      if (item.rawPrice <= 0 && !_isReferralOffer(item)) item.id: item,
  };

  /// Oferta de indicação do Google Play (o Play devolve para todos; o backend
  /// decide quem é indicado).
  static Map<String, ProductDetails> referralOffersById(
    Iterable<ProductDetails> items,
  ) => {
    for (final item in items)
      if (_isReferralOffer(item)) item.id: item,
  };

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
