import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/assinatura/utils/assinatura_review_display.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';
import 'package:focux_app/features/subscription/subscription_products.dart';

void main() {
  test('review S6 formata próxima cobrança e não ecoa erro cru da loja', () {
    final next = assinaturaReviewNextBill(
      DateTime(2026, 9, 2),
      SubscriptionBillingPeriod.monthly,
    );
    expect(next, DateTime(2026, 10, 2));
    expect(assinaturaReviewPlanLabel(SubscriptionPlan.PRO), isNotEmpty);
    expect(assinaturaStoreFailureCopy(), isNot(contains('BillingResponse')));
    expect(assinaturaStoreFailureCopy(), isNot(contains('SKError')));
  });

  test('com teste a cobrança vem no fim dele, mesmo no anual', () {
    final agora = DateTime(2026, 10, 30);
    expect(
      assinaturaReviewNextBill(
        agora,
        SubscriptionBillingPeriod.yearly,
        trialDias: 30,
      ),
      DateTime(2026, 11, 29),
    );
    expect(
      assinaturaReviewLinhas(
        now: agora,
        period: SubscriptionBillingPeriod.monthly,
        price: 'R\$ 99,90/mês',
        trialDias: 30,
      ).map((l) => '${l.quando} ${l.valor}'),
      ['Hoje R\$ 0,00', '29/11/2026 R\$ 99,90/mês'],
    );
    expect(
      assinaturaReviewLinhas(
        now: agora,
        period: SubscriptionBillingPeriod.monthly,
        price: 'R\$ 99,90/mês',
      ).first.valor,
      'R\$ 99,90/mês',
    );
  });

  test('botão diz o que acontece', () {
    expect(
      assinaturaReviewConfirmLabel(price: 'R\$ 99,90/mês', trialDias: 30),
      'Começar 30 dias grátis',
    );
    expect(
      assinaturaReviewConfirmLabel(price: 'R\$ 99,90/mês'),
      'Assinar por R\$ 99,90/mês',
    );
  });
}
