import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../subscription/services/iap_purchase_coordinator.dart';
import '../../subscription/store_subscription_policy.dart';
import '../../subscription/subscription_products.dart';
import 'paywall_price.dart';

/// A loja confirma se esta conta ainda tem o teste grátis do PRO mensal.
/// Falha ou sem loja: false (nunca promete o que a loja vai recusar).
final storeTrialEligibleProvider = FutureProvider.autoDispose<bool>((ref) async {
  if (!subscriptionUsesNativeStore) return false;
  final productId = SubscriptionProducts.productIdFor(
    kTrialPlan,
    SubscriptionBillingPeriod.monthly,
  );
  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final response = await InAppPurchase.instance.queryProductDetails({productId});
      return SubscriptionProducts.freeTrialOffersById(response.productDetails)
          .containsKey(productId);
    }
    return await ref.read(iapPurchaseCoordinatorProvider).introOfferEligible(productId) ??
        false;
  } catch (_) {
    return false;
  }
});
