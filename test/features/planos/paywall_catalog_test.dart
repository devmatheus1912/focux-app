import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/planos/paywall/paywall_catalog.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

void main() {
  test('comparisons binárias batem com a spec', () {
    expect(PaywallCatalog.comparisonFreeVsPro.length, 6);
    expect(PaywallCatalog.comparisonFreeVsEnterprise.length, 9);
  });

  test('upgradeTriggers match reference', () {
    expect(PaywallCatalog.upgradeTriggers.length, 8);
  });

  test('displayPlanName usa o nome canônico', () {
    expect(PaywallCatalog.displayPlanName(SubscriptionPlan.PRO), 'PRO');
    expect(
      PaywallCatalog.displayPlanName(SubscriptionPlan.ENTERPRISE),
      'ENTERPRISE',
    );
  });

  test('roi tags omit emoji prefix', () {
    final tag = PaywallCatalog.roiTagForPlan(SubscriptionPlan.PRO);
    expect(tag, isNotNull);
    expect(tag!, isNot(startsWith('💰')));
  });

  test('parseFeatureLabel strips pro markers', () {
    final a = PaywallCatalog.parseFeatureLabel('Pose Coach ML ✦');
    expect(a.label, 'Pose Coach ML');
    expect(a.pro, isTrue);
    final b = PaywallCatalog.parseFeatureLabel('30 alunos ativos');
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
