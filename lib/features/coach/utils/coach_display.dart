import '../data/coach_proativo_repository.dart';

const coachComoCalculamos =
    'Treino parado, sono curto ou sequência quebrada. O catálogo pagina as não lidas. Abrir o aluno fecha o job.';

const coachEmptyTitle = 'Nada para o coach dizer';

const coachEmptySubtitle =
    'Ele só dispara com aluno ativo e sinal recente: treino parado há 5 dias, sono curto ou streak quebrada. Sem check-in, a fila fica vazia.';

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

String coachChatRota(CoachHomeItem item) =>
    item.alunoId > 0 ? '/alunos/${item.alunoId}/chat' : '/alunos';

bool coachPedeAgenda(String? tipo) {
  switch ((tipo ?? '').trim().toUpperCase()) {
    case 'SEM_TREINO_5D':
    case 'STREAK_QUEBRADO':
      return true;
    default:
      return false;
  }
}

String? coachAgendaRota(CoachHomeItem item) =>
    coachPedeAgenda(item.tipo) ? '/agenda' : null;
