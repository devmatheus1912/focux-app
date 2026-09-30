import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../subscription_products.dart';
import '../utils/iap_completion_policy.dart';
import 'iap_purchase_event.dart';
import 'iap_service.dart';
import 'iap_store.dart';

typedef IapVerify =
    Future<Map<String, dynamic>> Function(PurchaseDetails purchase);

class IapRestoreResult {
  final bool storeAvailable;
  final int verifiedCount;
  final int failureCount;

  const IapRestoreResult({
    required this.storeAvailable,
    this.verifiedCount = 0,
    this.failureCount = 0,
  });

  bool get hasVerifiedPurchases => verifiedCount > 0;
  bool get hasFailures => failureCount > 0;
}

String iapPurchaseKey(PurchaseDetails purchase) => [
  purchase.productID,
  purchase.purchaseID ?? 'sem-id',
  purchase.transactionDate ?? 'sem-data',
].join('|');

/// Único listener do `purchaseStream` no app.
///
/// Toda compra entregue pela loja (checkout, renovação, restore ou transação
/// pendente reentregue ao abrir) é validada uma vez no servidor. A conclusão
/// na loja segue [iapShouldCompleteAfterVerifyFailure] quando o verify falha.
class IapPurchaseCoordinator {
  IapPurchaseCoordinator({
    required IapStore store,
    required IapVerify verify,
    bool Function(String productId)? isSupportedProduct,
    bool? isAndroid,
  }) : _store = store,
       _verify = verify,
       _isSupportedProduct =
           isSupportedProduct ??
           ((id) => SubscriptionProducts.planForProductId(id) != null),
       _isAndroid =
           isAndroid ?? defaultTargetPlatform == TargetPlatform.android;

  final IapStore _store;
  final IapVerify _verify;
  final bool Function(String productId) _isSupportedProduct;
  final bool _isAndroid;

  final _events = StreamController<IapPurchaseEvent>.broadcast();
  final Set<String> _inFlight = <String>{};
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Future<bool>? _starting;
  Completer<void>? _restoreDone;
  int _session = 0;

  Stream<IapPurchaseEvent> get events => _events.stream;

  bool get isListening => _subscription != null;

  /// Idempotente. Android: `restorePurchases` silencioso (sem prompt). iOS: só o stream.
  Future<bool> start() {
    if (_subscription != null) return Future.value(true);
    return _starting ??= _listen(_session);
  }

  Future<bool> _listen(int session) async {
    try {
      final available = await _store.isAvailable();
      if (!available || session != _session) return false;
      _subscription = _store.purchaseStream.listen(
        (purchases) => _onBatch(purchases, session),
        onError: (Object error) {
          if (session == _session) _emit(IapPurchaseStreamFailed(error));
        },
      );
      if (_isAndroid && session == _session) {
        try {
          await _store.restorePurchases();
        } catch (error) {
          debugPrint('[IAP] restore Android na abertura falhou: ${_failureReason(error)}');
        }
      }
      return true;
    } finally {
      if (session == _session) _starting = null;
    }
  }

  /// Logout: compras ainda não processadas ficam para a próxima sessão e o
  /// restore em andamento termina com o que já foi contado.
  Future<void> stop() async {
    _session++;
    _starting = null;
    _inFlight.clear();
    final restoreDone = _restoreDone;
    if (restoreDone != null && !restoreDone.isCompleted) restoreDone.complete();
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }

  Future<void> dispose() async {
    await stop();
    await _events.close();
  }

  /// Abre a compra só com o listener ativo; `false` = loja indisponível e a
  /// compra não é aberta.
  Future<bool> buy(ProductDetails product) async {
    if (!await start()) return false;
    await _store.buyNonConsumable(product);
    return true;
  }

  Future<IapRestoreResult> restore({
    Duration timeout = const Duration(seconds: 8),
    Duration quietPeriod = const Duration(milliseconds: 900),
  }) async {
    if (!await start()) return const IapRestoreResult(storeAvailable: false);

    final done = _restoreDone = Completer<void>();
    var verified = 0;
    var failures = 0;
    Timer? finishTimer;

    void finishAfter(Duration delay) {
      finishTimer?.cancel();
      finishTimer = Timer(delay, () {
        if (!done.isCompleted) done.complete();
      });
    }

    final sub = events.listen((event) {
      switch (event) {
        case IapPurchaseVerifying():
          finishTimer?.cancel();
        case IapPurchaseVerified():
          verified++;
        case IapPurchaseVerifyFailed() || IapPurchaseStoreError():
          failures++;
        case IapPurchaseBatchProcessed():
          finishAfter(quietPeriod);
        case IapPurchaseStreamFailed():
          failures++;
          finishAfter(Duration.zero);
        case IapPurchasePending() ||
            IapPurchaseCanceled() ||
            IapPurchaseUnsupported():
          break;
      }
    });

    try {
      await _store.restorePurchases();
      if (!done.isCompleted) finishAfter(timeout);
      await done.future;
    } finally {
      finishTimer?.cancel();
      await sub.cancel();
      if (identical(_restoreDone, done)) _restoreDone = null;
    }

    return IapRestoreResult(
      storeAvailable: true,
      verifiedCount: verified,
      failureCount: failures,
    );
  }

  Future<void> _onBatch(List<PurchaseDetails> purchases, int session) async {
    for (final purchase in purchases) {
      if (session != _session) return;
      await _handle(purchase, session);
    }
    if (session == _session) _emit(const IapPurchaseBatchProcessed());
  }

  Future<void> _handle(PurchaseDetails purchase, int session) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        _emit(IapPurchasePending(purchase));
      case PurchaseStatus.canceled:
        _emit(IapPurchaseCanceled(purchase));
      case PurchaseStatus.error:
        _emit(IapPurchaseStoreError(purchase));
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        final key = iapPurchaseKey(purchase);
        if (!_inFlight.add(key)) return;
        try {
          if (await _verifyOnServer(purchase, session)) {
            await _complete(purchase);
          }
        } finally {
          _inFlight.remove(key);
        }
        return;
    }
    await _complete(purchase);
  }

  /// Devolve se a transação deve ser concluída na loja.
  Future<bool> _verifyOnServer(PurchaseDetails purchase, int session) async {
    if (!_isSupportedProduct(purchase.productID)) {
      _emit(IapPurchaseUnsupported(purchase));
      return true;
    }
    _emit(IapPurchaseVerifying(purchase));
    try {
      final response = await _verify(purchase);
      if (session == _session) _emit(IapPurchaseVerified(purchase, response));
      return true;
    } catch (error) {
      final complete = iapShouldCompleteAfterVerifyFailure(
        error: error,
        isAndroid: _isAndroid,
      );
      debugPrint(
        '[IAP] verify falhou: produto=${purchase.productID} '
        'motivo=${_failureReason(error)} concluir=$complete',
      );
      if (session == _session) _emit(IapPurchaseVerifyFailed(purchase, error));
      return complete;
    }
  }

  Future<void> _complete(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) return;
    try {
      await _store.completePurchase(purchase);
    } catch (error) {
      debugPrint('[IAP] completePurchase falhou: ${_failureReason(error)}');
    }
  }

  void _emit(IapPurchaseEvent event) {
    if (!_events.isClosed) _events.add(event);
  }
}

/// Motivo curto para log — nunca a mensagem crua (pode ecoar recibo/token).
String _failureReason(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    return status != null ? 'http_$status' : error.type.name;
  }
  return error.runtimeType.toString();
}

final iapPurchaseCoordinatorProvider = Provider<IapPurchaseCoordinator>((ref) {
  final coordinator = IapPurchaseCoordinator(
    store: ref.read(iapStoreProvider),
    verify: ref.read(iapServiceProvider).verifyPurchase,
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
