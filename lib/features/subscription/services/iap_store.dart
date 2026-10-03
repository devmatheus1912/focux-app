import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

/// Recorte da loja nativa usado pelo fluxo de compras (fake em testes).
abstract interface class IapStore {
  Future<bool> isAvailable();

  Stream<List<PurchaseDetails>> get purchaseStream;

  Future<void> completePurchase(PurchaseDetails purchase);

  Future<void> restorePurchases();

  /// [replacing]: assinatura ativa no Google Play que a nova substitui.
  Future<void> buyNonConsumable(
    ProductDetails product, {
    String? accountToken,
    PurchaseDetails? replacing,
  });

  /// Assinatura ativa no Google Play (null no iOS ou sem assinatura).
  Future<PurchaseDetails?> activeAndroidSubscription(
    bool Function(String productId) isSupported,
  );

  /// Elegibilidade da oferta introdutória na App Store; null se não souber.
  Future<bool?> introOfferEligible(String productId);
}

class PluginIapStore implements IapStore {
  const PluginIapStore();

  InAppPurchase get _iap => InAppPurchase.instance;

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.android)) {
      return false;
    }
    return _iap.isAvailable();
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);

  @override
  Future<void> restorePurchases() => _iap.restorePurchases();

  @override
  Future<void> buyNonConsumable(
    ProductDetails product, {
    String? accountToken,
    PurchaseDetails? replacing,
  }) {
    final PurchaseParam param;
    if (defaultTargetPlatform == TargetPlatform.android) {
      param = GooglePlayPurchaseParam(
        productDetails: product,
        applicationUserName: accountToken,
        changeSubscriptionParam:
            replacing is GooglePlayPurchaseDetails
                ? ChangeSubscriptionParam(
                  oldPurchaseDetails: replacing,
                  replacementMode: ReplacementMode.chargeProratedPrice,
                )
                : null,
      );
    } else {
      param = PurchaseParam(
        productDetails: product,
        applicationUserName: accountToken,
      );
    }
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  @override
  Future<PurchaseDetails?> activeAndroidSubscription(
    bool Function(String productId) isSupported,
  ) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final addition =
        _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await addition.queryPastPurchases();
    for (final purchase in response.pastPurchases) {
      if (isSupported(purchase.productID) &&
          purchase.status != PurchaseStatus.error) {
        return purchase;
      }
    }
    return null;
  }

  @override
  Future<bool?> introOfferEligible(String productId) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return null;
    try {
      return await SK2Product.isIntroductoryOfferEligible(productId);
    } catch (_) {
      return null;
    }
  }
}

final iapStoreProvider = Provider<IapStore>((ref) => const PluginIapStore());
