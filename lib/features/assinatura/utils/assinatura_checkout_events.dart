import '../../subscription/services/iap_purchase_event.dart';

/// O evento é da compra que a tela abriu? Renovação ou transação de outro
/// produto que chega com o paywall aberto não vira sucesso/erro da tela.
bool assinaturaCheckoutOwnsEvent(
  IapPurchaseEvent event, {
  required String? checkoutProductId,
}) {
  if (checkoutProductId == null) return false;
  final purchase = event.purchase;
  return purchase == null || purchase.productID == checkoutProductId;
}
