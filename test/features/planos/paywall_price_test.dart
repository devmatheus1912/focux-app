import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/planos/paywall/paywall_price.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';
import 'package:focux_app/features/subscription/subscription_products.dart';

void main() {
  test('FREE fica Grátis', () {
    final copy = buildPaywallPriceCopy(
      precoMensal: 0,
      period: SubscriptionBillingPeriod.monthly,
    );
    expect(copy.primary, 'Grátis');
    expect(copy.secondary, isNull);
  });

  test('mensal usa BFF quando a loja não veio', () {
    final copy = buildPaywallPriceCopy(
      precoMensal: 99,
      period: SubscriptionBillingPeriod.monthly,
    );
    expect(copy.primary, 'R\$ 99,00/mês');
    expect(copy.secondary, isNull);
  });

  test('anual mostra total e equivalente mensal', () {
    final copy = buildPaywallPriceCopy(
      precoMensal: 100,
      precoAnual: 960,
      precoAnualMensalEquiv: 80,
      period: SubscriptionBillingPeriod.yearly,
    );
    expect(copy.primary, 'R\$ 960,00/ano');
    expect(copy.secondary, 'Equiv. R\$ 80,00/mês');
  });

  test('loja ganha do catálogo', () {
    final copy = buildPaywallPriceCopy(
      precoMensal: 99,
      period: SubscriptionBillingPeriod.monthly,
      storePrice: 'R\$ 89,90',
    );
    expect(copy.primary, 'R\$ 89,90/mês');
  });

  test('30 dias só no Pro para conta FREE', () {
    expect(
      paywallShowsMaxPlanTrial(
        selected: SubscriptionPlan.ENTERPRISE_PRO,
        current: SubscriptionPlan.FREE,
      ),
      isTrue,
    );
    expect(
      paywallShowsMaxPlanTrial(
        selected: SubscriptionPlan.ENTERPRISE,
        current: SubscriptionPlan.FREE,
      ),
      isFalse,
    );
    expect(
      paywallShowsMaxPlanTrial(
        selected: SubscriptionPlan.ENTERPRISE_PRO,
        current: SubscriptionPlan.PREMIUM,
      ),
      isFalse,
    );
    expect(
      paywallShowsMaxPlanTrial(
        selected: SubscriptionPlan.ENTERPRISE_PRO,
        current: SubscriptionPlan.FREE,
        trialEligible: false,
      ),
      isFalse,
    );
    expect(kPaywallMaxPlanTrialDays, 30);
  });
}
