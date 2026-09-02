import '../data/command_center_data.dart';

const copilotActionsStatusAberto = 'ABERTO';
const copilotActionsStatusAdiado = 'ADIADO';
const copilotActionsStatusConcluido = 'CONCLUIDO';

const copilotActionsStatusValues = [
  copilotActionsStatusAberto,
  copilotActionsStatusAdiado,
  copilotActionsStatusConcluido,
];

String copilotActionsStatusLabel(String status) {
  return switch (status) {
    copilotActionsStatusAdiado => 'Adiadas',
    copilotActionsStatusConcluido => 'Concluídas',
    _ => 'Abertas',
  };
}

String copilotActionsFiltroTitle() => 'Filtrar tarefas';

String copilotActionsRevisarAlunoLabel() => 'Revisar aluno';

String copilotActionsVerAlunoLabel() => 'Ver aluno';

String copilotActionsAdiarLabel() => 'Adiar 24h';

String copilotActionsConcluirLabel() => 'Concluir';

String copilotActionsReabrirLabel() => 'Reabrir';

String copilotActionsAtualizarLabel() => 'Atualizar';

String copilotActionsCompleteConfirmTitle() => 'Concluir esta tarefa?';

String copilotActionsCompleteConfirmMessage() =>
    'Sai da lista de abertas e vai para concluídas.';

String copilotActionsSnoozeConfirmTitle() => 'Adiar esta tarefa por 24h?';

String copilotActionsSnoozeConfirmMessage() =>
    'Vai para adiadas. Você pode reabrir depois.';

String copilotActionsReopenConfirmTitle() => 'Reabrir esta tarefa?';

String copilotActionsReopenConfirmMessage() => 'Volta para a lista de abertas.';

String copilotActionsHelpTitle() => 'Tarefas IA';

String copilotActionsHelpSubtitle() =>
    'Copiloto e sinais do Radar. Nada some sem você confirmar.';

String copilotActionsSectionDetail(String status, int count) {
  final suffix = switch (status) {
    copilotActionsStatusAdiado => 'adiadas',
    copilotActionsStatusConcluido => 'concluídas',
    _ => 'abertas',
  };
  return '$count $suffix';
}

String copilotActionsEmptyTitle(String status) {
  return switch (status) {
    copilotActionsStatusAdiado => 'Nenhuma tarefa adiada',
    copilotActionsStatusConcluido => 'Nenhuma tarefa concluída',
    _ => 'Nenhuma tarefa IA aberta',
  };
}

String copilotActionsEmptySubtitle(String status) {
  return switch (status) {
    copilotActionsStatusAdiado =>
      'Quando uma ação for adiada, ela fica guardada aqui.',
    copilotActionsStatusConcluido =>
      'As tarefas resolvidas aparecem aqui para auditoria.',
    _ => 'Copiloto e Radar Focux aparecem aqui quando exigem ação humana.',
  };
}

String copilotActionsModeLabel(FilaAcaoResumo action) {
  final raw = (action.sourceMode ?? '').trim();
  if (raw.isEmpty) return 'Treino';
  final lower = raw.toLowerCase();
  return lower.substring(0, 1).toUpperCase() + lower.substring(1);
}

String copilotActionsDeadlineLabel(
  FilaAcaoResumo action,
  String status, {
  DateTime? now,
}) {
  if (status == copilotActionsStatusConcluido) return 'concluída';
  if (status == copilotActionsStatusAdiado) return 'adiada';
  final dueAt = DateTime.tryParse(action.dueAt ?? '');
  if (dueAt == null) {
    final sla = action.sla.trim();
    if (sla.isEmpty) return 'vence em 24h';
    return sla.toLowerCase().contains('vence') ? sla : 'vence em $sla';
  }
  final diff = dueAt.difference(now ?? DateTime.now());
  if (diff.isNegative) return 'atrasada';
  final hours = diff.inHours.clamp(1, 999);
  return 'vence em ${hours}h';
}

String copilotActionsOpenAlunoLabel(bool done) =>
    done ? copilotActionsVerAlunoLabel() : copilotActionsRevisarAlunoLabel();
