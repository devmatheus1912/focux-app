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
      precoMensal: 99.90,
      period: SubscriptionBillingPeriod.monthly,
    );
    expect(copy.primary, 'R\$ 99,90/mês');
    expect(copy.secondary, isNull);
  });

  test('anual mostra total, equivalente e 2 meses grátis', () {
    final copy = buildPaywallPriceCopy(
      precoMensal: 99.90,
      precoAnual: 999,
      precoAnualMensalEquiv: 83.25,
      labelDescontoAnual: '2 meses grátis',
      labelEconomiaAnual: 'Economize R\$ 199,80',
      period: SubscriptionBillingPeriod.yearly,
    );
    expect(copy.primary, 'R\$ 999,00/ano');
    expect(copy.secondary, contains('Equiv. R\$ 83,25/mês'));
    expect(copy.secondary, contains('2 meses grátis'));
    expect(copy.secondary, contains('Economize R\$ 199,80'));
  });

  test('loja ganha do catálogo', () {
    final copy = buildPaywallPriceCopy(
      precoMensal: 99.90,
      period: SubscriptionBillingPeriod.monthly,
      storePrice: 'R\$ 89,90',
    );
    expect(copy.primary, 'R\$ 89,90/mês');
  });

  test('30 dias só no Enterprise para conta FREE', () {
    expect(
      paywallShowsMaxPlanTrial(
        selected: SubscriptionPlan.ENTERPRISE,
        current: SubscriptionPlan.FREE,
      ),
      isTrue,
    );
    expect(
      paywallShowsMaxPlanTrial(
        selected: SubscriptionPlan.PRO,
        current: SubscriptionPlan.FREE,
      ),
      isFalse,
    );
    expect(
      paywallShowsMaxPlanTrial(
        selected: SubscriptionPlan.ENTERPRISE,
        current: SubscriptionPlan.PRO,
      ),
      isFalse,
    );
    expect(
      paywallShowsMaxPlanTrial(
        selected: SubscriptionPlan.ENTERPRISE,
        current: SubscriptionPlan.FREE,
        trialEligible: false,
      ),
      isFalse,
    );
    expect(kPaywallMaxPlanTrialDays, 30);
  });

  test('CTA sticky leva o preço; trial não mostra valor no botão', () {
    expect(
      paywallStickyCtaLabel(
        trialOffer: true,
        isUpgrade: true,
        planName: 'ENTERPRISE',
        pricePrimary: 'R\$ 199,90/mês',
      ),
      'Começar 30 dias grátis',
    );
    expect(
      paywallStickyCtaLabel(
        trialOffer: false,
        isUpgrade: true,
        planName: 'PRO',
        pricePrimary: 'R\$ 99,90/mês',
      ),
      'Fazer upgrade por R\$ 99,90/mês',
    );
    expect(
      paywallStickyCtaLabel(
        trialOffer: false,
        isUpgrade: false,
        planName: 'PRO',
        pricePrimary: 'R\$ 99,90/mês',
      ),
      'Assinar PRO por R\$ 99,90/mês',
    );
    expect(
      paywallStickyCtaLabel(
        trialOffer: false,
        isUpgrade: true,
        planName: 'PRO',
      ),
      'Confirmar upgrade',
    );
  });
}
