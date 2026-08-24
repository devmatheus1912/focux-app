import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/planos/paywall/paywall_catalog.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

void main() {
  test('comparison table matches reference row count', () {
    expect(PaywallCatalog.comparisonRows.length, 14);
  });

  test('roi strip match reference', () {
    expect(PaywallCatalog.roiStrip.length, 6);
    expect(PaywallCatalog.upgradeTriggers.length, 8); // modais in-app, não vitrine
  });

  test('displayPlanName formats ENTERPRISE PRO', () {
    expect(
      PaywallCatalog.displayPlanName(SubscriptionPlan.ENTERPRISE_PRO),
      'ENTERPRISE PRO',
    );
  });

  test('badge de 30 dias só no Pro', () {
    expect(PaywallCatalog.badgeForPlan(SubscriptionPlan.ENTERPRISE), isNull);
    expect(
      PaywallCatalog.badgeForPlan(SubscriptionPlan.ENTERPRISE_PRO),
      'TRIAL 30 DIAS',
    );
  });

  test('roi tags omit emoji prefix', () {
    final tag = PaywallCatalog.roiTagForPlan(SubscriptionPlan.PREMIUM);
    expect(tag, isNotNull);
    expect(tag!, isNot(startsWith('💰')));
  });

  test('parseFeatureLabel strips pro markers', () {
    final a = PaywallCatalog.parseFeatureLabel('Pose Coach ML ✦');
    expect(a.label, 'Pose Coach ML');
    expect(a.pro, isTrue);
    final b = PaywallCatalog.parseFeatureLabel('20 alunos ativos');
    expect(b.pro, isFalse);
  });

  test('modalMessageFor maps capabilities to trigger copy', () {
    expect(
      PaywallCatalog.modalMessageFor(capability: 'financeiro'),
      contains('inadimplência'),
    );
    expect(
      PaywallCatalog.modalMessageFor(capability: 'iaCopiloto'),
      contains('IA está aguardando'),
    );
    expect(
      PaywallCatalog.modalMessageFor(
        capability: 'iaCopiloto',
        featureName: 'Cota de IA esgotada',
      ),
      contains('limite de IA'),
    );
    expect(
      PaywallCatalog.modalMessageFor(capability: 'whiteLabel'),
      contains('SEU logo'),
    );
    expect(
      PaywallCatalog.modalMessageFor(capability: 'landingCompleta'),
      contains('landing'),
    );
    expect(PaywallCatalog.modalMessageFor(capability: 'agenda'), isNull);
  });
}
