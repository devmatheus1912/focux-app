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
    expect(
      assinaturaReviewNextBillLabel(DateTime(2026, 10, 2)),
      'Próxima cobrança estimada: 02/10/2026',
    );
    expect(assinaturaReviewPlanLabel(SubscriptionPlan.PRO), isNotEmpty);
    expect(assinaturaStoreFailureCopy(), isNot(contains('BillingResponse')));
    expect(assinaturaStoreFailureCopy(), isNot(contains('SKError')));
  });
}
