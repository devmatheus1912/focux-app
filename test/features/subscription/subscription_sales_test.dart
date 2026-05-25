import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/subscription/subscription_products.dart';

void main() {
  test('planos redireciona para assinatura unificada', () {
    final router = File('lib/core/router/app_router.dart').readAsStringSync();
    expect(router, contains("path: '/planos'"));
    expect(router, contains("return '/assinatura'"));
  });

  test('paywall assinatura com CTA contextual e gerenciar loja', () {
    final assinatura = File(
      'lib/features/assinatura/screens/assinatura_screen.dart',
    ).readAsStringSync();
    expect(assinatura, contains('Gerenciar assinatura'));
    expect(
      File('lib/features/assinatura/screens/claude_paywall_layout.dart')
          .readAsStringSync(),
      contains('_ClaudePlanOptionTile'),
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
    expect(banner, contains("'/assinatura'"));
    expect(gate, contains('PlanEntitlements.lockedOffer'));
    expect(gate, contains("'/assinatura'"));
    expect(repo, contains('alunosAtivos'));
    expect(repo, contains('agenda: true'));
    expect(repo, contains('limiteAlunos: 5'));
  });
}
