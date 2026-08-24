import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/planos/paywall/paywall_catalog.dart';
import 'package:focux_app/features/planos/paywall/paywall_compare_logic.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

void main() {
  test('FREE selecionado vira um card, sem coluna extra', () {
    final view = buildPaywallCompareView(
      selected: SubscriptionPlan.FREE,
      current: SubscriptionPlan.FREE,
    );
    expect(view.headline, 'Seu plano FREE');
    expect(view.showTwoColumns, isFalse);
    expect(view.showBillingToggle, isFalse);
    expect(view.rows.length, PaywallCatalog.comparisonRows.length);
  });

  test('aba Premium compara Free x Premium e muda o título', () {
    final view = buildPaywallCompareView(
      selected: SubscriptionPlan.PREMIUM,
      current: SubscriptionPlan.FREE,
    );
    expect(view.headline, 'Assinar Premium');
    expect(view.showTwoColumns, isTrue);
    expect(view.showBillingToggle, isTrue);
    expect(view.baselineColumnLabel, 'Free');
    expect(view.selectedColumnLabel, 'Premium');

    final pix = view.rows.firstWhere((r) => r.feature == 'PIX + QR Code');
    expect(paywallCompareCellIncluded(pix.baseline), isFalse);
    expect(pix.selected, '✓');
  });

  test('upgrade a partir do Premium aponta Enterprise', () {
    final view = buildPaywallCompareView(
      selected: SubscriptionPlan.ENTERPRISE,
      current: SubscriptionPlan.PREMIUM,
    );
    expect(view.headline, 'Assinar Enterprise');
    expect(paywallTabLabel(SubscriptionPlan.ENTERPRISE_PRO), 'Pro');
  });

  test('marcador pro some do rótulo da linha', () {
    final view = buildPaywallCompareView(
      selected: SubscriptionPlan.ENTERPRISE_PRO,
      current: SubscriptionPlan.FREE,
    );
    expect(view.rows.any((r) => r.feature.contains('✦')), isFalse);
    expect(view.rows.any((r) => r.feature == 'Pose Coach ML'), isTrue);
  });
}
