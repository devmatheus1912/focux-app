import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/checkin_repository.dart';
import '../data/meus_treinos_mem_cache.dart';

final checkinRepositoryProvider = Provider<CheckinRepository>(
  (ref) => CheckinRepository(ref.read(apiClientProvider)),
);

final meusTreinosProvider = FutureProvider<List<ExecucaoTreino>>((ref) async {
  try {
    final treinos = await ref.read(checkinRepositoryProvider).meusTreinos();
    MeusTreinosMemCache.save(treinos);
    return treinos;
  } catch (e) {
    final cached = MeusTreinosMemCache.loadIfFresh();
    if (cached != null) return cached;
    rethrow;
  }
});

final historicoCheckinProvider = FutureProvider<List<ExecucaoTreino>>((
  ref,
) async {
  return ref.read(checkinRepositoryProvider).historico();
});
