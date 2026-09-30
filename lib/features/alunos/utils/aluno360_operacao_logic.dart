import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/data/command_center_data.dart';
import '../data/aluno_contact_utils.dart';
import '../../ia/models/ia_copilot_proxima_acao.dart';
import '../data/aluno_repository.dart';
import 'aluno360_copilot_logic.dart';
import 'aluno_hero_signal.dart';

part 'aluno360_operacao_logic_format.part.dart';
part 'aluno360_operacao_logic_visibility.part.dart';
part 'aluno360_operacao_logic_snapshot.part.dart';

enum OperacaoStickyDestination {
  chat,
  commandCenter,
  evolucao,
  editAluno,
  financeiro,
  treino,
  commitment,
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

  bool get isCommitmentAction =>
      destination == OperacaoStickyDestination.commitment;
}

enum OperacaoDominantMetricKind { risco, aderencia, prontidao }

/// Cards do grid Status operacional — destino decidido no app (BE sem deep link).
enum OperacaoStatusCardKind {
  focoDoDia,
  prontidao,
  aderencia,
  ultimoTreino,
  risco,
  checkins7d,
}

enum OperacaoStatusCardDestination {
  chat,
  engajamento,
  treinos,
  noop,
}

/// Resolve destino do card. Não usar treinos como default para Foco/Risco/Aderência.
OperacaoStatusCardDestination resolveOperacaoStatusCardDestination({
  required OperacaoStatusCardKind kind,
  required bool contactPriority,
  ProximaAcaoResumo? proximaAcao,
}) {
  switch (kind) {
    case OperacaoStatusCardKind.focoDoDia:
      return _focoDoDiaDestination(
        contactPriority: contactPriority,
        proximaAcao: proximaAcao,
      );
    case OperacaoStatusCardKind.risco:
      return contactPriority
          ? OperacaoStatusCardDestination.chat
          : OperacaoStatusCardDestination.engajamento;
    case OperacaoStatusCardKind.aderencia:
      return OperacaoStatusCardDestination.engajamento;
    case OperacaoStatusCardKind.prontidao:
      // Sem deep link de treino; detalhe wearable fica na própria aba.
      return OperacaoStatusCardDestination.noop;
    case OperacaoStatusCardKind.ultimoTreino:
      return OperacaoStatusCardDestination.treinos;
    case OperacaoStatusCardKind.checkins7d:
      // Check-ins = aderência/engajamento, não lista de treinos.
      return OperacaoStatusCardDestination.engajamento;
  }
}

/// `go_router` extra for engajamento — nome alone or `{nome, section}`.
Object operacaoEngajamentoRouteExtra(
  String alunoNome, {
  String? section,
}) {
  if (section == null || section.isEmpty) return alunoNome;
  return <String, String>{'nome': alunoNome, 'section': section};
}

String? operacaoEngajamentoSectionForStatusKind(OperacaoStatusCardKind kind) {
  if (kind == OperacaoStatusCardKind.checkins7d) return 'checkins';
  return null;
}

OperacaoStatusCardDestination _focoDoDiaDestination({
  required bool contactPriority,
  ProximaAcaoResumo? proximaAcao,
}) {
  if (contactPriority) return OperacaoStatusCardDestination.chat;

  final tipo = proximaAcao?.tipoAcao?.toUpperCase().trim() ?? '';
  final acao = proximaAcao?.acao.trim() ?? '';
  final lower = acao.toLowerCase();

  if (tipo == 'CONTATO' ||
      tipo == 'RECUPERACAO' ||
      tipo == 'WEARABLE' ||
      acaoSugereChat(acao)) {
    return OperacaoStatusCardDestination.chat;
  }
  if (tipo == 'ADERENCIA' ||
      lower.contains('aderên') ||
      lower.contains('aderenc') ||
      lower.contains('churn') ||
      lower.contains('inativ') ||
      lower.contains('sumiu') ||
      lower.contains('sumiço')) {
    return OperacaoStatusCardDestination.engajamento;
  }
  if (tipo == 'TREINO' ||
      tipo == 'CHECKIN' ||
      lower.contains('treino') ||
      lower.contains('check-in') ||
      lower.contains('checkin')) {
    return OperacaoStatusCardDestination.treinos;
  }
  if (tipo == 'MEDIDA' ||
      lower.contains('medida') ||
      lower.contains('corporal') ||
      lower.contains('mapa')) {
    // Evolução fica no sticky; no grid de status, engajamento cobre o contexto.
    return OperacaoStatusCardDestination.engajamento;
  }
  if (tipo == 'FINANCEIRO' ||
      lower.contains('financeir') ||
      lower.contains('mensalidade')) {
    return OperacaoStatusCardDestination.engajamento;
  }
  // Default: permanecer no 360 / não empurrar treinos.
  return OperacaoStatusCardDestination.noop;
}

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
    // Janela fixa de 7 dias — totalSemana é soma de check-ins, não dias.
    const denom = 7;
    if (!hasAnyCheckin) {
      return '0 de $denom dias';
    }
    return '$totalCheckins check-ins · $daysWith de $denom dias';
  }

  String get weekRatioLabel {
    final daysWith =
        daysWithCheckin ?? points.where((p) => p.checkins > 0).length;
    if (points.isEmpty && daysWithCheckin == null) return '—';
    // Sempre dias-com-check-in / 7 (nunca totalSemana = soma de check-ins).
    return '$daysWith/7';
  }
}
