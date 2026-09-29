import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/api/payment_api_client.dart';
import 'iap_store.dart';

/// Bridge entre a loja nativa e o backend `/api/iap/verify`.
///
/// O servidor é a fonte de verdade do `Plano`; o app só reflete o estado
/// que vier do `/perfil` após o verify. O stream de compras é ouvido só pelo
/// `IapPurchaseCoordinator`.
class IapService {
  IapService(this._payment, this._store);

  final PaymentApiClient _payment;
  final IapStore _store;

  Future<bool> isAvailable() => _store.isAvailable();

  Future<Map<String, dynamic>> verifyPurchase(PurchaseDetails details) async {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final body = <String, dynamic>{
      'platform': isAndroid ? 'google' : 'apple',
      'productId': details.productID,
      'receipt': details.verificationData.serverVerificationData,
      'purchaseToken':
          isAndroid ? details.verificationData.serverVerificationData : null,
    };
    final res = await _payment.dio.post('/api/iap/verify', data: body);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{'status': 'PROCESSADO'};
  }
}

final iapServiceProvider = Provider<IapService>((ref) {
  return IapService(
    ref.read(paymentApiClientProvider),
    ref.read(iapStoreProvider),
  );
});
