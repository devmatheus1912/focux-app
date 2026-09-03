import '../data/coach_proativo_repository.dart';

const coachComoCalculamos =
    'Treino parado, sono curto ou sequência quebrada. Abrir o aluno fecha o job.';

String coachRota(CoachHomeItem item) {
  final rota = item.rota.trim();
  if (rota.startsWith('/')) return rota;
  return item.alunoId > 0 ? '/alunos/${item.alunoId}' : '/alunos';
}
