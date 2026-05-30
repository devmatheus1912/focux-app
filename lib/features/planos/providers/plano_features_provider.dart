import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/planos_repository.dart';

final planosRepositoryProvider = Provider<PlanosRepository>(
  (ref) => PlanosRepository(ref.read(apiClientProvider)),
);

final _planosRepositoryProvider = planosRepositoryProvider;

/// Server-side feature flags do plano atual.
///
/// Stale-while-revalidate: se existir snapshot local, o gate usa esse dado
/// imediatamente e atualiza em segundo plano. Assim uma oscilacao de rede nao
/// derruba usuario pagante em uma tela de bloqueio falsa.
final planoFeaturesProvider = StateNotifierProvider<
  PlanoFeaturesNotifier,
  AsyncValue<PlanoFeatures>
>((ref) {
  final notifier = PlanoFeaturesNotifier(ref.read(_planosRepositoryProvider));
  unawaited(notifier.bootstrap());
  return notifier;
});

class PlanoFeaturesNotifier extends StateNotifier<AsyncValue<PlanoFeatures>> {
  final PlanosRepository _repo;
  bool _refreshing = false;

  PlanoFeaturesNotifier(this._repo) : super(const AsyncLoading());

  Future<void> bootstrap() async {
    final cached = await _repo.loadCachedPlanoFeatures();
    if (cached != null) {
      state = AsyncData(cached);
      unawaited(
        AnalyticsService.instance.track(
          ProductEvents.planGateStaleUsed,
          props: {
            'plan': cached.plano.name,
            'cacheSavedAt': cached.cacheSavedAt?.toIso8601String(),
          },
        ),
      );
      unawaited(refresh());
      return;
    }

    await refresh(forceLoading: true);
  }

  Future<void> refresh({bool forceLoading = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    final previous = state.valueOrNull;
    if (forceLoading || previous == null) {
      state = const AsyncLoading();
    }

    try {
      final fresh = await _fetchWithRetry();
      state = AsyncData(fresh);
    } catch (error) {
      if (previous != null) {
        state = AsyncData(
          previous.copyWithOperationalState(
            fromCache: true,
            syncWarning:
                'Nao foi possivel confirmar o plano agora. Mantivemos o ultimo acesso salvo.',
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
        final fallback = forAluno
            ? PlanoFeatures.optimisticAluno
            : PlanoFeatures.optimisticEnterprise;
        state = AsyncData(fallback);
        unawaited(
          AnalyticsService.instance.track(
            ProductEvents.planGateRefreshFailed,
            props: {
              'plan': fallback.plano.name,
              'error': error.toString(),
              'allowedByOptimisticFallback': true,
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
}
