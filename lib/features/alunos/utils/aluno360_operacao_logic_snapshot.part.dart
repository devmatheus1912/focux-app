part of 'aluno360_operacao_logic.dart';

/// Snapshot unificado da aba Operação (sticky + copilot + outreach).
class Aluno360OperacaoSnapshot {
  const Aluno360OperacaoSnapshot({
    required this.effectiveProxima,
    required this.stickyAction,
    required this.stickyDisplayLabel,
    required this.contactPriority,
    required this.showPrepareMessage,
    required this.hideCopilotTaskRow,
    required this.hideCopilotChatRow,
    required this.outreachMessage,
  });

  final ProximaAcaoResumo? effectiveProxima;
  final OperacaoStickyAction stickyAction;
  final String stickyDisplayLabel;
  final bool contactPriority;
  final bool showPrepareMessage;
  final bool hideCopilotTaskRow;
  final bool hideCopilotChatRow;
  final String outreachMessage;
}

Aluno360OperacaoSnapshot resolveAluno360OperacaoSnapshot({
  required Aluno aluno,
  required ProximaAcaoResumo? proximaAcao360,
  required bool forceIa,
  required AsyncValue<IaCopilotProximaAcao>? iaAsync,
  required bool hasOpenTask,
  required bool followUpDue,
  bool wearableRelevant = true,
  OperacaoUiHints? uiHints,
}) {
  var effectiveProxima = resolveCopilotProximaAcaoResumo(
    proximaAcao360: proximaAcao360,
    forceIa: forceIa,
    iaAsync: iaAsync,
  );
  if (effectiveProxima != null) {
    effectiveProxima = sanitizeProximaAcaoWearable(
      aluno,
      effectiveProxima,
      wearableRelevant: wearableRelevant,
    );
  }
  var sticky = resolveOperacaoStickyAction(
    aluno: aluno,
    proximaAcao: effectiveProxima,
    hasOpenTask: hasOpenTask,
    followUpDue: followUpDue,
    wearableRelevant: wearableRelevant,
  );
  final acao = effectiveProxima?.acao ?? '';
  final contactPriority = resolveOperacaoContactPriority(
    aluno: aluno,
    proximaAcao: effectiveProxima,
    uiHints: uiHints,
  );
  sticky = applyContactPriorityStickyOverride(
    sticky: sticky,
    contactPriority: contactPriority,
    hasOpenTask: hasOpenTask,
    proximaAcao: effectiveProxima,
  );
  final stickySecondaryVisible = hasOperacaoStickySecondary(
    sticky: sticky,
    hasOpenTask: hasOpenTask,
    followUpDue: followUpDue,
    proximaAcaoText: effectiveProxima?.acao,
  );
  final stickyDisplayLabel = resolveStickyDisplayLabel(
    sticky: sticky,
    compact: stickySecondaryVisible,
    proximaAcao: effectiveProxima,
  );
  final outreachAcao =
      contactPriority && !acaoSugereChat(acao)
          ? contactPriorityOutreachAcao()
          : acao;
  // Sticky chat já abre o sheet de mensagem — não duplicar "Preparar mensagem".
  final wantsPrepare = acaoSugereChat(acao) || contactPriority;
  final showPrepareMessage = wantsPrepare && !sticky.isChatAction;
  final hideCopilotChatRow =
      shouldHideCopilotChatCta(sticky: sticky, hasOpenTask: hasOpenTask) ||
      wantsPrepare;
  return Aluno360OperacaoSnapshot(
    effectiveProxima: effectiveProxima,
    stickyAction: sticky,
    stickyDisplayLabel: stickyDisplayLabel,
    contactPriority: contactPriority,
    showPrepareMessage: showPrepareMessage,
    hideCopilotTaskRow: shouldHideCopilotTaskRowWhenContactPriority(
      contactPriority: contactPriority,
      hasOpenTask: hasOpenTask,
    ),
    hideCopilotChatRow: hideCopilotChatRow,
    outreachMessage: resolveOutreachMessage(
      aluno,
      acao: outreachAcao,
      backendMessage: effectiveProxima?.mensagemSugerida,
      wearableRelevant: wearableRelevant,
    ),
  );
}

/// §9 S3: faixa de 2–4 métricas. Check-ins da semana não viram KPI extra —
/// a strip de 7 dias é o detalhe da aderência.
List<OperacaoStatusCardKind> resolveOperacaoStatusMetricKinds({
  required bool heroShowsRisco,
  required OperacaoDominantMetricKind dominantKind,
}) {
  final kinds = <OperacaoStatusCardKind>[];
  if (heroShowsRisco) {
    kinds.add(OperacaoStatusCardKind.aderencia);
    kinds.add(OperacaoStatusCardKind.ultimoTreino);
  } else {
    kinds.add(switch (dominantKind) {
      OperacaoDominantMetricKind.risco => OperacaoStatusCardKind.focoDoDia,
      OperacaoDominantMetricKind.aderencia => OperacaoStatusCardKind.aderencia,
      OperacaoDominantMetricKind.prontidao => OperacaoStatusCardKind.prontidao,
    });
    if (dominantKind != OperacaoDominantMetricKind.aderencia) {
      kinds.add(OperacaoStatusCardKind.aderencia);
    }
    if (dominantKind != OperacaoDominantMetricKind.risco) {
      kinds.add(OperacaoStatusCardKind.ultimoTreino);
    }
  }
  return kinds.take(4).toList(growable: false);
}
