import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/evolucao_repository.dart';
import '../utils/evolucao_home_client_cache.dart';

/// Com `autoDispose`, abrir a tela sempre respeita os 45 s do cache: quem chega
/// pela notificação não vê o dado da visita anterior.
final evolucaoHomeProvider = FutureProvider.autoDispose.family<EvolucaoHomeBundle, int>((
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

/// Evolução do aluno logado: mesma resposta, sem cache de personal.
final minhaEvolucaoProvider = FutureProvider.autoDispose<EvolucaoHomeBundle>(
  (ref) => EvolucaoRepository(ref.read(apiClientProvider)).minhaEvolucao(),
);

/// Aquece a tela antes do toque.
void prefetchEvolucaoHome(WidgetRef ref, int alunoId) {
  if (EvolucaoHomeClientCache.getIfFresh(alunoId) != null) return;
  // ignore: unawaited_futures
  EvolucaoRepository(ref.read(apiClientProvider)).getHome(alunoId).then(
    (bundle) => EvolucaoHomeClientCache.put(alunoId, bundle),
    onError: (_) {},
  );
}
