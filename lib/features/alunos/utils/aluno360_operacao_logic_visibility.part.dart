part of 'aluno360_operacao_logic.dart';

List<AderenciaWeekPoint> parseAderenciaSemanal(
  List<Map<String, dynamic>>? raw,
) {
  if (raw == null || raw.isEmpty) return padAderenciaWeekToSevenDays(const []);
  final parsed = raw
      .map(
        (point) => AderenciaWeekPoint(
          checkins: (point['checkins'] as num?)?.toDouble() ?? 0,
          date: point['data'] as String? ?? point['dia'] as String?,
          dayLetter:
              (point['labelDia'] as String?)?.trim() ??
              (point['weekday'] as String?)?.trim(),
          status: parseAderenciaDiaStatus(point['status'] as String?),
        ),
      )
      .toList(growable: false);
  return padAderenciaWeekToSevenDays(parsed);
}

/// Ensures 7 distinct ISO days ending today (sparkline always has D–S labels).
List<AderenciaWeekPoint> padAderenciaWeekToSevenDays(
  List<AderenciaWeekPoint> points,
) {
  final byDate = <String, AderenciaWeekPoint>{};
  for (final point in points) {
    final date = point.date;
    if (date == null || date.isEmpty) continue;
    byDate[date] = point;
  }
  final today = DateTime.now();
  final anchor = DateTime(today.year, today.month, today.day);
  return List.generate(7, (index) {
    final day = anchor.subtract(Duration(days: 6 - index));
    final iso =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    final source = byDate[iso];
    return AderenciaWeekPoint(
      checkins: source?.checkins ?? 0,
      date: iso,
      status: source?.status,
    );
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
    totalSemana:
        bundle == null
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

/// Label for adherence spark bar (always from local ISO — evita labelDia legado I/X/A).
String adherenceDayLetter(AderenciaWeekPoint point) =>
    weekdayLetterFromIso(point.date);

/// Prefer BE hints when bundled in /360; fallback to local heuristics.
bool resolveOperacaoContactPriority({
  required Aluno aluno,
  ProximaAcaoResumo? proximaAcao,
  OperacaoUiHints? uiHints,
}) =>
    uiHints?.contactPriority ??
    isOperacaoContatoPrioritario(aluno: aluno, proximaAcao: proximaAcao);


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
