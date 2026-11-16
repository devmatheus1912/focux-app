import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/planos/paywall/paywall_catalog.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

void main() {
  test('comparisons binárias batem com a spec', () {
    expect(PaywallCatalog.comparisonFreeVsPro.length, 11);
    expect(PaywallCatalog.comparisonFreeVsEnterprise.length, 14);
    final rotulos = [
      ...PaywallCatalog.comparisonFreeVsPro,
      ...PaywallCatalog.comparisonFreeVsEnterprise,
    ].map((r) => r.feature).join(' | ');
    expect(rotulos, isNot(contains('CRM')));
    expect(rotulos, contains('Hoje com o Índice Focux'));
    // SPEC 12/11: nomes do app, sem inglês nem nome velho.
    for (final velho in ['Copiloto', 'landing', 'win-back', 'Loja de pacotes']) {
      expect(rotulos, isNot(contains(velho)), reason: velho);
    }
    expect(
      PaywallCatalog.comparisonProVsEnterprise.where((r) => r.free == r.paid),
      isEmpty,
    );
  });

  test('upgradeTriggers match reference', () {
    expect(PaywallCatalog.upgradeTriggers.length, 8);
  });

  test('displayPlanName usa o nome de vitrine', () {
    expect(PaywallCatalog.displayPlanName(SubscriptionPlan.PRO), 'Pro');
    expect(
      PaywallCatalog.displayPlanName(SubscriptionPlan.ENTERPRISE),
      'Enterprise',
    );
  });

  test('gatilhos de upgrade sem preço fixo nem estatística sem base', () {
    final textos = [
      for (final t in PaywallCatalog.upgradeTriggers) t.message,
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
      contains('analisa cada aluno'),
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
      // "landing" virou "página de vendas" (15/11).
      contains('página de vendas'),
    );
    expect(PaywallCatalog.modalMessageFor(capability: 'agenda'), isNull);
  });
}
