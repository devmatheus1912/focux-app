import 'package:flutter/services.dart';

import '../../../core/utils/friendly_error.dart';
import '../../../l10n/app_localizations.dart';
import '../../subscription/services/iap_purchase_event.dart';
import '../../subscription/utils/iap_completion_policy.dart';

/// O evento é da compra que a tela abriu? Renovação ou transação de outro
/// produto que chega com o paywall aberto não vira sucesso/erro da tela.
/// Evento sem transação (lote, erro do stream) também não: o stream segue
/// vivo depois de um erro e a compra ainda pode chegar.
bool assinaturaCheckoutOwnsEvent(
  IapPurchaseEvent event, {
  required String? checkoutProductId,
}) {
  if (checkoutProductId == null) return false;
  return event.purchase?.productID == checkoutProductId;
}

/// StoreKit recusa abrir a compra enquanto a transação anterior do mesmo
/// produto não foi concluída.
const _storeKitTransacaoPendente = 'storekit_duplicate_product_object';

String assinaturaBuyErrorMessage(S l10n, Object error) {
  if (error is PlatformException && error.code == _storeKitTransacaoPendente) {
    return l10n.assinaturaCompraAnteriorPendente;
  }
  return friendlyError(error, fallback: 'Erro ao iniciar a compra na loja.');
}

/// A loja já cobrou quando o verify falha. Falha transitória: no iOS o
/// StoreKit reentrega a transação ao reabrir; no Android ela já foi
/// concluída e só o Restaurar compras valida de novo.
String assinaturaVerifyFailedMessage(
  S l10n,
  Object error, {
  required bool isAndroid,
}) {
  if (iapVerifyFailureIsTransient(error)) {
    return isAndroid
        ? l10n.assinaturaPagamentoConfirmacaoPendenteAndroid
        : l10n.assinaturaPagamentoConfirmacaoPendente;
  }
  return friendlyError(
    error,
    fallback: 'Não foi possível sincronizar a assinatura.',
  );
}
