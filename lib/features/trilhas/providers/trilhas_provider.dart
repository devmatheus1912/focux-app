import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/trilhas_repository.dart';
import '../models/trilha.dart';

final trilhasRepositoryProvider = Provider(
  (ref) => TrilhasRepository(ref.read(apiClientProvider)),
);

final trilhasAlunoProvider = FutureProvider.family<TrilhaLista, int>((
  ref,
  alunoId,
) {
  return ref.read(trilhasRepositoryProvider).listarPorAluno(alunoId);
});

final trilhasMinhasProvider = FutureProvider<TrilhaLista>((ref) {
  return ref.read(trilhasRepositoryProvider).listarMinhas();
});
