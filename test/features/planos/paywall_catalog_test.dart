import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/assinatura/data/assinatura_repository.dart';
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
  });
}
