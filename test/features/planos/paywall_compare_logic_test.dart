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
    expect(view.rows.length, PaywallCatalog.comparisonFreeVsPro.length);
  });

  test('aba Pro compara Free x Pro e muda o título', () {
    final view = buildPaywallCompareView(
      selected: SubscriptionPlan.PRO,
      current: SubscriptionPlan.FREE,
    );
    expect(view.headline, 'Assinar Pro');
    expect(view.showTwoColumns, isTrue);
    expect(view.showBillingToggle, isTrue);
    expect(view.baselineColumnLabel, 'Free');
    expect(view.selectedColumnLabel, 'Pro');

    final pix = view.rows.firstWhere((r) => r.feature.contains('PIX'));
    expect(paywallCompareCellIncluded(pix.baseline), isFalse);
    expect(pix.selected, '✓');

    final extra = view.rows.firstWhere(
      (r) => r.feature.toLowerCase().contains('white-label'),
    );
    expect(extra.selected, '—');
  });

  test('aba Enterprise compara Free x Enterprise', () {
    final view = buildPaywallCompareView(
      selected: SubscriptionPlan.ENTERPRISE,
      current: SubscriptionPlan.PRO,
    );
    expect(view.headline, 'Assinar Enterprise');
    expect(view.selectedColumnLabel, 'Enterprise');
    expect(paywallTabLabel(SubscriptionPlan.ENTERPRISE), 'Enterprise');

    final pose = view.rows.firstWhere((r) => r.feature == 'Pose Coach');
    expect(pose.selected, '✓');
    expect(view.rows.any((r) => r.feature.contains('✦')), isFalse);
  });

  test('managementMode no plano atual esconde billing e muda subtítulo', () {
    final view = buildPaywallCompareView(
      selected: SubscriptionPlan.ENTERPRISE,
      current: SubscriptionPlan.ENTERPRISE,
      managementMode: true,
    );
    expect(view.headline, 'Seu plano Enterprise');
    expect(view.showBillingToggle, isFalse);
    expect(
      view.subtitle,
      'Status, cobrança na loja e cancelamento — sem vitrine de upgrade.',
    );
  });
}
