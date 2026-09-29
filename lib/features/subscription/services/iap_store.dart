import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Recorte da loja nativa usado pelo fluxo de compras (fake em testes).
abstract interface class IapStore {
  Future<bool> isAvailable();

  Stream<List<PurchaseDetails>> get purchaseStream;

  Future<void> completePurchase(PurchaseDetails purchase);

  Future<void> restorePurchases();

  Future<void> buyNonConsumable(ProductDetails product);
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
  Future<void> buyNonConsumable(ProductDetails product) => _iap
      .buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
}

final iapStoreProvider = Provider<IapStore>((ref) => const PluginIapStore());
