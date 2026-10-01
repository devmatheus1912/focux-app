import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/planos/paywall/paywall_catalog.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

void main() {
  test('comparisons binárias batem com a spec', () {
    expect(PaywallCatalog.comparisonFreeVsPro.length, 7);
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

  test('tags do plano descrevem limites reais, sem ROI inventado', () {
    expect(
      PaywallCatalog.roiTagForPlan(SubscriptionPlan.PRO),
      'Até 30 alunos, 200 usos de IA/mês e cobrança PIX',
    );
    expect(
      PaywallCatalog.roiTagForPlan(SubscriptionPlan.ENTERPRISE),
      'Marca própria, landing, loja e até 5 assistentes além de você',
    );
    expect(PaywallCatalog.roiTagForPlan(SubscriptionPlan.FREE), isNull);
  });

  test('gatilhos de upgrade sem preço fixo nem estatística sem base', () {
    final textos = [
      for (final t in PaywallCatalog.upgradeTriggers) t.message,
      PaywallCatalog.roiTagForPlan(SubscriptionPlan.PRO)!,
      PaywallCatalog.roiTagForPlan(SubscriptionPlan.ENTERPRISE)!,
    ];
    for (final texto in textos) {
      expect(texto, isNot(contains('R\$')), reason: texto);
      expect(texto, isNot(contains('%')), reason: texto);
      expect(texto, isNot(contains('falta de aluno')), reason: texto);
      expect(texto, isNot(contains('agência')), reason: texto);
      expect(texto, isNot(contains('3 minutos')), reason: texto);
    }
    expect(
      PaywallCatalog.modalMessageFor(capability: 'financeiro'),
      contains('PIX'),
    );
  });

  test('parseFeatureLabel strips pro markers', () {
    final a = PaywallCatalog.parseFeatureLabel('Feedback em vídeo ML ✦');
    expect(a.label, 'Feedback em vídeo ML');
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
