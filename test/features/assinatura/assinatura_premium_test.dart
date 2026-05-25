import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assinatura paywall 10/10: layout, SKUs e CTA contextual', () {
    final screen = File(
      'lib/features/assinatura/screens/assinatura_screen.dart',
    ).readAsStringSync();

    expect(screen, contains('_AssinaturaHero'));
    expect(screen, contains('_PlanSegmentBar'));
    expect(screen, contains('_PremiumPlanShowcase'));
    expect(screen, contains('_TrustStrip'));
    expect(screen, contains('_AssinaturaStickyFooter'));
    expect(screen, contains('Gerenciar assinatura'));
    expect(screen, contains('openNativeSubscriptionManagement'));
    expect(screen, contains('_shouldShowEnterpriseTrialCard'));
    expect(screen, contains('_ManageSubscriptionCard'));
    expect(screen, contains('_ActivePlanStatusChip'));
    expect(screen, contains('bottomNavigationBar'));
    expect(screen, contains('restoreAndVerifyPurchases'));
    expect(screen, contains('_BillingPeriodToggle'));
    expect(screen, contains('subscription_products.dart'));
    expect(screen, isNot(contains('class _PlanoCard')));
  });
}
