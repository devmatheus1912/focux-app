import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/sessao_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/anamnese_repository.dart';

final anamneseRepositoryProvider = Provider<AnamneseRepository>(
  (ref) => AnamneseRepository(ref.read(apiClientProvider)),
);

/// Ficha do aluno logado — banner/CTA no Meu Treino.
final minhaAnamneseProvider = FutureProvider<Anamnese>((ref) async {
  ref.watch(sessaoProvider);
  return ref.read(anamneseRepositoryProvider).buscarMinha();
});

/// Ficha de um aluno (personal) — tile Aluno 360.
final alunoAnamneseProvider =
    FutureProvider.family<Anamnese, int>((ref, alunoId) async {
  ref.watch(sessaoProvider);
  return ref.read(anamneseRepositoryProvider).buscar(alunoId);
});
