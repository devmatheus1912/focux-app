import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../subscription_products.dart';
import 'iap_service.dart';
import 'iap_store.dart';

typedef IapVerify =
    Future<Map<String, dynamic>> Function(PurchaseDetails purchase);

sealed class IapPurchaseEvent {
  const IapPurchaseEvent();
}

final class IapPurchasePending extends IapPurchaseEvent {
  const IapPurchasePending(this.purchase);
  final PurchaseDetails purchase;
}

final class IapPurchaseCanceled extends IapPurchaseEvent {
  const IapPurchaseCanceled(this.purchase);
  final PurchaseDetails purchase;
}

final class IapPurchaseStoreError extends IapPurchaseEvent {
  const IapPurchaseStoreError(this.purchase);
  final PurchaseDetails purchase;
}

final class IapPurchaseUnsupported extends IapPurchaseEvent {
  const IapPurchaseUnsupported(this.purchase);
  final PurchaseDetails purchase;
}

final class IapPurchaseVerifying extends IapPurchaseEvent {
  const IapPurchaseVerifying(this.purchase);
  final PurchaseDetails purchase;
}

final class IapPurchaseVerified extends IapPurchaseEvent {
  const IapPurchaseVerified(this.purchase, this.response);
  final PurchaseDetails purchase;
  final Map<String, dynamic> response;
}

final class IapPurchaseVerifyFailed extends IapPurchaseEvent {
  const IapPurchaseVerifyFailed(this.purchase, this.error);
  final PurchaseDetails purchase;
  final Object error;
}

/// Lote do stream da loja terminou de ser processado.
final class IapPurchaseBatchProcessed extends IapPurchaseEvent {
  const IapPurchaseBatchProcessed();
}

final class IapPurchaseStreamFailed extends IapPurchaseEvent {
  const IapPurchaseStreamFailed(this.error);
  final Object error;
}

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
/// pendente reentregue ao abrir) é validada uma vez no servidor e concluída
/// na loja quando `pendingCompletePurchase` — inclusive se a validação falhar,
/// para a transação não travar novas compras do mesmo produto.
class IapPurchaseCoordinator {
  IapPurchaseCoordinator({
    required IapStore store,
    required IapVerify verify,
    bool Function(String productId)? isSupportedProduct,
  }) : _store = store,
       _verify = verify,
       _isSupportedProduct =
           isSupportedProduct ??
           ((id) => SubscriptionProducts.planForProductId(id) != null);

  final IapStore _store;
  final IapVerify _verify;
  final bool Function(String productId) _isSupportedProduct;

  final _events = StreamController<IapPurchaseEvent>.broadcast();
  final Set<String> _inFlight = <String>{};
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Future<bool>? _starting;
  int _session = 0;

  Stream<IapPurchaseEvent> get events => _events.stream;

  bool get isListening => _subscription != null;

  /// Idempotente. Não chama `restorePurchases` (evita prompt da Apple ID).
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
      return true;
    } finally {
      if (session == _session) _starting = null;
    }
  }

  /// Logout: compras ainda não processadas ficam para a próxima sessão.
  Future<void> stop() async {
    _session++;
    _starting = null;
    _inFlight.clear();
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }

  Future<void> dispose() async {
    await stop();
    await _events.close();
  }

  Future<IapRestoreResult> restore({
    Duration timeout = const Duration(seconds: 8),
    Duration quietPeriod = const Duration(milliseconds: 900),
  }) async {
    if (!await start()) return const IapRestoreResult(storeAvailable: false);

    final done = Completer<void>();
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
      finishAfter(timeout);
      await done.future;
    } finally {
      finishTimer?.cancel();
      await sub.cancel();
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
          await _verifyOnServer(purchase, session);
          await _complete(purchase);
        } finally {
          _inFlight.remove(key);
        }
        return;
    }
    await _complete(purchase);
  }

  Future<void> _verifyOnServer(PurchaseDetails purchase, int session) async {
    if (!_isSupportedProduct(purchase.productID)) {
      _emit(IapPurchaseUnsupported(purchase));
      return;
    }
    _emit(IapPurchaseVerifying(purchase));
    try {
      final response = await _verify(purchase);
      if (session == _session) _emit(IapPurchaseVerified(purchase, response));
    } catch (error) {
      if (session == _session) _emit(IapPurchaseVerifyFailed(purchase, error));
    }
  }

  Future<void> _complete(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) return;
    try {
      await _store.completePurchase(purchase);
    } catch (error) {
      if (kDebugMode) debugPrint('[IAP] completePurchase falhou: $error');
    }
  }

  void _emit(IapPurchaseEvent event) {
    if (!_events.isClosed) _events.add(event);
  }
}

final iapPurchaseCoordinatorProvider = Provider<IapPurchaseCoordinator>((ref) {
  final coordinator = IapPurchaseCoordinator(
    store: ref.read(iapStoreProvider),
    verify: ref.read(iapServiceProvider).verifyPurchase,
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
