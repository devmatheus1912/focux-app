import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/recorrencia_repository.dart';

/// A recorrência em vigor de um aluno (qualquer status menos cancelada), ou
/// nulo. Vem da busca por nome da lista do personal, filtrada pelo id.
final recorrenciaDoAlunoProvider = FutureProvider.autoDispose
    .family<RecorrenciaAssinatura?, ({int alunoId, String nome})>((
      ref,
      aluno,
    ) async {
      final page = await RecorrenciaRepository(
        ref.read(apiClientProvider),
      ).listarPagina(q: aluno.nome, size: 20);
      for (final r in page.content) {
        if (r.alunoId == aluno.alunoId &&
            r.status.trim().toUpperCase() != 'CANCELADA') {
          return r;
        }
      }
      return null;
    });
