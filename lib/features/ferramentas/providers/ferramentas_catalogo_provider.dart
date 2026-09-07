import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/ferramentas_catalogo_models.dart';
import '../data/ferramentas_catalogo_repository.dart';

final ferramentasCatalogoRepositoryProvider = Provider(
  (ref) => FerramentasCatalogoRepository(ref.read(apiClientProvider)),
);

/// Catálogo de hubs — fonte única para Home + sheet (não lista flat local).
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
      // Refresh em background sem bloquear first paint.
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
    return repo.fetch();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(ferramentasCatalogoRepositoryProvider).fetch(
            allowStaleOnError: false,
          ),
    );
  }
}
