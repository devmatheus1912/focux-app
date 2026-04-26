import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/planos_repository.dart';

final _planosRepositoryProvider =
    Provider<PlanosRepository>((ref) => PlanosRepository(ref.read(apiClientProvider)));

/// Server-side feature flags do plano atual. Cacheado por sessão; invalide
/// (`ref.invalidate(planoFeaturesProvider)`) sempre que mudar a assinatura
/// (verify IAP, webhook MP, troca de plano, ativação de trial).
final planoFeaturesProvider = FutureProvider<PlanoFeatures>((ref) async {
  return ref.read(_planosRepositoryProvider).getPlanoFeatures();
});
