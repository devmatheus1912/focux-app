part of 'aluno360_operacao_logic.dart';

enum AlunoDetailTab { operacao, evolucao, ferramentas }

const _stickyLabelMax = 32;

String truncateStickyLabel(String raw) {
  final trimmed = raw.trim();
  if (trimmed.length <= _stickyLabelMax) return trimmed;
  return '${trimmed.substring(0, _stickyLabelMax - 1)}…';
}

bool isAlunoFollowUpDue(Aluno aluno, {DateTime? now}) {
  final followUp = aluno.followUpDate;
  if (followUp == null) return false;
  final clock = now ?? DateTime.now();
  return !followUp.isAfter(clock);
}

bool isAluno360CopilotOpenAction(FilaAcaoResumo action) {
  if (action.status.toUpperCase() != 'ABERTO') return false;
  final source = (action.source ?? '').toUpperCase();
  return action.tipo == 'IA_COPILOTO' ||
      source == 'ALUNO_360' ||
      (action.sourceMode ?? '').toUpperCase() == 'ALUNO_360' ||
      action.createdFromInsight;
}

FilaAcaoResumo? findOpenCopilotTask(List<FilaAcaoResumo> actions) {
  for (final action in actions) {
    if (isAluno360CopilotOpenAction(action)) return action;
  }
  return null;
}

OperacaoStickyDestination resolveOperacaoStickyDestination(
  String acao, {
  required bool followUpDue,
}) {
  final lower = cleanCopilotText(acao).toLowerCase();
  if (lower.contains('cadastro') ||
      lower.contains('mapa') ||
      lower.contains('corporal')) {
    return OperacaoStickyDestination.editAluno;
  }
  if (lower.contains('medida')) {
    return OperacaoStickyDestination.evolucao;
  }
  if (lower.contains('financeir') ||
      lower.contains('inadimpl') ||
      lower.contains('cobrar') ||
      lower.contains('mensalidade') ||
      lower.contains('pagamento')) {
    return OperacaoStickyDestination.financeiro;
  }
  if (lower.contains('atribuir') ||
      lower.contains('prescrever') ||
      (lower.contains('treino') && lower.contains('montar'))) {
    return OperacaoStickyDestination.treino;
  }
  if (acaoSugereChat(acao) || (followUpDue && acao.trim().isEmpty)) {
    return OperacaoStickyDestination.chat;
  }
  if (lower.contains('objetivo') ||
      lower.contains('perfil') ||
      lower.contains('lacuna')) {
    return OperacaoStickyDestination.editAluno;
  }
  if (acaoSugereCommitment(acao)) {
    return OperacaoStickyDestination.commitment;
  }
  if (lower.contains('evolu') ||
      lower.contains('planejar') ||
      lower.contains('radar') ||
      lower.contains('volume') ||
      lower.contains('pr ')) {
    return OperacaoStickyDestination.evolucao;
  }
  return OperacaoStickyDestination.commandCenter;
}

/// Sono / horário da noite — compromisso no 360, sem endpoint novo.
bool acaoSugereCommitment(String acao) {
  final lower = cleanCopilotText(acao).toLowerCase();
  final mentionsHour =
      lower.contains('hora') ||
      lower.contains('horár') ||
      lower.contains('horar');
  return lower.contains('sono') ||
      lower.contains('durm') ||
      (mentionsHour && lower.contains('noite'));
}

IconData stickyIconForDestination(OperacaoStickyDestination destination) {
  return switch (destination) {
    OperacaoStickyDestination.chat => Icons.chat_bubble_outline_rounded,
    OperacaoStickyDestination.evolucao => Icons.monitor_weight_outlined,
    OperacaoStickyDestination.editAluno => Icons.edit_outlined,
    OperacaoStickyDestination.commandCenter => Icons.dashboard_outlined,
    OperacaoStickyDestination.financeiro => Icons.payments_outlined,
    OperacaoStickyDestination.treino => Icons.fitness_center_outlined,
    OperacaoStickyDestination.commitment => Icons.bedtime_outlined,
  };
}

OperacaoStickyAction resolveOperacaoStickyAction({
  required Aluno aluno,
  required ProximaAcaoResumo? proximaAcao,
  required bool hasOpenTask,
  required bool followUpDue,
  bool wearableRelevant = true,
}) {
  final acao = proximaAcao?.acao.trim() ?? '';

  if (hasOpenTask && acao.isEmpty) {
    return OperacaoStickyAction(
      label: 'Ver tarefa',
      icon: stickyIconForDestination(OperacaoStickyDestination.commandCenter),
      destination: OperacaoStickyDestination.commandCenter,
    );
  }

  if (acao.isEmpty) {
    if (aluno.inadimplente || aluno.statusFinanceiro == 'INADIMPLENTE') {
      return OperacaoStickyAction(
        label: 'Cobrar mensalidade',
        icon: stickyIconForDestination(OperacaoStickyDestination.financeiro),
        destination: OperacaoStickyDestination.financeiro,
      );
    }
    if (followUpDue) {
      return OperacaoStickyAction(
        label: 'Abrir chat',
        icon: stickyIconForDestination(OperacaoStickyDestination.chat),
        destination: OperacaoStickyDestination.chat,
      );
    }
    return OperacaoStickyAction(
      label: 'Ver próxima ação',
      icon: stickyIconForDestination(OperacaoStickyDestination.commandCenter),
      destination: OperacaoStickyDestination.commandCenter,
    );
  }

  final destination = resolveOperacaoStickyDestination(
    acao,
    followUpDue: followUpDue,
  );
  final backendLabel = proximaAcao?.stickyLabel?.trim();
  final derived = copilotStickyLabel(
    aluno,
    acao,
    wearableRelevant: wearableRelevant,
  );
  final label =
      backendLabel != null &&
              backendLabel.isNotEmpty &&
              backendLabel.length <= 32 &&
              !backendLabel.contains('. ')
          ? backendLabel
          : derived;
  return OperacaoStickyAction(
    label: label,
    icon: stickyIconForDestination(destination),
    destination: destination,
  );
}

/// Copy + CTA for a week with zero check-ins in the adherence spark block.
class OperacaoAdherenceEmptyState {
  const OperacaoAdherenceEmptyState({
    required this.message,
    this.hint,
    required this.showCheckinCta,
  });

  final String message;
  final String? hint;
  final bool showCheckinCta;

  String get compactLine {
    final base = message.replaceAll(RegExp(r'\.\s*$'), '');
    if (hint == null || hint!.isEmpty) return message;
    final hintText = hint!.replaceAll(RegExp(r'\.\s*$'), '');
    return '$base · $hintText';
  }
}

