import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/planos/utils/plano_capability.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

void main() {
  PlanoFeatures featuresFor(SubscriptionPlan plan) =>
      PlanoFeatures.free.alignedToBilling(plan);

  test('leads libera PRO e Enterprise; bloqueia Free', () {
    expect(PlanoCapability.has(featuresFor(SubscriptionPlan.FREE), 'leads'), isFalse);
    expect(PlanoCapability.has(featuresFor(SubscriptionPlan.PRO), 'leads'), isTrue);
    expect(
      PlanoCapability.has(featuresFor(SubscriptionPlan.ENTERPRISE), 'leads'),
      isTrue,
    );
  });

  test('nfse só libera Enterprise', () {
    expect(PlanoCapability.has(featuresFor(SubscriptionPlan.FREE), 'nfse'), isFalse);
    expect(PlanoCapability.has(featuresFor(SubscriptionPlan.PRO), 'nfse'), isFalse);
    expect(
      PlanoCapability.has(featuresFor(SubscriptionPlan.ENTERPRISE), 'nfse'),
      isTrue,
    );
  });
}
