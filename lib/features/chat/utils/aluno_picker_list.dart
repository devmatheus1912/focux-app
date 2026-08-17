import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../alunos/data/aluno_repository.dart';

/// Cached `GET /api/alunos/home` alunos, including while the provider refreshes.
List<Aluno>? alunoPickerAlunosFromHome(AsyncValue<AlunosHomeBundle> homeAsync) {
  return homeAsync.valueOrNull?.alunos;
}

List<Aluno> filterAlunoPickerAlunos(List<Aluno> alunos, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return alunos;
  return alunos
      .where(
        (a) =>
            a.nome.toLowerCase().contains(q) ||
            a.email.toLowerCase().contains(q),
      )
      .toList();
}
