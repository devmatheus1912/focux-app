import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';
import 'package:focux_app/features/subscription/plan_entitlements.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';

void main() {
  test('capabilityFromFeatureLabel maps landing editor to landingCompleta', () {
    expect(
      PlanEntitlements.capabilityFromFeatureLabel(
        'Editor completo — depoimentos, galeria e FAQ',
      ),
      'landingCompleta',
    );
  });

  test('resolveUpgradeTarget for Enterprise blocked landing points to Pro', () {
    final usage = PlanEntitlements.snapshotFrom(
      plano: SubscriptionPlan.ENTERPRISE,
      alunosAtivos: 10,
      limiteAlunos: null,
      iaUsadaMes: 0,
      limiteIaMensal: 600,
    );
    final target = PlanEntitlements.resolveUpgradeTarget(
      usage: usage,
      blockedFeatureLabel: 'Editor completo — depoimentos, galeria e FAQ',
    );
    expect(target, SubscriptionPlan.ENTERPRISE);
  });

  test('snapshot uses billing tier for unlimited alunos when API says FREE', () {
    final usage = PlanEntitlements.snapshotFrom(
      plano: SubscriptionPlan.FREE,
      billingPlan: SubscriptionPlan.ENTERPRISE,
      serverPlano: SubscriptionPlan.FREE,
      alunosAtivos: 0,
      limiteAlunos: 5,
      iaUsadaMes: 0,
      limiteIaMensal: 0,
    );
    expect(usage.plano, SubscriptionPlan.ENTERPRISE);
    expect(usage.limiteAlunos, isNull);
    expect(usage.planMismatch, isTrue);
    expect(usage.limiteIaMensal, 600);
  });

  test('capabilityFromBackendFeature mapeia o enum do contrato', () {
    expect(
      PlanEntitlements.capabilityFromBackendFeature('FEEDBACK_VIDEO'),
      'feedbackVideo',
    );
    expect(
      PlanEntitlements.capabilityFromBackendFeature('ia_copiloto'),
      'iaCopiloto',
    );
    expect(
      PlanEntitlements.capabilityFromBackendFeature('FEATURE_INEXISTENTE'),
      isNull,
    );
  });

  test('upgradePlano do servidor vence o mapa local de capability', () {
    // Loja digital é Enterprise no mapa local. Se o servidor mandar PRO,
    // a sheet oferece PRO — senão o app ignora o campo que o contrato
    // existe para carregar.
    final fromServer = PlanEntitlements.lockedOffer(
      featureName: 'Loja digital',
      capability: 'lojaDigital',
      upgradePlano: SubscriptionPlan.PRO,
    );
    expect(fromServer.targetPlan, SubscriptionPlan.PRO);
  });

  test('sem upgradePlano, feedbackVideo é Pro e LEADS/NFSE seguem o contrato', () {
    final feedback = PlanEntitlements.lockedOffer(
      featureName: 'Feedback em vídeo',
      capability: 'feedbackVideo',
    );
    expect(feedback.targetPlan, SubscriptionPlan.PRO);

    expect(
      PlanEntitlements.targetPlan(capability: 'leads'),
      SubscriptionPlan.PRO,
    );
    expect(
      PlanEntitlements.targetPlan(capability: 'nfse'),
      SubscriptionPlan.ENTERPRISE,
    );
  });

  test('oferta bloqueada não cita estatística sem base', () {
    const caps = [
      'financeiro',
      'iaCopiloto',
      'landingCompleta',
      'whiteLabel',
      'relatorios',
      'migracaoFoto',
      'agenda',
      'habitCoaching',
      'comunidadePrivada',
      'automacoes',
      'automacoesAvancadas',
      'comunidadeGrupos',
      'equipeRbac',
      'lojaDigital',
      'feedbackVideo',
      'leads',
      'nfse',
    ];
    for (final cap in caps) {
      final offer = PlanEntitlements.lockedOffer(
        featureName: cap,
        capability: cap,
      );
      expect(offer.body, isNot(contains('%')), reason: cap);
      expect(offer.body, isNot(contains('R\$')), reason: cap);
    }
    expect(
      PlanEntitlements.lockedOffer(
        featureName: 'Hábitos',
        capability: 'habitCoaching',
      ).body,
      contains('Hábitos diários'),
    );
  });

  test('alignedToBilling elevates FREE /me to Enterprise limits', () {
    const me = PlanoFeatures(
      plano: SubscriptionPlan.FREE,
      financeiro: false,
      agenda: true,
      relatorios: false,
      whiteLabel: false,
      iaCopiloto: false,
      migracaoFoto: false,
      limiteAlunos: 5,
      limiteIaMensal: 0,
    );
    final aligned = me.alignedToBilling(SubscriptionPlan.ENTERPRISE);
    expect(aligned.plano, SubscriptionPlan.ENTERPRISE);
    expect(aligned.limiteAlunos, isNull);
    expect(aligned.limiteIaMensal, 600);
    expect(aligned.whiteLabel, isTrue);
  });
}
