import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/planos/paywall/paywall_catalog.dart';
import 'package:focux_app/features/planos/paywall/paywall_vitrine.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

void main() {
  test('fromApi parses social proof', () {
    final snapshot = PaywallVitrineSnapshot.fromApi({
      'socialProof': [
        {'value': '100', 'label': 'test'},
      ],
    });
    expect(snapshot.socialProof, [(value: '100', label: 'test')]);
  });

  test('fromApi falls back when empty', () {
    final snapshot = PaywallVitrineSnapshot.fromApi({'socialProof': []});
    expect(snapshot.socialProof, PaywallCatalog.socialProof);
  });

  test('fromApi parses roi strip and trial offer', () {
    final snapshot = PaywallVitrineSnapshot.fromApi({
      'socialProof': [
        {'value': '1', 'label': 'x'},
      ],
      'roiStrip': [
        {'value': '5×', 'label': 'ROI', 'tone': 'brand'},
      ],
      'trialDaysOffer': 30,
    });
    expect(snapshot.fromApi, isTrue);
    expect(snapshot.trialDaysOffer, 30);
    expect(snapshot.effectiveRoiStrip.first.value, '5×');
  });

  test('fromApi parses comparisons binárias Free × plano', () {
    final snapshot = PaywallVitrineSnapshot.fromApi({
      'comparisonFreeVsPro': [
        {'feature': 'PIX / financeiro', 'free': '—', 'paid': '✓'},
      ],
      'comparisonFreeVsEnterprise': [
        {'feature': 'Landing + loja', 'free': '—', 'paid': '✓'},
      ],
      'version': '2026-08-24',
    });
    expect(snapshot.fromApi, isTrue);
    expect(snapshot.rowsFor(SubscriptionPlan.PRO).first.feature, 'PIX / financeiro');
    expect(snapshot.rowsFor(SubscriptionPlan.PRO).first.paid, '✓');
    expect(
      snapshot.rowsFor(SubscriptionPlan.ENTERPRISE).first.feature,
      'Landing + loja',
    );
    expect(snapshot.rowsFor(SubscriptionPlan.ENTERPRISE).first.paid, '✓');
  });
}
