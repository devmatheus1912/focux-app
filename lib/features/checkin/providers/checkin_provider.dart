import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/api/pagina.dart';
import '../data/checkin_repository.dart';
import '../data/meus_treinos_mem_cache.dart';
import '../models/checkin_personal_home.dart';

final checkinRepositoryProvider = Provider<CheckinRepository>(
  (ref) => CheckinRepository(ref.read(apiClientProvider)),
);

/// Primeira página de `/api/checkin/meus-treinos` (Pagina).
final meusTreinosProvider = FutureProvider<Pagina<ExecucaoTreino>>((ref) async {
  try {
    final pagina = await ref
        .read(checkinRepositoryProvider)
        .meusTreinosPagina(page: 0);
    MeusTreinosMemCache.save(pagina.content);
    return pagina;
  } catch (e) {
    final cached = MeusTreinosMemCache.loadIfFresh();
    if (cached != null) {
      return Pagina(content: cached, hasNext: false, page: 0, size: cached.length);
    }
    rethrow;
  }
});

final historicoCheckinProvider = FutureProvider<List<ExecucaoTreino>>((
  ref,
) async {
  return (await ref.read(checkinRepositoryProvider).historico()).content;
});

final checkinPersonalHomeProvider = FutureProvider<CheckinPersonalHomeBundle>((
  ref,
) async {
  return ref.read(checkinRepositoryProvider).personalHome();
});
