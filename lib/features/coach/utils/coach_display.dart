import '../data/coach_proativo_repository.dart';

const coachComoCalculamos =
    'Todo dia às 8h checamos treino parado há 5 dias, sono abaixo de 5h e sequência quebrada. '
    'Quando bate, o aluno já recebe um push motivacional. Aqui fica o aviso para você.';

const coachComoResolver =
    'Abrir o aluno, escrever ou agendar tira ele da lista. O alerta também some quando ele volta a treinar ou depois de 7 dias.';

const coachEmptyTitle = 'Nenhum aluno precisa de atenção';

const coachEmptySubtitle =
    'Aparece aqui quem ficou 5 dias sem treinar, dormiu pouco ou quebrou a sequência. Depende do check-in dos treinos.';

String? coachPendingChipLabel(int pending) {
  if (pending <= 0) return null;
  if (pending == 1) return '1 aluno pede atenção';
  return '$pending alunos pedem atenção';
}

String coachPendingTitulo(int pending) {
  if (pending <= 0) return 'Ninguém precisa de atenção';
  if (pending == 1) return '1 aluno precisa de atenção';
  return '$pending alunos precisam de atenção';
}

String coachMotivo(CoachHomeItem item) {
  final motivo = item.motivo.trim();
  if (motivo.isNotEmpty) return motivo;
  return switch (item.tipo.trim().toUpperCase()) {
    'SEM_TREINO_5D' => 'Alguns dias sem treinar',
    'STREAK_QUEBRADO' => 'Parou de treinar nesta semana',
    'SONO_BAIXO' => 'Dormiu menos de 5h',
    _ => 'Precisa de atenção',
  };
}

String? coachJaAvisado(CoachHomeItem item) {
  final msg = item.mensagem.trim();
  if (msg.isEmpty) return null;
  return 'Já avisamos o aluno: “$msg”';
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

/// Ações do card de foco — P0 no fold, resto sob demanda (A30 / §0.1).
enum CoachFocusActionId { open, chat, agenda, ack }

({CoachFocusActionId primary, List<CoachFocusActionId> secondary})
coachFocusActions({
  required bool canChat,
  required bool canAgenda,
}) {
  return (
    primary: CoachFocusActionId.open,
    secondary: [
      if (canChat) CoachFocusActionId.chat,
      if (canAgenda) CoachFocusActionId.agenda,
      CoachFocusActionId.ack,
    ],
  );
}

String coachFocusActionLabel(CoachFocusActionId id) => switch (id) {
  CoachFocusActionId.open => 'Abrir aluno',
  CoachFocusActionId.chat => 'Escrever',
  CoachFocusActionId.agenda => 'Agenda',
  CoachFocusActionId.ack => 'Arquivar',
};
