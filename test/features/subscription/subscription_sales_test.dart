import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
    expect(products, contains('focux_premium_yearly'));
    expect(products, contains('annualDiscountRate'));
    expect(products, contains('annualSavingsCompactLabel'));
  });

  test('segmento anual sem hifen duplo no subtexto', () {
    final label = SubscriptionProducts.annualSavingsCompactLabel(99.90);
    expect(label, contains('2 meses grátis'));
    expect(label, isNot(contains('−20%')));
    expect(label, isNot(contains('− −')));
    expect(label, isNot(contains('- -')));
  });

  test('card anual usa copy distinta do segmento', () {
    final card = SubscriptionProducts.annualSavingsCardLabel(99.90);
    expect(card, contains('Economize R\$ 199,80'));
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
}
