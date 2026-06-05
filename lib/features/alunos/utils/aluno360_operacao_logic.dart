import 'package:flutter/material.dart';

import '../data/aluno_repository.dart';

class OperacaoStickyAction {
  const OperacaoStickyAction({
    required this.label,
    required this.icon,
    required this.isChatAction,
  });

  final String label;
  final IconData icon;
  final bool isChatAction;
}

const _stickyLabelMax = 32;

String truncateStickyLabel(String raw) {
  final trimmed = raw.trim();
  if (trimmed.length <= _stickyLabelMax) return trimmed;
  return '${trimmed.substring(0, _stickyLabelMax - 1)}…';
}

bool acaoSugereChat(String acao) {
  final lower = acao.toLowerCase();
  return lower.contains('chat') ||
      lower.contains('mensagem') ||
      lower.contains('contato') ||
      lower.contains('follow-up') ||
      lower.contains('follow up') ||
      lower.contains('whatsapp');
}

OperacaoStickyAction resolveOperacaoStickyAction({
  required ProximaAcaoResumo? proximaAcao,
  required bool hasOpenTask,
  required bool followUpDue,
}) {
  if (hasOpenTask) {
    return const OperacaoStickyAction(
      label: 'Ver tarefa',
      icon: Icons.open_in_new_rounded,
      isChatAction: false,
    );
  }

  final acao = proximaAcao?.acao.trim() ?? '';
  if (acao.isNotEmpty) {
    final chat = acaoSugereChat(acao) || followUpDue;
    return OperacaoStickyAction(
      label: truncateStickyLabel(acao),
      icon:
          chat
              ? Icons.chat_bubble_outline_rounded
              : Icons.play_arrow_rounded,
      isChatAction: chat,
    );
  }

  if (followUpDue) {
    return const OperacaoStickyAction(
      label: 'Abrir chat',
      icon: Icons.chat_bubble_outline_rounded,
      isChatAction: true,
    );
  }

  return const OperacaoStickyAction(
    label: 'Ver próxima ação',
    icon: Icons.open_in_new_rounded,
    isChatAction: false,
  );
}

int parseAlunoDetailTabIndex(String? tab) {
  if (tab == null || tab.isEmpty) return 0;
  switch (tab.toLowerCase()) {
    case 'operacao':
    case 'operação':
    case '0':
      return 0;
    case 'evolucao':
    case 'evolução':
    case '1':
      return 1;
    case 'ferramentas':
    case '2':
      return 2;
    default:
      return 0;
  }
}

/// Single-letter weekday for spark bars (D S T Q Q S S, Sunday-first).
String weekdayLetterFromIso(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return '';
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return '';
  const labels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
  return labels[parsed.weekday % 7];
}
