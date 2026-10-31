import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/utils/ia_cota.dart';
import 'package:focux_app/features/planos/paywall/paywall_catalog.dart';
import 'package:focux_app/features/planos/paywall/paywall_compare_logic.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';
import 'package:focux_app/features/subscription/plan_entitlements.dart';

void main() {
  test('cota volta no dia 1, inclusive na virada do ano', () {
    expect(iaCotaVoltaEm(DateTime(2026, 10, 31)), DateTime(2026, 11));
    expect(iaCotaVoltaEm(DateTime(2026, 12, 15)), DateTime(2027));
    expect(iaCotaVoltaLabel(DateTime(2026, 10, 31)), '01/11');
  });

  test('tom da barra', () {
    expect(iaCotaTom(usado: 42, limite: 600), IaCotaTom.normal);
    expect(iaCotaTom(usado: 480, limite: 600), IaCotaTom.atencao);
    expect(iaCotaTom(usado: 600, limite: 600), IaCotaTom.esgotada);
    expect(iaCotaTom(usado: 0, limite: 0), IaCotaTom.normal);
  });

  test('texto da barra', () {
    expect(
      iaCotaUsoTexto(usado: 42, limite: 600, agora: DateTime(2026, 10, 31)),
      '42 de 600 usos de IA · volta em 01/11',
    );
  });

  test('Enterprise esgotado diz quando volta e não vende nada', () {
    final offer = PlanEntitlements.iaQuotaUpgradeOffer(
      currentPlan: SubscriptionPlan.ENTERPRISE,
      limiteAtual: 600,
      agora: DateTime(2026, 10, 31),
    );
    expect(offer.targetPlan, isNull);
    expect(offer.body, 'Seus 600 usos de IA acabaram. Voltam em 01/11.');
  });

  test('Pro esgotado diz quando volta e oferece Enterprise', () {
    final offer = PlanEntitlements.iaQuotaUpgradeOffer(
      currentPlan: SubscriptionPlan.PRO,
      limiteAtual: 200,
      agora: DateTime(2026, 10, 31),
    );
    expect(offer.targetPlan, SubscriptionPlan.ENTERPRISE);
    expect(offer.body, contains('Voltam em 01/11'));
  });

  test('inclusos trazem o valor, com número primeiro', () {
    expect(paywallInclusos(PaywallCatalog.comparisonFreeVsEnterprise).take(3), [
      'Alunos sem limite',
      'Copiloto IA: 600 por mês',
      'Importação por foto: 80 por mês',
    ]);
  });
}
