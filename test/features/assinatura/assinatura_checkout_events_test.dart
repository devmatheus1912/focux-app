import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/assinatura/utils/assinatura_checkout_events.dart';
import 'package:focux_app/features/subscription/services/iap_purchase_event.dart';
import 'package:focux_app/features/subscription/subscription_products.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

PurchaseDetails _compra(String produto) => PurchaseDetails(
  purchaseID: 'tx-1',
  productID: produto,
  verificationData: PurchaseVerificationData(
    localVerificationData: 'local',
    serverVerificationData: 'recibo',
    source: 'app_store',
  ),
  transactionDate: '1700000000000',
  status: PurchaseStatus.purchased,
);

void main() {
  const pro = SubscriptionProducts.proMonthly;
  const enterprise = SubscriptionProducts.enterpriseYearly;

  test('sem checkout aberto nenhum evento é da tela', () {
    expect(
      assinaturaCheckoutOwnsEvent(
        IapPurchaseVerified(_compra(pro), const {}),
        checkoutProductId: null,
      ),
      isFalse,
    );
  });

  test('só o produto que a tela abriu vira sucesso/erro da tela', () {
    expect(
      assinaturaCheckoutOwnsEvent(
        IapPurchaseVerified(_compra(pro), const {}),
        checkoutProductId: pro,
      ),
      isTrue,
    );
    expect(
      assinaturaCheckoutOwnsEvent(
        IapPurchaseVerified(_compra(enterprise), const {}),
        checkoutProductId: pro,
      ),
      isFalse,
    );
    expect(
      assinaturaCheckoutOwnsEvent(
        IapPurchaseVerifyFailed(_compra(enterprise), Exception('x')),
        checkoutProductId: pro,
      ),
      isFalse,
    );
  });

  test('falha do stream durante o checkout é da tela', () {
    expect(
      assinaturaCheckoutOwnsEvent(
        IapPurchaseStreamFailed(Exception('x')),
        checkoutProductId: pro,
      ),
      isTrue,
    );
  });

  test('compra abre pelo coordenador; loja indisponível aborta com aviso', () {
    final screen =
        File(
          'lib/features/assinatura/screens/assinatura_screen.dart',
        ).readAsStringSync();
    expect(screen, contains('.buy(productToBuy)'));
    expect(screen, contains('S.of(context).assinaturaLojaIndisponivel'));
    expect(screen, isNot(contains('InAppPurchase.instance.buyNonConsumable')));
    expect(screen, isNot(contains('purchaseStream')));

    final arb = File('lib/l10n/app_pt.arb').readAsStringSync();
    expect(
      arb,
      contains(
        '"assinaturaLojaIndisponivel": '
        '"Loja indisponível no momento. Tente de novo em instantes."',
      ),
    );
  });
}
