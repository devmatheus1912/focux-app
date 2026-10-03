import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';
import 'package:focux_app/features/subscription/subscription_products.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('planos redireciona para assinatura unificada', () {
    final router = readRouterSourceBundle();
    expect(router, contains("path: '/planos'"));
    expect(router, contains("path: '/paywall'"));
    expect(router, contains("return '/assinatura'"));
    expect(router, isNot(contains('PaywallScreen')));
  });

  test('paywall assinatura com CTA contextual e gerenciar loja', () {
    final assinatura = readScreenSourceBundle(
      'lib/features/assinatura/screens/assinatura_screen.dart',
    );
    expect(assinatura, contains('Gerenciar assinatura'));
    expect(
      File('lib/features/planos/paywall/paywall_compare_stage.dart')
          .readAsStringSync(),
      contains('class PaywallCompareStage'),
    );
    expect(assinatura, contains('openNativeSubscriptionManagement'));
  });

  test('SKUs anuais configurados no app e backend', () {
    final products = File(
      'lib/features/subscription/subscription_products.dart',
    ).readAsStringSync();
    expect(products, contains('focux_pro_yearly'));
    expect(products, contains('focux_enterprise_yearly'));
    expect(products, contains('annualDiscountRate'));
    expect(products, contains('annualSavingsCompactLabel'));
  });

  test('SKUs premium legados ainda mapeiam para PRO no restore', () {
    expect(
      SubscriptionProducts.planForProductId('focux_premium_monthly'),
      SubscriptionPlan.PRO,
    );
    expect(
      SubscriptionProducts.planForProductId('focux_premium_yearly'),
      SubscriptionPlan.PRO,
    );
    expect(
      SubscriptionProducts.planForProductId('focux_pro_monthly'),
      SubscriptionPlan.PRO,
    );
    expect(
      SubscriptionProducts.planForProductId('sku_desconhecido'),
      isNull,
    );
  });

  test('segmento anual sem hifen duplo no subtexto', () {
    final label = SubscriptionProducts.annualSavingsCompactLabel(99.90);
    expect(label, contains('2 meses grátis'));
    expect(label, isNot(contains('20%')));
    expect(label, isNot(contains('−20%')));
    expect(label, isNot(contains('− −')));
    expect(label, isNot(contains('- -')));
  });

  test('card anual usa copy distinta do segmento', () {
    final card = SubscriptionProducts.annualSavingsCardLabel(99.90);
    expect(card, contains('Economize R\$ 199,80'));
    expect(card, isNot(contains('20%')));
    expect(card, isNot(contains('−20%')));
  });

  test('matriz de vendas: entitlements, banner e gate contextual', () {
    final entitlements = File(
      'lib/features/subscription/plan_entitlements.dart',
    ).readAsStringSync();
    final banner = File(
      'lib/features/subscription/widgets/plan_usage_banner.dart',
    ).readAsStringSync();
    final gate = File('lib/core/widgets/feature_gate.dart').readAsStringSync();
    final repo = File(
      'lib/features/planos/data/planos_repository.dart',
    ).readAsStringSync();

    expect(entitlements, contains('LockedOffer'));
    expect(entitlements, contains('softGateMessage'));
    expect(banner, contains('/assinatura'));
    expect(gate, contains('PlanEntitlements.lockedOffer'));
    expect(gate, contains('/assinatura'));
    expect(repo, contains('alunosAtivos'));
    expect(repo, contains('agenda: true'));
    expect(repo, contains('limiteAlunos: 3'));
  });

  test('Play: preço vem da oferta paga e trial só se a loja devolver', () {
    ProductDetails p(double raw) => ProductDetails(
      id: SubscriptionProducts.proMonthly,
      title: 'PRO',
      description: 'PRO mensal',
      price: raw == 0 ? 'Grátis' : r'R$ 49,90',
      rawPrice: raw,
      currencyCode: 'BRL',
    );
    final trial = p(0);
    final paga = p(49.9);

    expect(SubscriptionProducts.displayById([trial, paga]).values.single, paga);
    expect(SubscriptionProducts.displayById([paga, trial]).values.single, paga);
    expect(
      SubscriptionProducts.freeTrialOffersById([trial, paga]),
      {SubscriptionProducts.proMonthly: trial},
    );
    expect(SubscriptionProducts.freeTrialOffersById([paga]), isEmpty);
  });
}