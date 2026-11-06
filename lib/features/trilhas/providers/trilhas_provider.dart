import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/sessao_provider.dart';
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
  ref.watch(sessaoProvider);
  return ref.read(trilhasRepositoryProvider).listarPorAluno(alunoId);
});

final trilhasMinhasProvider = FutureProvider<TrilhaLista>((ref) {
  ref.watch(sessaoProvider);
  return ref.read(trilhasRepositoryProvider).listarMinhas();
});
