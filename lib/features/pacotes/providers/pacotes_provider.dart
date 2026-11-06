import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/sessao_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/pacote_repository.dart';

final pacoteRepositoryProvider = Provider<PacoteRepository>(
  (ref) => PacoteRepository(ref.read(apiClientProvider)),
);

final pacotesHomeProvider = FutureProvider<PacotesHomeBundle>((ref) async {
  ref.watch(sessaoProvider);
  return ref.read(pacoteRepositoryProvider).getHome();
});

void invalidatePacotesCaches(WidgetRef ref) {
  ref.invalidate(pacotesHomeProvider);
}
