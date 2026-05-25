import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assinatura usa layout premium estilo paywall', () {
    final screen = File(
      'lib/features/assinatura/screens/assinatura_screen.dart',
    ).readAsStringSync();

    expect(screen, contains('_AssinaturaHero'));
    expect(screen, contains('_PlanSegmentBar'));
    expect(screen, contains('_PremiumPlanShowcase'));
    expect(screen, contains('_TrustStrip'));
    expect(screen, contains('bottomNavigationBar'));
    expect(screen, contains('restoreAndVerifyPurchases'));
    expect(screen, contains('_BillingPeriodToggle'));
    expect(screen, contains('subscription_products.dart'));
    expect(screen, contains('focux_premium_yearly'));
    expect(screen, isNot(contains('Resumo do plano')));
    expect(screen, isNot(contains('class _PlanoCard')));
  });
}
