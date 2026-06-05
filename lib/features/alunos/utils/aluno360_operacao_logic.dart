import 'package:flutter/material.dart';

import '../../dashboard/data/command_center_data.dart';
import '../data/aluno_contact_utils.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno_display_utils.dart';
import 'aluno360_copilot_logic.dart';
import 'aluno_hero_signal.dart';

enum OperacaoStickyDestination {
  chat,
  commandCenter,
  evolucao,
  editAluno,
}

/// Sticky bar action resolved from 360 payload and queue state.
class OperacaoStickyAction {
  const OperacaoStickyAction({
    required this.label,
    required this.icon,
    required this.destination,
  });

  final String label;
  final IconData icon;
  final OperacaoStickyDestination destination;

  bool get isChatAction => destination == OperacaoStickyDestination.chat;
}

enum OperacaoDominantMetricKind { risco, aderencia, prontidao }

/// Primary operational metric shown above the secondary grid.
class OperacaoDominantMetric {
  const OperacaoDominantMetric({
    required this.kind,
    required this.label,
    required this.value,
    required this.hint,
    required this.semanticsLabel,
    this.riscoNivel,
  });

  final OperacaoDominantMetricKind kind;
  final String label;
  final String value;
  final String hint;
  final String semanticsLabel;
  final String? riscoNivel;
}

class AderenciaWeekPoint {
  const AderenciaWeekPoint({required this.checkins, this.date});

  final double checkins;
  final String? date;
}

class AderenciaWeekSummary {
  const AderenciaWeekSummary({
    required this.points,
    required this.totalCheckins,
    required this.hasAnyCheckin,
  });

  final List<AderenciaWeekPoint> points;
  final int totalCheckins;
  final bool hasAnyCheckin;

  String get caption {
    if (points.isEmpty) return 'Sem dados';
    final daysWith =
        points.where((p) => p.checkins > 0).length;
    if (!hasAnyCheckin) {
      return '0 de ${points.length} dias';
    }
    return '$totalCheckins check-ins · $daysWith de ${points.length} dias';
  }
}

enum AlunoDetailTab { operacao, evolucao, ferramentas }

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
  if (acaoSugereChat(acao) || (followUpDue && acao.trim().isEmpty)) {
    return OperacaoStickyDestination.chat;
  }
  if (lower.contains('objetivo') ||
      lower.contains('perfil') ||
      lower.contains('lacuna')) {
    return OperacaoStickyDestination.editAluno;
  }
  return OperacaoStickyDestination.commandCenter;
}

IconData stickyIconForDestination(OperacaoStickyDestination destination) {
  return switch (destination) {
    OperacaoStickyDestination.chat => Icons.chat_bubble_outline_rounded,
    OperacaoStickyDestination.evolucao => Icons.accessibility_new_rounded,
    OperacaoStickyDestination.editAluno => Icons.edit_outlined,
    OperacaoStickyDestination.commandCenter => Icons.open_in_new_rounded,
  };
}

OperacaoStickyAction resolveOperacaoStickyAction({
  required Aluno aluno,
  required ProximaAcaoResumo? proximaAcao,
  required bool hasOpenTask,
  required bool followUpDue,
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
  return OperacaoStickyAction(
    label: copilotStickyLabel(aluno, acao),
    icon: stickyIconForDestination(destination),
    destination: destination,
  );
}

String operacaoStatusSubtitle(Aluno aluno, {required bool heroShowsRisco}) {
  return 'Próximo contato: ${formatProximoContato(aluno)}';
}

/// Human-readable idle days for operational tiles.
String formatDiasSemTreinoDisplay(int? dias) {
  if (dias == null) return 'Sem registro';
  return '${dias}d';
}

OperacaoDominantMetric resolveOperacaoDominantMetric(Aluno aluno) {
  if (aluno.emRisco) {
    final risco = formatRiscoNivel(aluno.riscoNivel);
    return OperacaoDominantMetric(
      kind: OperacaoDominantMetricKind.risco,
      label: 'Foco do dia',
      value: risco,
      hint: 'Em risco · priorize contato',
      semanticsLabel: 'Risco $risco',
      riscoNivel: aluno.riscoNivel,
    );
  }

  final aderencia = aluno.aderenciaPercent;
  if (aderencia != null) {
    return OperacaoDominantMetric(
      kind: OperacaoDominantMetricKind.aderencia,
      label: 'Aderência semanal',
      value: '$aderencia%',
      hint: 'Métrica dominante da semana',
      semanticsLabel: 'Aderência $aderencia por cento',
    );
  }

  final prontidao = aluno.scoreProntidao;
  return OperacaoDominantMetric(
    kind: OperacaoDominantMetricKind.prontidao,
    label: 'Prontidão',
    value: prontidao == null ? '—' : '$prontidao',
    hint: 'Índice operacional',
    semanticsLabel: 'Prontidão ${prontidao ?? 'indisponível'}',
  );
}

List<AderenciaWeekPoint> parseAderenciaSemanal(
  List<Map<String, dynamic>>? raw,
) {
  if (raw == null || raw.isEmpty) return const [];
  return raw
      .map(
        (point) => AderenciaWeekPoint(
          checkins: (point['checkins'] as num?)?.toDouble() ?? 0,
          date: point['data'] as String?,
        ),
      )
      .toList(growable: false);
}

AderenciaWeekSummary summarizeAderenciaWeek(List<AderenciaWeekPoint> points) {
  if (points.isEmpty) {
    return const AderenciaWeekSummary(
      points: [],
      totalCheckins: 0,
      hasAnyCheckin: false,
    );
  }
  final total = points.fold<double>(0, (sum, p) => sum + p.checkins);
  return AderenciaWeekSummary(
    points: points,
    totalCheckins: total.round(),
    hasAnyCheckin: points.any((p) => p.checkins > 0),
  );
}

AlunoDetailTab parseAlunoDetailTab(String? tab) {
  if (tab == null || tab.isEmpty) return AlunoDetailTab.operacao;
  switch (tab.toLowerCase()) {
    case 'operacao':
    case 'operação':
    case '0':
      return AlunoDetailTab.operacao;
    case 'evolucao':
    case 'evolução':
    case '1':
      return AlunoDetailTab.evolucao;
    case 'ferramentas':
    case '2':
      return AlunoDetailTab.ferramentas;
    default:
      return AlunoDetailTab.operacao;
  }
}

int alunoDetailTabIndex(AlunoDetailTab tab) => tab.index;

int parseAlunoDetailTabIndex(String? tab) =>
    alunoDetailTabIndex(parseAlunoDetailTab(tab));

/// Single-letter weekday for spark bars (D S T Q Q S S, Sunday-first).
String weekdayLetterFromIso(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return '';
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return '';
  const labels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
  return labels[parsed.weekday % 7];
}

/// Full weekday name for sparkline tooltips (Seg, Ter, …).
String weekdayNameFromIso(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return '';
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return '';
  const labels = [
    'Dom',
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
  ];
  return labels[parsed.weekday % 7];
}

/// Staggered entrance delay for Operação sections (finance banner shifts timeline).
Duration operacaoSectionDelay({
  required bool financeRisk,
  required int stepIndex,
}) {
  const withFinance = [0, 40, 80, 120, 160, 200];
  const withoutFinance = [0, 0, 40, 80, 120, 160];
  final table = financeRisk ? withFinance : withoutFinance;
  final index = stepIndex.clamp(0, table.length - 1);
  return Duration(milliseconds: table[index]);
}

/// True when hero already surfaces operational risk (skip duplicate tiles).
bool operacaoHeroShowsRisco(Aluno aluno) =>
    alunoHeroPrimarySignal(aluno).label == 'Risco operacional';

/// Hide copilot lacunas when hero/sticky already covers the same action.
bool shouldShowCopilotProfileGapsButton(
  Aluno aluno,
  int profileCompletion, {
  OperacaoStickyAction? sticky,
}) {
  if (profileCompletion >= 80) return false;
  if (copilotProfileGapsForCard(aluno).isEmpty) return false;
  if (sticky == null) return true;
  if (sticky.destination == OperacaoStickyDestination.evolucao) return false;
  if (sticky.destination == OperacaoStickyDestination.editAluno) return false;
  return true;
}

/// Prescription block stays visible during IA refresh even if sticky matches 360.
bool shouldShowCopilotPrescriptionBlock({
  required bool forceIa,
  required OperacaoStickyAction sticky,
  required Aluno aluno,
  String? proximaAcaoRaw,
}) {
  if (forceIa) return true;
  return !shouldHideCopilotPrescriptionWhenMatchesSticky(
    sticky: sticky,
    aluno: aluno,
    proximaAcaoRaw: proximaAcaoRaw,
  );
}

/// Hide copilot prescription block when sticky already shows the same CTA.
bool shouldHideCopilotPrescriptionWhenMatchesSticky({
  required OperacaoStickyAction sticky,
  required Aluno aluno,
  String? proximaAcaoRaw,
}) {
  final raw = proximaAcaoRaw?.trim() ?? '';
  if (raw.isEmpty) return false;
  return sticky.label == copilotStickyLabel(aluno, raw);
}

/// Hide copilot primary CTA when sticky already covers Command Center action.
bool shouldHideCopilotPrimaryCtaWhenMatchesSticky({
  required OperacaoStickyAction sticky,
  required Aluno aluno,
  String? proximaAcaoRaw,
}) {
  if (sticky.destination != OperacaoStickyDestination.commandCenter) {
    return false;
  }
  return shouldHideCopilotPrescriptionWhenMatchesSticky(
    sticky: sticky,
    aluno: aluno,
    proximaAcaoRaw: proximaAcaoRaw,
  );
}

/// Sticky primary opens chat — hide duplicate chat CTA in copilot card.
bool shouldHideCopilotChatCta({
  required OperacaoStickyAction sticky,
  required bool hasOpenTask,
}) {
  if (sticky.isChatAction) return true;
  if (hasOpenTask) return true;
  return false;
}

/// Outline chat on sticky when primary is Command Center but contact is due.
bool shouldShowStickySecondaryChat({
  required OperacaoStickyAction sticky,
  required bool hasOpenTask,
  required bool followUpDue,
  required String? proximaAcaoText,
}) {
  if (sticky.isChatAction) return false;
  if (sticky.label == 'Abrir chat') return false;
  if (hasOpenTask) return followUpDue;
  return followUpDue || acaoSugereChat(proximaAcaoText ?? '');
}

/// Outline Command Center on sticky when chat is primary but a task is open.
bool shouldShowStickySecondaryCommandCenter({
  required OperacaoStickyAction sticky,
  required bool hasOpenTask,
}) =>
    hasOpenTask && sticky.isChatAction;
