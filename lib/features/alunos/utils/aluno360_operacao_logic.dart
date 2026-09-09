import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/data/command_center_data.dart';
import '../data/aluno_contact_utils.dart';
import '../../ia/models/ia_copilot_proxima_acao.dart';
import '../data/aluno_repository.dart';
import 'aluno360_copilot_logic.dart';
import 'aluno_hero_signal.dart';

enum OperacaoStickyDestination {
  chat,
  commandCenter,
  evolucao,
  editAluno,
  financeiro,
  treino,
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
  const AderenciaWeekPoint({required this.checkins, this.date, this.dayLetter});

  final double checkins;
  final String? date;

  /// Optional API label (ignored na UI — exibimos via [adherenceDayLetter]).
  final String? dayLetter;
}

class AderenciaWeekSummary {
  const AderenciaWeekSummary({
    required this.points,
    required this.totalCheckins,
    required this.hasAnyCheckin,
    this.daysWithCheckin,
    this.totalSemana,
    this.resumo = '',
  });

  final List<AderenciaWeekPoint> points;
  final int totalCheckins;
  final bool hasAnyCheckin;
  final int? daysWithCheckin;
  final int? totalSemana;
  final String resumo;

  String get caption {
    if (resumo.trim().isNotEmpty) return resumo.trim();
    if (points.isEmpty) return 'Sem dados';
    final daysWith =
        daysWithCheckin ?? points.where((p) => p.checkins > 0).length;
    final denom = totalSemana ?? points.length;
    if (!hasAnyCheckin) {
      return '0 de $denom dias';
    }
    return '$totalCheckins check-ins · $daysWith de $denom dias';
  }

  String get weekRatioLabel {
    final daysWith =
        daysWithCheckin ?? points.where((p) => p.checkins > 0).length;
    final denom = totalSemana ?? (points.isEmpty ? 7 : points.length);
    if (points.isEmpty && daysWithCheckin == null) return '—';
    return '$daysWith/$denom';
  }
}

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
  return OperacaoStickyDestination.commandCenter;
}

IconData stickyIconForDestination(OperacaoStickyDestination destination) {
  return switch (destination) {
    OperacaoStickyDestination.chat => Icons.chat_bubble_outline_rounded,
    OperacaoStickyDestination.evolucao => Icons.monitor_weight_outlined,
    OperacaoStickyDestination.editAluno => Icons.edit_outlined,
    OperacaoStickyDestination.commandCenter => Icons.dashboard_outlined,
    OperacaoStickyDestination.financeiro => Icons.payments_outlined,
    OperacaoStickyDestination.treino => Icons.fitness_center_outlined,
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
  final label =
      backendLabel != null && backendLabel.isNotEmpty
          ? backendLabel
          : copilotStickyLabel(aluno, acao, wearableRelevant: wearableRelevant);
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
    return 'Resumo da semana · aderência, treinos e check-ins';
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

/// Legend only when the week has at least one check-in (empty week is self-evident).
bool shouldShowOperacaoAdherenceLegend({required bool weekHasAnyCheckin}) =>
    weekHasAnyCheckin;

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
    return OperacaoAdherenceEmptyState(
      message: message,
      showCheckinCta: false,
    );
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
  if (raw == null || raw.isEmpty) return padAderenciaWeekToSevenDays(const []);
  final parsed = raw
      .map(
        (point) => AderenciaWeekPoint(
          checkins: (point['checkins'] as num?)?.toDouble() ?? 0,
          date:
              point['data'] as String? ??
              point['dia'] as String?,
          dayLetter:
              (point['labelDia'] as String?)?.trim() ??
              (point['weekday'] as String?)?.trim(),
        ),
      )
      .toList(growable: false);
  return padAderenciaWeekToSevenDays(parsed);
}

/// Ensures 7 distinct ISO days ending today (sparkline always has D–S labels).
List<AderenciaWeekPoint> padAderenciaWeekToSevenDays(
  List<AderenciaWeekPoint> points,
) {
  final byDate = <String, double>{};
  for (final point in points) {
    final date = point.date;
    if (date == null || date.isEmpty) continue;
    byDate[date] = point.checkins;
  }
  final today = DateTime.now();
  final anchor = DateTime(today.year, today.month, today.day);
  return List.generate(7, (index) {
    final day = anchor.subtract(Duration(days: 6 - index));
    final iso =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    return AderenciaWeekPoint(checkins: byDate[iso] ?? 0, date: iso);
  });
}

AderenciaWeekSummary summarizeAderenciaWeek(
  List<AderenciaWeekPoint> points, {
  AderenciaSemanalBundle? bundle,
}) {
  if (points.isEmpty && bundle == null) {
    return const AderenciaWeekSummary(
      points: [],
      totalCheckins: 0,
      hasAnyCheckin: false,
    );
  }
  final total = points.fold<double>(0, (sum, p) => sum + p.checkins);
  final hasAny =
      (bundle?.diasComCheckin ?? 0) > 0 || points.any((p) => p.checkins > 0);
  return AderenciaWeekSummary(
    points: points,
    totalCheckins: total.round(),
    hasAnyCheckin: hasAny,
    daysWithCheckin: bundle?.diasComCheckin,
    totalSemana: bundle == null
        ? null
        : (bundle.totalSemana > 0 ? bundle.totalSemana : 7),
    resumo: bundle?.resumo ?? '',
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

/// Parses yyyy-MM-dd as a local calendar date (not UTC midnight).
DateTime? parseIsoDateLocal(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(isoDate.trim());
  if (match == null) return null;
  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

/// Siglas de dois caracteres para spark bars (Do Sg Te Qa Qi Sx Sb — sem ambiguidade).
const kWeekdayShortLabels = ['Do', 'Sg', 'Te', 'Qa', 'Qi', 'Sx', 'Sb'];

/// Two-letter weekday label for adherence sparkline (domingo = Do).
String weekdayLetterFromIso(String? isoDate) {
  final parsed = parseIsoDateLocal(isoDate);
  if (parsed == null) return '';
  return kWeekdayShortLabels[parsed.weekday % 7];
}

/// Full weekday name for sparkline tooltips (Seg, Ter, …).
String weekdayNameFromIso(String? isoDate) {
  final parsed = parseIsoDateLocal(isoDate);
  if (parsed == null) return '';
  const labels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
  return labels[parsed.weekday % 7];
}

/// Whether [isoDate] (yyyy-MM-dd) is today in local time.
bool isIsoDateToday(String? isoDate) {
  final parsed = parseIsoDateLocal(isoDate);
  if (parsed == null) return false;
  final now = DateTime.now();
  return parsed.year == now.year &&
      parsed.month == now.month &&
      parsed.day == now.day;
}

/// Label for adherence spark bar (always from local ISO — evita labelDia legado I/X/A).
String adherenceDayLetter(AderenciaWeekPoint point) =>
    weekdayLetterFromIso(point.date);

/// Compact cell label — dia do mês (cabe em células estreitas).
String adherenceDayCellLabel(AderenciaWeekPoint point) {
  final parsed = parseIsoDateLocal(point.date);
  if (parsed == null) return '';
  return '${parsed.day}';
}

/// Staggered entrance delay for Operação sections (finance banner shifts timeline).
Duration operacaoSectionDelay({
  required bool financeRisk,
  required int stepIndex,
  bool contactPriority = false,
}) {
  if (contactPriority) return Duration.zero;
  const withFinance = [0, 40, 80, 120, 160, 200];
  const withoutFinance = [0, 0, 40, 80, 120, 160];
  final table = financeRisk ? withFinance : withoutFinance;
  final index = stepIndex.clamp(0, table.length - 1);
  return Duration(milliseconds: table[index]);
}

/// True when hero already surfaces operational risk (skip duplicate tiles).
bool operacaoHeroShowsRisco(Aluno aluno) =>
    alunoHeroPrimarySignal(aluno).label == 'Risco operacional';

bool shouldCompactFollowUpForContactPriority({
  required bool contactPriority,
  OperacaoUiHints? uiHints,
}) => uiHints?.compactFollowUp ?? contactPriority;

/// Prefer BE hints when bundled in /360; fallback to local heuristics.
bool resolveOperacaoContactPriority({
  required Aluno aluno,
  ProximaAcaoResumo? proximaAcao,
  OperacaoUiHints? uiHints,
}) => uiHints?.contactPriority ??
    isOperacaoContatoPrioritario(aluno: aluno, proximaAcao: proximaAcao);

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
///
/// Contact priority keeps the prescription body (motivo + preparar mensagem);
/// the sticky CTA remains the primary action and must not hollow the section.
bool shouldShowCopilotPrescriptionBlock({
  required bool forceIa,
  required OperacaoStickyAction sticky,
  required Aluno aluno,
  String? proximaAcaoRaw,
  bool contactPriority = false,
}) {
  if (forceIa) return true;
  if (contactPriority) return true;
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

/// Copy for compact follow-up row when contact is the hero priority.
String alunoFollowUpCompactSubtitle({
  required String alunoNome,
  required DateTime? followUpDate,
  required bool isSnoozed,
  required DateTime? snoozedUntil,
  required String Function(DateTime) formatDate,
}) {
  if (isSnoozed && snoozedUntil != null) {
    return 'Adiado até ${formatDate(snoozedUntil)}';
  }
  if (followUpDate != null) {
    return 'Agendado para ${formatDate(followUpDate)}';
  }
  final firstName = alunoPrimeiroNome(alunoNome);
  if (firstName != 'aluno') {
    return 'Agende depois de falar com $firstName';
  }
  return 'Agende o próximo contato após hoje';
}

/// Hide contact badge when sticky already surfaces the same CTA.
bool shouldShowCopilotContactBadge({
  required bool contactPriority,
  required OperacaoStickyAction sticky,
}) {
  if (!contactPriority) return false;
  return !sticky.isChatAction;
}

/// Hide check-in CTA when copilot/sticky already owns contact outreach.
bool shouldShowOperacaoCheckinCta({
  required Aluno360OperacaoSnapshot? operacao,
  required bool weekHasAnyCheckin,
}) {
  if (weekHasAnyCheckin) return false;
  if (operacao == null) return true;
  if (operacao.showPrepareMessage) return false;
  if (operacao.contactPriority && operacao.stickyAction.isChatAction) {
    return false;
  }
  return true;
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
}) => hasOpenTask && sticky.isChatAction;

/// True when the sticky bar shows Tarefa or Chat beside the primary CTA.
bool hasOperacaoStickySecondary({
  required OperacaoStickyAction sticky,
  required bool hasOpenTask,
  required bool followUpDue,
  required String? proximaAcaoText,
}) =>
    shouldShowStickySecondaryCommandCenter(
      sticky: sticky,
      hasOpenTask: hasOpenTask,
    ) ||
    shouldShowStickySecondaryChat(
      sticky: sticky,
      hasOpenTask: hasOpenTask,
      followUpDue: followUpDue,
      proximaAcaoText: proximaAcaoText,
    );

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
  final showPrepareMessage = acaoSugereChat(acao) || contactPriority;
  final hideCopilotChatRow =
      shouldHideCopilotChatCta(sticky: sticky, hasOpenTask: hasOpenTask) ||
      showPrepareMessage;
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
