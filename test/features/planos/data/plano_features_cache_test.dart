import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

void main() {
  test('PlanoFeatures preserves cache operational metadata', () {
    final cachedAt = DateTime.utc(2026, 4, 28, 18, 0);
    final features = PlanoFeatures.fromJson({
      'plano': 'PREMIUM',
      'fromCache': true,
      'cacheSavedAt': cachedAt.toIso8601String(),
      'syncWarning': 'Usando plano salvo.',
      'features': {
        'financeiro': true,
        'agenda': true,
        'relatorios': false,
        'whiteLabel': true,
        'iaCopiloto': true,
        'iaIlimitada': false,
      },
    });

    expect(features.plano, SubscriptionPlan.PREMIUM);
    expect(features.fromCache, isTrue);
    expect(features.cacheSavedAt, cachedAt);
    expect(features.syncWarning, 'Usando plano salvo.');
    expect(features.financeiro, isTrue);
    expect(features.iaIlimitada, isFalse);
  });

  test('PlanoFeatures can mark stale refresh without changing entitlements', () {
    const fresh = PlanoFeatures(
      plano: SubscriptionPlan.ENTERPRISE,
      financeiro: true,
      agenda: true,
      relatorios: true,
      whiteLabel: true,
      iaCopiloto: true,
      iaIlimitada: true,
    );

    final stale = fresh.copyWithOperationalState(
      fromCache: true,
      syncWarning: 'Mantivemos o ultimo acesso salvo.',
    );

    expect(stale.plano, SubscriptionPlan.ENTERPRISE);
    expect(stale.fromCache, isTrue);
    expect(stale.whiteLabel, isTrue);
    expect(stale.syncWarning, contains('ultimo acesso'));
  });
}
