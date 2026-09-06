import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../ia/models/ia_copilot_proxima_acao.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno_display_utils.dart';

export 'aluno360_copilot_executar_logic.dart';
export 'aluno360_copilot_outreach_logic.dart';
export 'aluno360_copilot_text_logic.dart';
import 'aluno360_copilot_outreach_logic.dart';
import 'aluno360_copilot_text_logic.dart';

/// Signal chip shown in the copilot decision grid.
class Aluno360CopilotSignal {
  const Aluno360CopilotSignal({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final String label;
  final String value;
  final String detail;
  final Color color;
}

/// Profile gap surfaced by the copilot card.
class CopilotProfileGap {
  const CopilotProfileGap({
    required this.icon,
    required this.title,
    required this.detail,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String route;
}

/// Prescription copy resolved from IA / 360 seed / offline fallback.
class CopilotPrescriptionContent {
  const CopilotPrescriptionContent({
    required this.title,
    required this.action,
    required this.reason,
    this.fullAction,
  });

  final String title;
  final String action;
  final String reason;
  final String? fullAction;
}

int copilotProfileCompletion(Aluno aluno) {
  final fields = [
    aluno.nome,
    aluno.email,
    aluno.telefone,
    aluno.whatsapp,
    aluno.objetivo,
    aluno.genero,
    aluno.tipoConsultoria,
  ];
  final filled =
      fields.where((value) {
        if (value == null) return false;
        return value.trim().isNotEmpty;
      }).length;
  return ((filled / fields.length) * 100).round().clamp(0, 100);
}

String copilotCardTitle({required bool contactPriority}) =>
    contactPriority ? 'Prioridade do dia' : 'Próxima melhor ação';

Map<String, dynamic> copilotActionFrom360(ProximaAcaoResumo proxima) => {
  'titulo':
      proxima.fonte == 'RADAR'
          ? 'Radar Focux'
          : proxima.fonte == 'EVOLUCAO'
          ? 'Evolução inteligente'
          : proxima.fonte == 'AUTONOMIA'
          ? 'Autonomia'
          : proxima.fonte == 'IA'
          ? 'Sugestão IA'
          : 'Próxima melhor ação',
  'acao': proxima.acao,
  'motivo': proxima.motivo,
  'fonte': proxima.fonte,
  'prioridade': proxima.prioridade,
};

Map<String, dynamic> copilotActionFromIa(IaCopilotProximaAcao action) {
  final raw = action.rawAcaoOrFallback;
  final acao = normalizeIaCopilotAcao(raw);
  final motivoRaw = action.motivo.isEmpty
      ? 'Gerado com base nos sinais atuais do aluno.'
      : action.motivo;
  return {
    'titulo': 'Sugestão IA',
    'acao': acao.isEmpty ? cleanCopilotText(raw) : acao,
    'motivo': formatCopilotIaMotivo(motivoRaw),
    'fonte': 'IA',
  };
}

/// Merges IA refresh result over Aluno 360 seed for sticky + prescription.
ProximaAcaoResumo? resolveCopilotProximaAcaoResumo({
  required ProximaAcaoResumo? proximaAcao360,
  required bool forceIa,
  required AsyncValue<IaCopilotProximaAcao>? iaAsync,
}) {
  if (forceIa && iaAsync != null) {
    return iaAsync.maybeWhen(
      data:
          (action) =>
              proximaAcaoResumoFromIaPayload(action, fallback: proximaAcao360),
      orElse: () => proximaAcao360,
    );
  }
  return proximaAcao360;
}

ProximaAcaoResumo? proximaAcaoResumoFromIaPayload(
  IaCopilotProximaAcao action, {
  ProximaAcaoResumo? fallback,
}) {
  final raw = action.rawAcaoOrFallback;
  final acao = normalizeIaCopilotAcao(raw);
  if (acao.isEmpty && raw.isEmpty) return fallback;
  return ProximaAcaoResumo(
    acao: acao.isEmpty ? cleanCopilotText(raw) : acao,
    motivo: formatCopilotIaMotivo(
      action.motivo.isEmpty
          ? 'Gerado com base nos sinais atuais do aluno.'
          : action.motivo,
    ),
    fonte: 'IA',
    prioridade: 'P1',
    tipoAcao: action.tipoAcao,
    mensagemSugerida: action.mensagemSugerida,
    stickyLabel: action.stickyLabel,
    stickyLabelCompact: action.stickyLabelCompact,
    wearableRelevant: action.wearableRelevant,
  );
}

ProximaAcaoResumo sanitizeProximaAcaoWearable(
  Aluno aluno,
  ProximaAcaoResumo resumo, {
  required bool wearableRelevant,
}) {
  if (wearableRelevant) return resumo;
  final tipo = resumo.tipoAcao?.toUpperCase();
  if (tipo != 'WEARABLE' && !copilotAcaoMencionaWearable(resumo.acao)) {
    return resumo;
  }
  final acao = sanitizeCopilotAcaoWearable(
    resumo.acao,
    wearableRelevant: false,
  );
  return ProximaAcaoResumo(
    acao: acao,
    motivo: resumo.motivo,
    fonte: resumo.fonte,
    prioridade: resumo.prioridade,
    tipoAcao: 'CONTATO',
    mensagemSugerida: copilotMensagemPronta(
      aluno,
      contactPriorityOutreachAcao(),
      wearableRelevant: false,
    ),
    stickyLabel: 'Retomar contato',
    stickyLabelCompact: 'Contato',
    wearableRelevant: false,
  );
}

String sanitizeCopilotAcaoWearable(
  String acao, {
  required bool wearableRelevant,
}) {
  if (wearableRelevant || !copilotAcaoMencionaWearable(acao)) return acao;
  return 'Retomar contato e checar como está o treino.';
}

/// Mutually exclusive card body states for “Prioridade do dia”.
enum CopilotPriorityCardState {
  /// No prescription yet (first paint / empty).
  idle,

  /// Showing proximaAcao from GET /360/operacao (or legacy /360).
  showingDeterministic,

  /// IA request in flight — keep current card, status line only.
  refreshingAi,

  /// Showing GET /api/ia/copiloto/proxima-acao response.
  showingAi,

  /// IA failed — keep deterministic (or offline fallback).
  errorAi,
}

bool _copilotSeedHasAction(Map<String, dynamic>? seed360) {
  final acao = seed360?['acao']?.toString().trim() ?? '';
  return acao.isNotEmpty;
}

/// Resolves exclusive display state for the prescription card body.
CopilotPriorityCardState resolveCopilotPriorityCardState({
  required Map<String, dynamic>? seed360,
  required bool forceIa,
  required AsyncValue<IaCopilotProximaAcao>? iaAsync,
  required bool iaRefreshing,
}) {
  final iaInFlight =
      iaRefreshing ||
      (forceIa &&
          iaAsync != null &&
          iaAsync.isLoading &&
          !iaAsync.hasValue);

  if (iaInFlight) {
    return CopilotPriorityCardState.refreshingAi;
  }

  if (forceIa && iaAsync != null) {
    if (iaAsync.hasError && !iaAsync.hasValue) {
      return CopilotPriorityCardState.errorAi;
    }
    if (iaAsync.hasValue) {
      return CopilotPriorityCardState.showingAi;
    }
    return CopilotPriorityCardState.refreshingAi;
  }

  if (_copilotSeedHasAction(seed360)) {
    return CopilotPriorityCardState.showingDeterministic;
  }
  return CopilotPriorityCardState.idle;
}

/// Skeleton only when there is no prescription to keep on screen.
bool copilotPriorityCardAllowsSkeleton(CopilotPriorityCardState state) {
  return state == CopilotPriorityCardState.idle;
}

String copilotCardSubtitle({
  required bool forceIa,
  required AsyncValue<IaCopilotProximaAcao>? iaAsync,
  required bool resumoLoading,
  bool compact = false,
  bool iaRefreshing = false,
  bool bundleLoading = false,
  bool bundleRefreshing = false,
}) {
  if (bundleLoading) {
    return compact ? 'Sincronizando…' : 'Sincronizando Aluno 360…';
  }
  if (bundleRefreshing) {
    return compact ? 'Atualizando 360…' : 'Atualizando sinais do Aluno 360…';
  }
  if (iaRefreshing) {
    return compact ? 'Atualizando IA…' : 'Atualizando sugestão com IA…';
  }
  if (forceIa && iaAsync != null) {
    return iaAsync.when(
      loading: () => compact ? 'Gerando com IA…' : 'Gerando sugestão com IA…',
      error:
          (_, __) =>
              compact
                  ? 'Aluno 360 · IA indisponível'
                  : 'Sugestão do Aluno 360 · IA indisponível agora',
      data:
          (_) =>
              compact
                  ? 'Sugestão IA · toque em atualizar'
                  : 'Atualizado com IA · toque em atualizar para regenerar',
    );
  }
  if (resumoLoading) {
    return compact ? 'Carregando perfil…' : 'Carregando sinais do perfil…';
  }
  return 'Sugestão com base no perfil de hoje.';
}

String copilotDisplayAction(Aluno aluno, String acao) {
  final normalized = normalizeIaCopilotAcao(acao);
  final lower = normalized.toLowerCase();
  if (acaoSugereChat(normalized) || isRoboticCopilotContactCopy(normalized)) {
    if (isRoboticCopilotContactCopy(normalized) || normalized.length > 72) {
      return copilotCoachContactPrescription(aluno, acao: normalized);
    }
    if (normalized.length <= 72) return normalized;
    final firstName =
        aluno.nome.trim().isEmpty ? null : aluno.nome.trim().split(' ').first;
    final label = copilotChatActionLabel(normalized);
    return firstName == null ? '$label com o aluno.' : '$label com $firstName.';
  }
  if (lower.contains('mapa') || lower.contains('corporal')) {
    return 'Completar mapa corporal para orientar a prescrição.';
  }
  if (lower.contains('objetivo')) {
    return 'Definir objetivo para alinhar prescrição e Copiloto.';
  }
  if (lower.contains('financeir') || lower.contains('inadimpl')) {
    return 'Alinhar pendência financeira antes de qualquer ajuste.';
  }
  if (lower.contains('perfil') || lower.contains('medida')) {
    return 'Completar dados do perfil para melhorar a prescrição.';
  }
  if (lower.contains('treino') || lower.contains('carga')) {
    return 'Ajustar treino e orientar próximo check-in.';
  }
  if (normalized.length <= 72 && normalized.isNotEmpty) return normalized;
  return 'Retomar contato e ajustar plano com base na resposta.';
}

const _copilotComPhraseStopWords = {
  'urgência',
  'urgencia',
  'calma',
  'base',
  'foco',
  'treino',
  'o',
  'a',
};

String _stripCosmeticComPhrase(String key) {
  return key.replaceAllMapped(RegExp(r'\s+com\s+(\S+)\s+'), (match) {
    final word = match.group(1)!.toLowerCase();
    if (_copilotComPhraseStopWords.contains(word)) return match.group(0)!;
    if (word.length <= 2) return match.group(0)!;
    return ' ';
  });
}

String copilotPrescriptionActionCompareKey(String text) {
  var key = cleanCopilotText(text).toLowerCase();
  key = key.replaceAll(RegExp(r'[.!?;:,]'), '').trim();
  key = key.replaceAll(RegExp(r'\s+com\s+(o\s+)?aluno\s+'), ' ');
  key = _stripCosmeticComPhrase(key);
  return key.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Cosmetic-only differences (punctuation, embedded first name) are equivalent.
bool copilotPrescriptionActionsEquivalent(String a, String b) {
  if (a.trim() == b.trim()) return true;
  return copilotPrescriptionActionCompareKey(a) ==
      copilotPrescriptionActionCompareKey(b);
}

String copilotPrescriptionFullAction(Aluno aluno, String rawAcao) {
  final normalized = normalizeIaCopilotAcao(rawAcao);
  if (normalized.isNotEmpty) return normalized;
  return copilotDisplayAction(aluno, rawAcao);
}

String copilotPrescriptionDisplayAction(
  Aluno aluno,
  String rawAcao, {
  bool wearableRelevant = true,
}) {
  final sanitized = sanitizeCopilotAcaoWearable(
    rawAcao,
    wearableRelevant: wearableRelevant,
  );
  final full = copilotPrescriptionFullAction(aluno, sanitized);
  final lower = full.toLowerCase();

  if (wearableRelevant &&
      copilotAcaoMencionaWearable(full) &&
      (acaoSugereChat(full) || isRoboticCopilotContactCopy(full))) {
    return 'Retomar contato e pedir sync do wearable.';
  }
  if (acaoSugereChat(full) ||
      isRoboticCopilotContactCopy(full) ||
      lower.contains('paralisa') ||
      lower.contains('paralis')) {
    return copilotCoachContactPrescription(aluno, acao: full);
  }

  final templated = copilotDisplayAction(aluno, sanitized);
  if (isRoboticCopilotContactCopy(full)) return templated;
  if (templated != full && full.length > 72) return templated;
  if (full.length <= 72) return full;
  return templated;
}

const _stickyLabelMax = 32;

String truncateCopilotStickyLabel(String raw) {
  final trimmed = raw.trim();
  if (trimmed.length <= _stickyLabelMax) return trimmed;
  return '${trimmed.substring(0, _stickyLabelMax - 1)}…';
}

bool acaoSugereChat(String acao) {
  final lower = acao.toLowerCase();
  return lower.contains('chat') ||
      lower.contains('mensagem') ||
      lower.contains('contato') ||
      lower.contains('contate') ||
      lower.contains('contatar') ||
      lower.contains('contactar') ||
      lower.contains('falar com') ||
      lower.contains('entre em contato') ||
      lower.contains('inativid') ||
      lower.contains('paralisa') ||
      lower.contains('paralis') ||
      lower.contains('incentiv') ||
      lower.contains('reengaj') ||
      lower.contains('retomar') ||
      lower.contains('retomada') ||
      lower.contains('follow-up') ||
      lower.contains('follow up') ||
      lower.contains('whatsapp');
}

/// Short label shared by sticky bar and prescription action line.
String copilotStickyLabel(
  Aluno aluno,
  String acao, {
  bool wearableRelevant = true,
}) {
  final cleaned = normalizeIaCopilotAcao(acao);
  if (cleaned.isEmpty) return 'Ver próxima ação';
  if (!wearableRelevant && copilotAcaoMencionaWearable(cleaned)) {
    return 'Retomar contato';
  }
  final lower = cleaned.toLowerCase();
  if (lower.contains('mapa') || lower.contains('corporal')) {
    return 'Completar mapa corporal';
  }
  if (lower.contains('objetivo')) return 'Definir objetivo';
  if (lower.contains('financeir') || lower.contains('inadimpl')) {
    return 'Alinhar financeiro';
  }
  if (acaoSugereChat(cleaned)) {
    if (wearableRelevant && copilotAcaoMencionaWearable(cleaned)) {
      return 'Retomar contato · wearable';
    }
    return copilotChatActionLabel(cleaned);
  }
  if (lower.contains('treino') || lower.contains('carga')) {
    return 'Ajustar treino';
  }
  if (lower.contains('perfil') || lower.contains('lacuna')) {
    return 'Completar perfil';
  }
  return truncateCopilotStickyLabel(copilotDisplayAction(aluno, cleaned));
}

List<CopilotProfileGap> copilotProfileGapsForCard(Aluno aluno) {
  final gaps = resolveCopilotProfileGaps(aluno);
  if (alunoObjectiveIsDefined(aluno.objetivo)) return gaps;
  return gaps.where((gap) => gap.title != 'Objetivo').toList(growable: false);
}

String copilotProfileGapsButtonLabel(Aluno aluno) {
  final gaps = copilotProfileGapsForCard(aluno);
  if (gaps.length > 1) return 'Resolver lacunas';
  if (gaps.isEmpty) return 'Completar perfil';
  return 'Completar ${gaps.first.title.toLowerCase()}';
}

CopilotPrescriptionContent contactPriorityPrescriptionContent(
  Aluno aluno, {
  bool statusMetricsVisible = false,
  bool hideMetricFooter = false,
}) {
  final firstName =
      aluno.nome.trim().isEmpty
          ? 'o aluno'
          : aluno.nome.trim().split(' ').first;
  final aderencia = aluno.aderenciaPercent;
  final reason = sanitizeCopilotPrescriptionReason(
    aluno.emRisco
        ? 'Risco operacional · aderência ${aderencia ?? 0}% nos últimos 7 dias.'
        : aderencia != null && aderencia <= 0
        ? 'Sem check-ins recentes · priorize contato antes de evoluir o plano.'
        : 'Sinais do perfil pedem contato direto hoje.',
    statusMetricsVisible: statusMetricsVisible,
    hideMetricFooter: hideMetricFooter,
  );
  return CopilotPrescriptionContent(
    title: 'Prioridade do dia',
    action: 'Retomar contato com $firstName e checar como está.',
    reason: reason,
  );
}

String copilotFallbackAction(Aluno aluno, AlunoAutonomiaResumo? resumo) {
  if (aluno.statusFinanceiro == 'INADIMPLENTE') {
    return 'Regularizar financeiro antes que isso vire atrito de acesso.';
  }
  if (copilotProfileCompletion(aluno) < 80) {
    return 'Completar perfil do aluno e remover lacunas de prescrição.';
  }
  if (resumo != null && resumo.cliques > resumo.concluidos) {
    return 'Resolver o gargalo de autonomia: ${resumo.gargaloTitulo ?? "tarefa aberta"}.';
  }
  return 'Revisar treino e propor a próxima evolução de ${aluno.objetivo ?? "objetivo"}.';
}

List<CopilotProfileGap> resolveCopilotProfileGaps(Aluno aluno) {
  return [
    if ((aluno.telefone ?? '').trim().isEmpty &&
        (aluno.whatsapp ?? '').trim().isEmpty)
      const CopilotProfileGap(
        icon: Icons.call_outlined,
        title: 'Contato',
        detail: 'Telefone ou WhatsApp para acionar o aluno.',
        route: 'edit',
      ),
    if ((aluno.objetivo ?? '').trim().isEmpty)
      const CopilotProfileGap(
        icon: Icons.flag_outlined,
        title: 'Objetivo',
        detail: 'Define foco da prescrição e do Copiloto.',
        route: 'edit',
      ),
    if ((aluno.genero ?? '').trim().isEmpty ||
        (aluno.tipoConsultoria ?? '').trim().isEmpty)
      const CopilotProfileGap(
        icon: Icons.badge_outlined,
        title: 'Perfil do aluno',
        detail: 'Gênero e consultoria usados no atendimento.',
        route: 'edit',
      ),
  ];
}

List<Aluno360CopilotSignal> resolveCopilotSignals({
  required Aluno aluno,
  required AlunoAutonomiaResumo? resumo,
  required Color primary,
}) {
  final profile = copilotProfileCompletion(aluno);
  final financeiroOk = aluno.statusFinanceiro != 'INADIMPLENTE';
  final hasAutonomyFriction =
      resumo != null && resumo.cliques > resumo.concluidos;
  final hasEquipment = aluno.equipamentosDisponiveis.isNotEmpty;
  return [
    Aluno360CopilotSignal(
      label: 'Perfil',
      value: '$profile%',
      detail:
          profile >= 80 ? 'dados bons para prescrição' : 'perfil incompleto',
      color: profile >= 80 ? EagleTokens.good : primary,
    ),
    Aluno360CopilotSignal(
      label: 'Financeiro',
      value: financeiroOk ? 'OK' : 'Atenção',
      detail: financeiroOk ? 'sem bloqueio operacional' : 'pendência ativa',
      color: financeiroOk ? EagleTokens.good : EagleTokens.bad,
    ),
    Aluno360CopilotSignal(
      label: 'Autonomia',
      value:
          resumo == null
              ? '--'
              : '${(resumo.concluidos / (resumo.cliques == 0 ? 1 : resumo.cliques) * 100).clamp(0, 100).round()}%',
      detail:
          hasAutonomyFriction
              ? 'clicou e ainda não fechou'
              : 'sem gargalo aberto forte',
      color: hasAutonomyFriction ? EagleTokens.warn : primary,
    ),
    Aluno360CopilotSignal(
      label: 'Contexto',
      value: hasEquipment ? 'Rico' : 'Base',
      detail:
          hasEquipment
              ? '${aluno.equipamentosDisponiveis.length} equipamentos'
              : 'equipamentos não definidos',
      color: primary,
    ),
  ];
}

String resolveCopilotAcao({
  required Map<String, dynamic>? seed360,
  required bool forceIa,
  required AsyncValue<IaCopilotProximaAcao>? iaAsync,
  required String fallback,
}) {
  if (forceIa && iaAsync != null) {
    return iaAsync.maybeWhen(
      data: (action) {
        final raw = action.rawAcaoOrFallback.isEmpty
            ? fallback
            : action.rawAcaoOrFallback;
        final normalized = normalizeIaCopilotAcao(raw);
        return cleanCopilotText(normalized.isEmpty ? raw : normalized);
      },
      orElse: () => fallback,
    );
  }
  if (seed360 != null) {
    return cleanCopilotText((seed360['acao'] ?? fallback).toString());
  }
  return fallback;
}

CopilotPrescriptionContent resolveCopilotPrescriptionFromAction(
  Aluno aluno,
  Map<String, dynamic> action,
  String fallback, {
  bool wearableRelevant = true,
  bool contactPriority = false,
  bool statusMetricsVisible = false,
  bool hideMetricFooter = false,
}) {
  final rawAcao =
      (action['acao'] ?? action['mensagem'] ?? action['descricao'] ?? fallback)
          .toString();
  final motivoRaw =
      (action['motivo'] ?? 'Baseado nos sinais atuais.').toString();
  final isIa = (action['fonte'] ?? '').toString().toUpperCase() == 'IA';
  final sanitizedAcao = sanitizeCopilotAcaoWearable(
    rawAcao,
    wearableRelevant: wearableRelevant,
  );
  final fullActionRaw = copilotPrescriptionFullAction(aluno, sanitizedAcao);
  final displayAction = copilotPrescriptionDisplayAction(
    aluno,
    sanitizedAcao,
    wearableRelevant: wearableRelevant,
  );
  final String? fullAction;
  if (isRoboticCopilotContactCopy(fullActionRaw) &&
      !(wearableRelevant && copilotAcaoMencionaWearable(fullActionRaw))) {
    fullAction = null;
  } else if (copilotPrescriptionActionsEquivalent(
    fullActionRaw,
    displayAction,
  )) {
    fullAction = null;
  } else {
    fullAction = fullActionRaw;
  }
  final reason = sanitizeCopilotPrescriptionReason(
    isIa ? formatCopilotIaMotivo(motivoRaw) : motivoRaw,
    statusMetricsVisible: statusMetricsVisible,
    hideMetricFooter: hideMetricFooter,
  );
  return CopilotPrescriptionContent(
    title:
        contactPriority
            ? 'Prioridade do dia'
            : (action['titulo'] ?? action['tipo'] ?? 'Próxima melhor ação')
                .toString(),
    action: displayAction,
    fullAction: fullAction,
    reason: reason,
  );
}

CopilotPrescriptionContent offlineCopilotPrescription(String fallback) {
  return CopilotPrescriptionContent(
    title: 'Sugestão offline',
    action: fallback,
    reason: 'Baseado nos sinais atuais do perfil.',
  );
}

CopilotPrescriptionContent iaErrorCopilotPrescription(String fallback) {
  return CopilotPrescriptionContent(
    title: 'Sugestão offline',
    action: fallback,
    reason: 'IA indisponível agora; usando sinais do Aluno 360.',
  );
}

/// Card “Prioridade do dia” has something to show (deterministic and/or IA).
///
/// Deterministic seed comes from GET /360/operacao — not from copiloto IA.
bool aluno360CopilotHasPriorityCardContent({
  required ProximaAcaoResumo? proximaAcao360,
  required bool forceIa,
  required bool iaHasValue,
  required bool hasOpenTask,
}) {
  if (hasOpenTask) return true;
  if (forceIa && iaHasValue) return true;
  final acao = proximaAcao360?.acao.trim() ?? '';
  return acao.isNotEmpty;
}
