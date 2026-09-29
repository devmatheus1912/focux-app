import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/assinatura/utils/assinatura_checkout_events.dart';
import 'package:focux_app/features/subscription/services/iap_purchase_event.dart';
import 'package:focux_app/features/subscription/subscription_products.dart';
import 'package:focux_app/l10n/app_localizations.dart';
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

  group('mensagens de falha da compra', () {
    final pt = lookupS(const Locale('pt'));

    test('transação anterior pendente no StoreKit orienta restaurar', () {
      final msg = assinaturaBuyErrorMessage(
        pt,
        PlatformException(code: 'storekit_duplicate_product_object'),
      );
      expect(
        msg,
        'Sua compra anterior ainda está sendo confirmada. '
        'Toque em Restaurar compras ou reabra o app.',
      );
    });

    test('outra falha ao abrir a compra não vaza código da loja', () {
      final msg = assinaturaBuyErrorMessage(
        pt,
        PlatformException(code: 'storekit_outro', message: 'SKError 2'),
      );
      expect(msg, isNot(contains('storekit')));
      expect(msg, isNot(contains('SKError')));
    });

    test('verify transitório avisa que o pagamento será confirmado', () {
      final timeout = DioException(
        requestOptions: RequestOptions(path: '/api/iap/verify'),
        type: DioExceptionType.connectionTimeout,
      );
      final ios = assinaturaVerifyFailedMessage(pt, timeout, isAndroid: false);
      expect(ios, contains('confirmado automaticamente'));
      expect(ios, contains('Restaurar compras'));

      final android = assinaturaVerifyFailedMessage(
        pt,
        timeout,
        isAndroid: true,
      );
      expect(android, contains('Restaurar compras'));
      expect(android, contains('sem nova cobrança'));
    });

    test('verify recusado mantém a mensagem do servidor', () {
      final req = RequestOptions(path: '/api/iap/verify');
      final msg = assinaturaVerifyFailedMessage(
        pt,
        DioException(
          requestOptions: req,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: req,
            statusCode: 403,
            data: {'erro': 'Recibo pertence a outra conta.'},
          ),
        ),
        isAndroid: false,
      );
      expect(msg, isNot(contains('confirmado automaticamente')));
    });

    test('loja indisponível tem texto humano', () {
      expect(
        pt.assinaturaLojaIndisponivel,
        'Loja indisponível no momento. Tente de novo em instantes.',
      );
    });
  });
}
