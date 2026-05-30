import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

void main() {
  test('ENTERPRISE tier ceiling bloqueia flags Pro mesmo com API inflada', () {
    const inflated = PlanoFeatures(
      plano: SubscriptionPlan.ENTERPRISE,
      financeiro: true,
      agenda: true,
      relatorios: true,
      whiteLabel: true,
      iaCopiloto: true,
      migracaoFoto: true,
      landingCompleta: true,
      habitCoaching: true,
      comunidadePrivada: true,
      automacoes: true,
      automacoesAvancadas: true,
      comunidadeGrupos: true,
      equipeRbac: true,
      lojaDigital: true,
      poseCoach: true,
      limiteAssistentes: 99,
    );

    final capped = inflated.withTierCeiling();

    expect(capped.landingCompleta, isFalse);
    expect(capped.lojaDigital, isFalse);
    expect(capped.poseCoach, isFalse);
    expect(capped.automacoesAvancadas, isFalse);
    expect(capped.automacoes, isTrue);
    expect(capped.equipeRbac, isTrue);
    expect(capped.limiteAssistentes, 1);
  });

  test('fromJson aplica tier ceiling para ENTERPRISE', () {
    final features = PlanoFeatures.fromJson({
      'plano': 'ENTERPRISE',
      'features': {
        'financeiro': true,
        'agenda': true,
        'relatorios': true,
        'whiteLabel': true,
        'landingCompleta': true,
        'lojaDigital': true,
        'poseCoach': true,
        'automacoes': true,
        'habitCoaching': true,
      },
    });

    expect(features.plano, SubscriptionPlan.ENTERPRISE);
    expect(features.landingCompleta, isFalse);
    expect(features.lojaDigital, isFalse);
    expect(features.poseCoach, isFalse);
  });

  test('PREMIUM tier ceiling bloqueia Enterprise e Pro', () {
    const premium = PlanoFeatures(
      plano: SubscriptionPlan.PREMIUM,
      financeiro: true,
      agenda: true,
      relatorios: true,
      whiteLabel: true,
      iaCopiloto: true,
      migracaoFoto: true,
      automacoes: true,
      lojaDigital: true,
      landingCompleta: true,
    );

    final capped = premium.withTierCeiling();

    expect(capped.whiteLabel, isFalse);
    expect(capped.automacoes, isFalse);
    expect(capped.lojaDigital, isFalse);
    expect(capped.landingCompleta, isFalse);
    expect(capped.financeiro, isTrue);
  });
}
