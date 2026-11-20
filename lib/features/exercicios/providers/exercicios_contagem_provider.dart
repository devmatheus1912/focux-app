import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/sessao_provider.dart';
import 'exercicios_provider.dart';

/// Quantos exercícios o personal tem em "Meus" e na biblioteca, para o topo
/// da aba ("3 seus · 492 da biblioteca"). Duas consultas de uma linha só.
typedef ExerciciosContagem = ({int meus, int biblioteca});

final exerciciosContagemProvider = FutureProvider<ExerciciosContagem>((
  ref,
) async {
  ref.watch(sessaoProvider);
  final repo = ref.read(exercicioRepositoryProvider);
  final (meus, biblioteca) =
      await (
        repo.listarPagina(aba: 'MEUS', size: 1),
        repo.listarPagina(aba: 'FOCUX', size: 1),
      ).wait;
  return (
    meus: meus.meta.totalElements,
    biblioteca: biblioteca.meta.totalElements,
  );
});
