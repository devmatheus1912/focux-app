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
      'socialProof': [{'value': '1', 'label': 'x'}],
      'roiStrip': [
        {'value': '5×', 'label': 'ROI', 'tone': 'brand'},
      ],
      'trialDaysOffer': 30,
    });
    expect(snapshot.fromApi, isTrue);
    expect(snapshot.trialDaysOffer, 30);
    expect(snapshot.effectiveRoiStrip.first.value, '5×');
  });

  test('fromApi parses comparison rows from vitrine', () {
    final snapshot = PaywallVitrineSnapshot.fromApi({
      'comparisonRows': [
        {
          'feature': 'Landing page COMPLETA',
          'free': '—',
          'premium': '—',
          'enterprise': '—',
          'enterprisePro': '✓',
        },
      ],
      'version': '2026-05-30',
    });
    expect(snapshot.fromApi, isTrue);
    expect(snapshot.effectiveComparisonRows.first.feature, 'Landing page COMPLETA');
    expect(
      snapshot.effectiveComparisonRows.first.valueFor(
        SubscriptionPlan.ENTERPRISE_PRO,
      ),
      '✓',
    );
  });
}
