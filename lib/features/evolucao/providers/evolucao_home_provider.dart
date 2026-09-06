import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/evolucao_repository.dart';
import '../utils/evolucao_home_client_cache.dart';

final evolucaoHomeProvider = FutureProvider.family<EvolucaoHomeBundle, int>((
  ref,
  alunoId,
) async {
  final cached = EvolucaoHomeClientCache.getIfFresh(alunoId);
  if (cached != null) return cached;
  final repo = EvolucaoRepository(ref.read(apiClientProvider));
  final bundle = await repo.getHome(alunoId);
  EvolucaoHomeClientCache.put(alunoId, bundle);
  return bundle;
});

/// Warm Medidas hub before the user taps (Ferramentas → Evolução).
///
/// Skips network when `/360/ferramentas.evolucaoHome` already hydrated the cache.
void prefetchEvolucaoHome(WidgetRef ref, int alunoId) {
  if (EvolucaoHomeClientCache.getIfFresh(alunoId) != null) return;
  // ignore: unawaited_futures
  ref.read(evolucaoHomeProvider(alunoId).future);
}

