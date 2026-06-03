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
      readPaywallComponentsBundle(),
      contains('PaywallRichPlanCard'),
    );
    expect(assinatura, contains('openNativeSubscriptionManagement'));
  });

  test('SKUs anuais configurados no app e backend', () {
    final products = File(
      'lib/features/subscription/subscription_products.dart',
    ).readAsStringSync();
    expect(products, contains('focux_premium_yearly'));
    expect(products, contains('focux_enterprise_yearly'));
    expect(products, contains('annualDiscountRate'));
    expect(products, contains('annualSavingsCompactLabel'));
  });

  test('segmento anual sem hifen duplo no subtexto', () {
    final label = SubscriptionProducts.annualSavingsCompactLabel(150);
    expect(label, '−20% · R\$ 360/ano');
    expect(label, isNot(contains('− −')));
    expect(label, isNot(contains('- -')));
  });

  test('card anual usa copy distinta do segmento', () {
    final card = SubscriptionProducts.annualSavingsCardLabel(149.90);
    expect(card, 'Economize R\$ 360/ano');
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
    expect(repo, contains('limiteAlunos: 5'));
  });
}
