import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/planos/paywall/paywall_catalog.dart';
import 'package:focux_app/features/planos/paywall/paywall_vitrine.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

void main() {
  test('fromApi falls back to catalog when comparisons empty', () {
    final snapshot = PaywallVitrineSnapshot.fromApi({});
    expect(
      snapshot.rowsFor(SubscriptionPlan.PRO).length,
      PaywallCatalog.comparisonFreeVsPro.length,
    );
  });

  test('fromApi parses comparisons binárias Free × plano', () {
    final snapshot = PaywallVitrineSnapshot.fromApi({
      'comparisonFreeVsPro': [
        {'feature': 'PIX / financeiro', 'free': '—', 'paid': '✓'},
      ],
      'comparisonFreeVsEnterprise': [
        {'feature': 'Landing + loja', 'free': '—', 'paid': '✓'},
      ],
    });
    expect(snapshot.rowsFor(SubscriptionPlan.PRO).first.feature, 'PIX / financeiro');
    expect(snapshot.rowsFor(SubscriptionPlan.PRO).first.paid, '✓');
    expect(
      snapshot.rowsFor(SubscriptionPlan.ENTERPRISE).first.feature,
      'Landing + loja',
    );
    expect(snapshot.rowsFor(SubscriptionPlan.ENTERPRISE).first.paid, '✓');
  });
}
