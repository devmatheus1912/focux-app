part of 'aluno360_operacao_logic.dart';

String alunoPrimeiroNome(String nomeAluno) {
  final trimmed = nomeAluno.trim();
  if (trimmed.isEmpty) return 'aluno';
  return trimmed.split(' ').first;
}

/// Mensagem sugerida ao pedir check-in pelo Aluno 360.
String checkinMensagemPronta(String nomeAluno) {
  final firstName = alunoPrimeiroNome(nomeAluno);
  return 'Oi, $firstName. Como foi seu último treino? '
      'Me manda carga, repetições e qualquer sensação fora do normal.';
}

/// Extra do GoRouter para `/alunos/:id/chat` com rascunho opcional.
Map<String, String> alunoChatRouteExtra({required String nome, String? draft}) {
  final extra = <String, String>{
    'nome': nome.trim().isEmpty ? 'Aluno' : nome.trim(),
  };
  final trimmedDraft = draft?.trim();
  if (trimmedDraft != null && trimmedDraft.isNotEmpty) {
    extra['draft'] = trimmedDraft;
  }
  return extra;
}

/// Label curto para sticky quando há botão secundário (evita truncamento).
String stickyLabelCompactFallback(String label) {
  final lower = label.toLowerCase();
  if (lower.contains('contato') || lower.contains('wearable')) return 'Contato';
  if (lower.contains('mapa') || lower.contains('corporal')) return 'Mapa';
  if (lower.contains('objetivo')) return 'Objetivo';
  if (lower.contains('treino')) return 'Treino';
  if (lower.contains('financeir')) return 'Financeiro';
  if (lower.contains('perfil')) return 'Perfil';
  if (lower.contains('sono') || lower.contains('durm')) return 'Sono';
  if (label.length <= 14) return label;
  return truncateStickyLabel(label);
}

/// Evita usar rótulo compacto do backend quando o sticky já foi sobrescrito
/// (ex.: contato prioritário enquanto proximaAcao ainda sugere mapa).
bool stickyCompactLabelAlignedWithAction({
  required OperacaoStickyAction sticky,
  required ProximaAcaoResumo? proximaAcao,
}) {
  if (proximaAcao == null) return true;
  final backend = proximaAcao.stickyLabelCompact?.trim();
  if (backend == null || backend.isEmpty) return true;

  final stickyCompact = stickyLabelCompactFallback(sticky.label);
  if (backend == stickyCompact) return true;

  final acao = proximaAcao.acao.trim();
  if (sticky.isChatAction && acao.isNotEmpty && !acaoSugereChat(acao)) {
    return false;
  }
  if (acao.isEmpty) return true;
  final expected = resolveOperacaoStickyDestination(acao, followUpDue: false);
  return sticky.destination == expected;
}

String resolveStickyDisplayLabel({
  required OperacaoStickyAction sticky,
  required bool compact,
  ProximaAcaoResumo? proximaAcao,
}) {
  if (compact) {
    final backend = proximaAcao?.stickyLabelCompact?.trim();
    if (backend != null &&
        backend.isNotEmpty &&
        backend.length <= 14 &&
        stickyCompactLabelAlignedWithAction(
          sticky: sticky,
          proximaAcao: proximaAcao,
        )) {
      return backend;
    }
    return stickyLabelCompactFallback(sticky.label);
  }
  return sticky.label;
}

bool isOperacaoContatoPrioritario({
  required Aluno aluno,
  ProximaAcaoResumo? proximaAcao,
}) {
  if (aluno.emRisco) return true;
  final acao = proximaAcao?.acao ?? '';
  if (acaoSugereChat(acao)) return true;
  final tipo = proximaAcao?.tipoAcao?.toUpperCase();
  if (tipo == 'CONTATO' || tipo == 'WEARABLE') return true;
  final aderencia = aluno.aderenciaPercent;
  if (aderencia != null && aderencia <= 0) return true;
  return false;
}

bool shouldHideCopilotTaskRowWhenContactPriority({
  required bool contactPriority,
  required bool hasOpenTask,
}) => contactPriority && !hasOpenTask;

/// Quando o hero pede contato mas o 360 ainda sugere mapa/perfil, o sticky alinha ao contato.
OperacaoStickyAction applyContactPriorityStickyOverride({
  required OperacaoStickyAction sticky,
  required bool contactPriority,
  required bool hasOpenTask,
  required ProximaAcaoResumo? proximaAcao,
}) {
  if (!contactPriority || sticky.isChatAction) return sticky;
  if (hasOpenTask &&
      proximaAcao?.acao.trim().isEmpty == true &&
      sticky.destination == OperacaoStickyDestination.commandCenter) {
    return sticky;
  }
  return OperacaoStickyAction(
    label: 'Retomar contato',
    icon: stickyIconForDestination(OperacaoStickyDestination.chat),
    destination: OperacaoStickyDestination.chat,
  );
}
