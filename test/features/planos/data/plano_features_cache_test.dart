import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

void main() {
  test('PlanoFeatures preserves cache operational metadata', () {
    final cachedAt = DateTime.utc(2026, 4, 28, 18, 0);
    final features = PlanoFeatures.fromJson({
      'plano': 'PRO',
      'fromCache': true,
      'cacheSavedAt': cachedAt.toIso8601String(),
      'syncWarning': 'Usando plano salvo.',
      'features': {
        'financeiro': true,
        'agenda': true,
        'relatorios': false,
        'whiteLabel': true,
        'iaCopiloto': true,
        'migracaoFoto': true,
      },
    });

    expect(features.plano, SubscriptionPlan.PRO);
    expect(features.fromCache, isTrue);
    expect(features.cacheSavedAt, cachedAt);
    expect(features.syncWarning, 'Usando plano salvo.');
    expect(features.financeiro, isTrue);
  });

  test('PlanoFeatures can mark stale refresh without changing entitlements', () {
    const fresh = PlanoFeatures(
      plano: SubscriptionPlan.ENTERPRISE,
      financeiro: true,
      agenda: true,
      relatorios: true,
      whiteLabel: true,
      iaCopiloto: true,
      migracaoFoto: true,
      limiteIaMensal: 400,
    );

    final stale = fresh.copyWithOperationalState(
      fromCache: true,
      syncWarning: 'Mantivemos o último acesso salvo.',
    );

    expect(stale.plano, SubscriptionPlan.ENTERPRISE);
    expect(stale.fromCache, isTrue);
    expect(stale.whiteLabel, isTrue);
    expect(stale.syncWarning, contains('último acesso'));
  });

  test('PlanoFeaturesSyncCopy distinguishes offline refresh failures', () {
    expect(
      PlanoFeaturesSyncCopy.forRefreshError(
        DioException(
          requestOptions: RequestOptions(path: '/planos/me'),
          type: DioExceptionType.connectionError,
        ),
      ),
      PlanoFeaturesSyncCopy.offlineCache,
    );
    expect(
      PlanoFeaturesSyncCopy.forRefreshError(Exception('500')),
      PlanoFeaturesSyncCopy.refreshFailed,
    );
  });
}
