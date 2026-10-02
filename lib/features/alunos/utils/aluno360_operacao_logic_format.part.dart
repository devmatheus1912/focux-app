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
  if (lower.contains('mapa') ||
      lower.contains('corporal') ||
      lower.contains('medida')) {
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

String? operacaoStatusSubtitle(
  Aluno aluno, {
  required bool heroShowsRisco,
  bool compactFollowUpVisible = false,
}) {
  if (compactFollowUpVisible) return null;
  if (heroShowsRisco) {
    return 'Resumo · aderência de 30 dias e check-ins dos últimos 7 dias';
  }
  return 'Próximo contato: ${formatProximoContato(aluno)}';
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

/// Legend only when some day treinou or faltou (neutral-only week is self-evident).
bool shouldShowOperacaoAdherenceLegend({
  required List<AderenciaWeekPoint> points,
}) => points.any((point) {
  final status = resolveAderenciaDiaStatus(point);
  return status == AderenciaDiaStatus.treinou ||
      status == AderenciaDiaStatus.faltou;
});

OperacaoAdherenceEmptyState? resolveOperacaoAdherenceEmptyState({
  required AderenciaWeekSummary week,
  required Aluno360OperacaoSnapshot? operacao,
}) {
  if (week.points.isEmpty || week.hasAnyCheckin) return null;

  final message =
      week.resumo.trim().isNotEmpty
          ? week.resumo.trim()
          : 'Nenhum check-in nos últimos 7 dias.';

  if (operacao?.showPrepareMessage == true) {
    return OperacaoAdherenceEmptyState(message: message, showCheckinCta: false);
  }

  return OperacaoAdherenceEmptyState(
    message: message,
    hint: 'Peça um check-in com mensagem pronta.',
    showCheckinCta: true,
  );
}

/// Human-readable idle days for operational tiles.
String formatDiasSemTreinoDisplay(int? dias) {
  if (dias == null) return '—';
  if (dias <= 0) return 'hoje';
  return '${dias}d';
}

String formatSemTreinoOperacaoLabel(int? dias) {
  if (dias != null && dias <= 0) return 'Último treino';
  return 'Sem treino';
}

String semTreinoOperacaoSubtitle(int? dias) {
  if (dias == null) return 'Ainda sem histórico no app';
  if (dias <= 0) return 'Treinou recentemente';
  return '$dias ${dias == 1 ? 'dia' : 'dias'} sem treinar';
}
