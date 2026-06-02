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
      limiteIaMensal: 400,
    );
    final target = PlanEntitlements.resolveUpgradeTarget(
      usage: usage,
      blockedFeatureLabel: 'Editor completo — depoimentos, galeria e FAQ',
    );
    expect(target, SubscriptionPlan.ENTERPRISE_PRO);
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
    expect(usage.limiteIaMensal, 400);
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
    expect(aligned.limiteIaMensal, 400);
    expect(aligned.whiteLabel, isTrue);
  });
}
