import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/planos/paywall/paywall_catalog.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

void main() {
  test('comparison table matches reference row count', () {
    expect(PaywallCatalog.comparisonRows.length, 14);
  });

  test('roi strip and rows match reference', () {
    expect(PaywallCatalog.roiStrip.length, 6);
    expect(PaywallCatalog.roiRows.length, 10);
    expect(PaywallCatalog.topFeatures.length, 10);
    expect(PaywallCatalog.upgradeTriggers.length, 8);
  });

  test('displayPlanName formats ENTERPRISE PRO', () {
    expect(
      PaywallCatalog.displayPlanName(SubscriptionPlan.ENTERPRISE_PRO),
      'ENTERPRISE PRO',
    );
  });

  test('roi tags omit emoji prefix', () {
    final tag = PaywallCatalog.roiTagForPlan(SubscriptionPlan.PREMIUM);
    expect(tag, isNotNull);
    expect(tag!, isNot(startsWith('💰')));
  });
}
