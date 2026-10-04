import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/planos/paywall/paywall_components.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';
import 'package:focux_app/features/subscription/plan_entitlements.dart';

PlanoUsageSnapshot _uso({
  SubscriptionPlan plano = SubscriptionPlan.FREE,
  int alunos = 0,
  int? limite = 3,
}) => PlanoUsageSnapshot(
  plano: plano,
  alunosAtivos: alunos,
  limiteAlunos: limite,
  iaUsadaMes: 0,
  limiteIaMensal: 0,
);

void main() {
  test('limite de alunos atingido não promete faturamento', () {
    final msg = paywallContextMessage(
      usage: _uso(alunos: 3),
      target: SubscriptionPlan.PRO,
    );
    expect(
      msg,
      'Você atingiu 3 alunos, o limite do seu plano. O Pro libera até 30 alunos.',
    );
    expect(
      paywallContextMessage(
        usage: _uso(plano: SubscriptionPlan.PRO, alunos: 30, limite: 30),
        target: SubscriptionPlan.ENTERPRISE,
      ),
      'Você atingiu 30 alunos, o limite do seu plano. Enterprise libera alunos ilimitados.',
    );
  });

  test('Free sem gatilho descreve o Pro com limites reais', () {
    final msg = paywallContextMessage(
      usage: _uso(alunos: 0),
      target: SubscriptionPlan.PRO,
    );
    expect(msg, isNotNull);
    expect(msg, isNot(contains('R\$')));
    expect(msg, isNot(contains('%')));
    expect(msg, contains('30 alunos'));
  });

  test('recurso bloqueado cita o plano de destino', () {
    expect(
      paywallContextMessage(
        usage: _uso(),
        blockedFeatureLabel: 'PIX',
        target: SubscriptionPlan.PRO,
      ),
      'PIX está no plano Pro.',
    );
  });
}
