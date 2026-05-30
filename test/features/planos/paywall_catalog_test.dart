import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/assinatura/data/plano.dart';
import 'package:focux_app/features/planos/paywall/paywall_catalog.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

Plano _mockPlano(String nome, {int? limite}) {
  final ent = nome.contains('ENTERPRISE');
  return Plano(
    id: 1,
    nome: nome,
    precoMensal: 79,
    precoAnual: 948,
    limiteAlunos: limite,
    temFinanceiro: nome != 'FREE',
    temAgenda: true,
    temRelatorios: nome != 'FREE',
    temWhiteLabel: ent,
    temLandingCompleta: nome.contains('PRO'),
  );
}

void main() {
  test('comparison table matches reference row count', () {
    expect(PaywallCatalog.comparisonRows.length, 14);
  });

  test('roi strip and rows match reference', () {
    expect(PaywallCatalog.roiStrip.length, 6);
    expect(PaywallCatalog.roiRows.length, 10);
    expect(PaywallCatalog.topFeatures.length, 10);
    expect(PaywallCatalog.upgradeTriggers.length, 8); // modais in-app, não vitrine
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

  test('parseFeatureLabel strips pro markers', () {
    final a = PaywallCatalog.parseFeatureLabel('Pose Coach ML ✦');
    expect(a.label, 'Pose Coach ML');
    expect(a.pro, isTrue);
    final b = PaywallCatalog.parseFeatureLabel('20 alunos ativos');
    expect(b.pro, isFalse);
  });

  test('plan cards expose collapsible feature sections', () {
    final free = PaywallCatalog.featureSectionsForPlan(
      _mockPlano('FREE', limite: 5),
      SubscriptionPlan.FREE,
    );
    expect(free.length, 2);
    expect(free.first.collapsible, isFalse);
    expect(free.last.collapsible, isTrue);
    expect(free.last.title, 'Bloqueado no FREE');

    final premium = PaywallCatalog.featureSectionsForPlan(
      _mockPlano('PREMIUM', limite: 20),
      SubscriptionPlan.PREMIUM,
    );
    expect(premium.length, 3);
    expect(premium.where((s) => s.collapsible).length, 2);

    final entPro = PaywallCatalog.featureSectionsForPlan(
      _mockPlano('ENTERPRISE_PRO'),
      SubscriptionPlan.ENTERPRISE_PRO,
    );
    expect(entPro.length, 3);
    expect(entPro.any((s) => s.title.contains('Landing')), isTrue);

    final enterprise = PaywallCatalog.featureSectionsForPlan(
      _mockPlano('ENTERPRISE'),
      SubscriptionPlan.ENTERPRISE,
    );
    expect(
      enterprise.any((s) => s.title.contains('Landing page · Enterprise Pro')),
      isTrue,
    );
    expect(
      enterprise
          .expand((s) => s.items)
          .any((i) => i.label.contains('Editor completo') && !i.included),
      isTrue,
    );
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
