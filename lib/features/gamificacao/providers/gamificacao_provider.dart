import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/gamificacao_repository.dart';

final gamificacaoRepositoryProvider = Provider<GamificacaoRepository>(
  (ref) => GamificacaoRepository(ref.read(apiClientProvider)),
);

final gamificacaoProvider = FutureProvider<GamificacaoData>((ref) async {
  return ref.read(gamificacaoRepositoryProvider).getGamificacao();
});
