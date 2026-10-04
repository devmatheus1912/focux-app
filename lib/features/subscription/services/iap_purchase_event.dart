import 'package:in_app_purchase/in_app_purchase.dart';

/// Saída do `IapPurchaseCoordinator` para a UI e para o sync de plano.
sealed class IapPurchaseEvent {
  const IapPurchaseEvent();

  /// Transação do evento; `null` nos eventos de lote/stream.
  PurchaseDetails? get purchase => null;
}

final class IapPurchasePending extends IapPurchaseEvent {
  const IapPurchasePending(this.purchase);
  @override
  final PurchaseDetails purchase;
}

final class IapPurchaseCanceled extends IapPurchaseEvent {
  const IapPurchaseCanceled(this.purchase);
  @override
  final PurchaseDetails purchase;
}

final class IapPurchaseStoreError extends IapPurchaseEvent {
  const IapPurchaseStoreError(this.purchase);
  @override
  final PurchaseDetails purchase;
}

final class IapPurchaseUnsupported extends IapPurchaseEvent {
  const IapPurchaseUnsupported(this.purchase);
  @override
  final PurchaseDetails purchase;
}

final class IapPurchaseVerifying extends IapPurchaseEvent {
  const IapPurchaseVerifying(this.purchase);
  @override
  final PurchaseDetails purchase;
}

final class IapPurchaseVerified extends IapPurchaseEvent {
  const IapPurchaseVerified(this.purchase, this.response);
  @override
  final PurchaseDetails purchase;
  final Map<String, dynamic> response;
}

final class IapPurchaseVerifyFailed extends IapPurchaseEvent {
  const IapPurchaseVerifyFailed(this.purchase, this.error);
  @override
  final PurchaseDetails purchase;
  final Object error;
}

/// Transação antiga trocada por upgrade: concluída na loja sem mexer no plano.
final class IapPurchaseSuperseded extends IapPurchaseEvent {
  const IapPurchaseSuperseded(this.purchase);
  @override
  final PurchaseDetails purchase;
}

/// Lote do stream da loja terminou de ser processado.
final class IapPurchaseBatchProcessed extends IapPurchaseEvent {
  const IapPurchaseBatchProcessed();
}

final class IapPurchaseStreamFailed extends IapPurchaseEvent {
  const IapPurchaseStreamFailed(this.error);
  final Object error;
}
