import 'package:flutter/material.dart';

import '../../dashboard/data/command_center_data.dart';
import '../data/aluno_contact_utils.dart';
import '../data/aluno_repository.dart';

/// Sticky bar action resolved from 360 payload and queue state.
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

  String get caption =>
      hasAnyCheckin ? '$totalCheckins check-ins' : 'Sem check-ins';
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
