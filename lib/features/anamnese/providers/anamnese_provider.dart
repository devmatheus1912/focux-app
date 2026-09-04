import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/anamnese_repository.dart';

final anamneseRepositoryProvider = Provider<AnamneseRepository>(
  (ref) => AnamneseRepository(ref.read(apiClientProvider)),
);

/// Ficha do aluno logado — banner/CTA no Meu Treino.
final minhaAnamneseProvider = FutureProvider<Anamnese>((ref) async {
  return ref.read(anamneseRepositoryProvider).buscarMinha();
});

/// Ficha de um aluno (personal) — tile Aluno 360.
final alunoAnamneseProvider =
    FutureProvider.family<Anamnese, int>((ref, alunoId) async {
  return ref.read(anamneseRepositoryProvider).buscar(alunoId);
});
