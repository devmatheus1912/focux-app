import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/utils/dashboard_home_client_cache.dart';
import '../data/plano_features_bff_cache.dart';
import '../data/planos_repository.dart';

final planosRepositoryProvider = Provider<PlanosRepository>(
  (ref) => PlanosRepository(ref.read(apiClientProvider)),
);

/// Server-side feature flags do plano atual.
///
/// Se [DashboardHomeClientCache] já tem `planoFeatures` fresco (TTL 90s),
/// [PlanoFeaturesNotifier.bootstrap] usa esse snapshot e não chama
/// GET `/api/planos/me`. Sem Home cache, aplica stale-while-revalidate no
/// snapshot local de [PlanosRepository] (gate imediato + refresh em fundo).
final planoFeaturesProvider =
    NotifierProvider<PlanoFeaturesNotifier, AsyncValue<PlanoFeatures>>(
      PlanoFeaturesNotifier.new,
    );

class PlanoFeaturesNotifier extends Notifier<AsyncValue<PlanoFeatures>> {
  late PlanosRepository _repo;
  bool _refreshing = false;

  /// Bumps on [seedFromHome] so an in-flight bootstrap `/planos/me` cannot
  /// overwrite a fresher Home BFF snapshot.
  int _generation = 0;

  @visibleForTesting
  Future<void> bootstrapped = Future<void>.value();

  @override
  AsyncValue<PlanoFeatures> build() {
    _repo = ref.read(planosRepositoryProvider);
    final fresh = _freshHomeSnapshot();
    if (fresh != null) return AsyncData(_remember(fresh));
    bootstrapped = Future.microtask(bootstrap);
    return const AsyncLoading();
  }

  PlanoFeatures? _freshHomeSnapshot() =>
      PlanoFeaturesBffCache.getIfFresh() ??
      DashboardHomeClientCache.getIfFresh()?.planoFeatures;

  bool _applyFreshHomeCacheIfAny() {
    final fresh = _freshHomeSnapshot();
    if (fresh == null) return false;
    seedFromHome(fresh);
    return true;
  }

  Future<void> bootstrap() async {
    if (!ref.mounted || _applyFreshHomeCacheIfAny()) return;

    final gen = _generation;
    final cached = await _repo.loadCachedPlanoFeatures();
    if (!ref.mounted || _generation != gen) return;
    if (_applyFreshHomeCacheIfAny()) return;

    if (cached != null) {
      state = AsyncData(cached.normalizeForTier());
      if (PlanosRepository.isEntitlementsCacheFresh(cached.cacheSavedAt)) {
        unawaited(
          AnalyticsService.instance.track(
            ProductEvents.planGateStaleUsed,
            props: {
              'plan': cached.plano.name,
              'cacheSavedAt': cached.cacheSavedAt?.toIso8601String(),
            },
          ),
        );
      }
      // Sem GET /me em fundo: o próximo BFF chama [seedFromHome].
      return;
    }

    await _refreshIfBootstrapStillCurrent(gen, forceLoading: true);
  }

  Future<void> _refreshIfBootstrapStillCurrent(
    int gen, {
    bool forceLoading = false,
  }) async {
    if (_generation != gen) return;
    if (_applyFreshHomeCacheIfAny()) return;
    await refresh(forceLoading: forceLoading);
  }

  Future<void> refresh({
    bool forceLoading = false,
    bool reconcileFirst = false,
  }) async {
    if (_refreshing) return;
    _refreshing = true;
    final gen = _generation;
    final previous = state.value;
    if (forceLoading || previous == null) {
      state = const AsyncLoading();
    }

    try {
      final fresh =
          reconcileFirst
              ? await _repo.reconcilePlanoFeatures()
              : await _fetchWithRetry();
      if (!ref.mounted || _generation != gen) return;
      state = AsyncData(fresh.normalizeForTier());
    } catch (error) {
      if (!ref.mounted || _generation != gen) return;
      if (previous != null &&
          PlanosRepository.canUseStaleEntitlementsOnError(
            previous.cacheSavedAt,
          )) {
        state = AsyncData(
          previous.normalizeForTier().copyWithOperationalState(
            fromCache: true,
            syncWarning: PlanoFeaturesSyncCopy.forRefreshError(error),
          ),
        );
        unawaited(
          AnalyticsService.instance.track(
            ProductEvents.planGateRefreshFailed,
            props: {'plan': previous.plano.name, 'error': error.toString()},
          ),
        );
      } else {
        final forAluno = await _isAlunoSession();
        if (!ref.mounted || _generation != gen) return;
        final fallback =
            (forAluno
                    ? PlanoFeatures.optimisticAluno
                    : PlanoFeatures.free)
                .normalizeForTier();
        state = AsyncData(fallback);
        unawaited(
          AnalyticsService.instance.track(
            ProductEvents.planGateRefreshFailed,
            props: {
              'plan': fallback.plano.name,
              'error': error.toString(),
              'allowedByOptimisticFallback': false,
              'forAluno': forAluno,
            },
          ),
        );
      }
    } finally {
      _refreshing = false;
    }
  }

  /// Cold-start cases (Railway free tier, mobile data flaky) often need a
  /// couple of attempts before /planos/me responds. Retry up to 3 times
  /// with 1s/2s backoff before surfacing a hard error.
  Future<bool> _isAlunoSession() async {
    final role = await SecureStorage.getRole();
    return role == 'ALUNO';
  }

  Future<PlanoFeatures> _fetchWithRetry() async {
    final forAluno = await _isAlunoSession();
    Object? lastError;
    StackTrace? lastStack;
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        return await _repo.getPlanoFeaturesFresh(forAluno: forAluno);
      } catch (error, stack) {
        lastError = error;
        lastStack = stack;
        if (attempt < 2) {
          await Future<void>.delayed(Duration(seconds: 1 << attempt));
        }
      }
    }
    Error.throwWithStackTrace(lastError!, lastStack!);
  }

  /// Seed imediato a partir do BFF `/home` (mesmo shape de `/planos/me`).
  void seedFromHome(PlanoFeatures features) {
    state = AsyncData(_remember(features));
  }

  PlanoFeatures _remember(PlanoFeatures features) {
    _generation++;
    final normalized = features.normalizeForTier();
    PlanoFeaturesBffCache.put(normalized);
    return normalized;
  }
}
