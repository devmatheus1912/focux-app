import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/cache/offline_cache.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/checkin_repository.dart';

final checkinRepositoryProvider = Provider<CheckinRepository>(
  (ref) => CheckinRepository(ref.read(apiClientProvider)),
);

const _cacheKeyTreinos = 'meus_treinos';

final meusTreinosProvider = FutureProvider<List<ExecucaoTreino>>((ref) async {
  try {
    final treinos = await ref.read(checkinRepositoryProvider).meusTreinos();
    // Cache the fresh data for offline use
    final jsonList = treinos.map((t) => t.toJson()).toList();
    await OfflineCache.put(_cacheKeyTreinos, jsonList);
    return treinos;
  } catch (e) {
    // If network fails, try cached data
    final cached = await OfflineCache.get<List>(_cacheKeyTreinos, ttl: const Duration(hours: 24));
    if (cached != null) {
      return cached
          .cast<Map<String, dynamic>>()
          .map((json) => ExecucaoTreino.fromJson(json))
          .toList();
    }
    rethrow;
  }
});

final historicoCheckinProvider = FutureProvider<List<ExecucaoTreino>>((ref) async {
  return ref.read(checkinRepositoryProvider).historico();
});

