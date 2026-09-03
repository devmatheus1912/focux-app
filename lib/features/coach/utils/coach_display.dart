import '../data/coach_proativo_repository.dart';

const coachComoCalculamos =
    'Treino parado, sono curto ou sequência quebrada. Abrir o aluno fecha o job.';

String? coachPendingChipLabel(int pending) {
  if (pending <= 0) return null;
  if (pending == 1) return '1 recado do coach';
  return '$pending recados do coach';
}

String coachRota(CoachHomeItem item) {
  final rota = item.rota.trim();
  if (rota.startsWith('/')) return rota;
  return item.alunoId > 0 ? '/alunos/${item.alunoId}' : '/alunos';
}
