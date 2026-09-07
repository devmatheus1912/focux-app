import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/ferramentas_catalogo_bootstrap.dart';
import '../data/ferramentas_catalogo_models.dart';
import '../data/ferramentas_catalogo_repository.dart';

final ferramentasCatalogoRepositoryProvider = Provider(
  (ref) => FerramentasCatalogoRepository(ref.read(apiClientProvider)),
);

/// Catálogo de hubs — BFF primeiro; bootstrap local só se rede falhar sem cache.
final ferramentasCatalogoProvider =
    AsyncNotifierProvider<FerramentasCatalogoNotifier, FerramentasCatalogo>(
      FerramentasCatalogoNotifier.new,
    );

class FerramentasCatalogoNotifier extends AsyncNotifier<FerramentasCatalogo> {
  @override
  Future<FerramentasCatalogo> build() async {
    final repo = ref.read(ferramentasCatalogoRepositoryProvider);
    final cached = await repo.peekCache();
    if (cached != null) {
      Future.microtask(() async {
        try {
          final fresh = await repo.fetch(allowStaleOnError: false);
          state = AsyncData(fresh);
        } catch (_) {
          // Mantém cache.
        }
      });
      return cached;
    }

    try {
      return await repo.fetch(allowStaleOnError: false);
    } catch (_) {
      // Home não pode cair: usa árvore de hubs local até o BFF responder.
      Future.microtask(() async {
        try {
          final fresh = await repo.fetch(allowStaleOnError: false);
          state = AsyncData(fresh);
        } catch (_) {}
      });
      return ferramentasCatalogoBootstrap();
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        return await ref
            .read(ferramentasCatalogoRepositoryProvider)
            .fetch(allowStaleOnError: false);
      } catch (_) {
        final stale =
            await ref.read(ferramentasCatalogoRepositoryProvider).peekCache();
        return stale ?? ferramentasCatalogoBootstrap();
      }
    });
  }
}
