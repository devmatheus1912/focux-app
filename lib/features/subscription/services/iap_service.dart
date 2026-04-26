import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/api/api_client.dart';
import '../../auth/providers/auth_provider.dart';

/// Bridge entre `in_app_purchase` e o backend `/api/iap/verify`.
///
/// Responsável por:
/// - Inicializar e descobrir produtos por id (Apple e Google).
/// - Disparar o fluxo de compra (autoConsume = false para assinaturas).
/// - Receber atualizações do stream e validar o receipt no servidor.
///
/// O servidor é a fonte de verdade do `Plano`; o app só reflete o estado
/// que vier do `/perfil` após o verify.
class IapService {
  IapService(this._api);

  final ApiClient _api;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _initialized = false;

  Future<bool> isAvailable() async {
    if (!Platform.isIOS && !Platform.isAndroid) return false;
    return _iap.isAvailable();
  }

  Future<List<ProductDetails>> loadProducts(Set<String> productIds) async {
    if (!await isAvailable()) return const [];
    final response = await _iap.queryProductDetails(productIds);
    if (response.error != null && kDebugMode) {
      debugPrint('IAP query error: ${response.error}');
    }
    return response.productDetails;
  }

  /// Inicializa o stream de compras (deve ser chamado uma vez por sessão).
  /// O [onVerified] é invocado depois que o backend valida o receipt.
  Future<void> attachStream({
    required Future<void> Function(PurchaseDetails details, Map<String, dynamic> serverResponse)
        onVerified,
    required void Function(IAPError error) onError,
  }) async {
    if (_initialized) return;
    _initialized = true;
    _sub = _iap.purchaseStream.listen(
      (purchases) async {
        for (final p in purchases) {
          if (p.status == PurchaseStatus.error) {
            onError(p.error ?? IAPError(
              source: 'iap',
              code: 'purchase_error',
              message: 'Erro ao processar compra',
            ));
            continue;
          }
          if (p.status == PurchaseStatus.purchased ||
              p.status == PurchaseStatus.restored) {
            try {
              final resp = await _verifyOnBackend(p);
              await onVerified(p, resp);
            } catch (e) {
              onError(IAPError(
                source: 'iap',
                code: 'verify_failed',
                message: 'Não foi possível validar a compra: $e',
              ));
            } finally {
              if (p.pendingCompletePurchase) {
                await _iap.completePurchase(p);
              }
            }
          }
        }
      },
      onError: (e) => onError(IAPError(
        source: 'iap',
        code: 'stream_error',
        message: e.toString(),
      )),
    );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _initialized = false;
  }

  Future<void> buy(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restore() async {
    await _iap.restorePurchases();
  }

  Future<Map<String, dynamic>> _verifyOnBackend(PurchaseDetails details) async {
    final body = <String, dynamic>{
      'platform': Platform.isIOS ? 'apple' : 'google',
      'productId': details.productID,
      'receipt': details.verificationData.serverVerificationData,
      'purchaseToken': Platform.isAndroid
          ? details.verificationData.serverVerificationData
          : null,
    };
    final res = await _api.dio.post('/api/iap/verify', data: body);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{'status': 'PROCESSADO'};
  }
}

final iapServiceProvider = Provider<IapService>((ref) {
  return IapService(ref.read(apiClientProvider));
});
