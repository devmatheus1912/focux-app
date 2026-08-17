import '../data/aluno_repository.dart';

/// Limiar de dias sem treino para UI (lista / 360).
///
/// Fonte: cache de `GET /api/alunos/home` (`alertasConfig`). Não dispara
/// `GET /api/alertas/configuracao` nem um novo `/alunos/home`.
int resolveDiasSemTreinoLimiteFromHome({
  required bool alunosHomeInitialized,
  int? cachedDiasSemTreino,
}) {
  if (alunosHomeInitialized && cachedDiasSemTreino != null) {
    return cachedDiasSemTreino;
  }
  return AlunosHomeBundle.fallbackDiasSemTreino;
}
