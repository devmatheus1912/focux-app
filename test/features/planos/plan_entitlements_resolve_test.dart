import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';
import 'package:focux_app/features/subscription/plan_entitlements.dart';

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
}
