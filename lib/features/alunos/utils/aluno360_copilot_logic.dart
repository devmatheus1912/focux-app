import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../dashboard/data/command_center_data.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno_display_utils.dart';
import '../../health/data/health_repository.dart';

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
  final filled = fields.where((value) {
    if (value == null) return false;
    return value.trim().isNotEmpty;
  }).length;
  return ((filled / fields.length) * 100).round().clamp(0, 100);
}

String copilotCardTitle({required bool contactPriority}) =>
    contactPriority ? 'Prioridade do dia' : 'Próxima melhor ação';

Map<String, dynamic> copilotActionFrom360(ProximaAcaoResumo proxima) => {
  'titulo': proxima.fonte == 'RADAR'
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

Map<String, dynamic> copilotActionFromIa(Map<String, dynamic> action) {
  final raw =
      (action['acao'] ?? action['mensagem'] ?? action['descricao'] ?? '')
          .toString();
  final acao = normalizeIaCopilotAcao(raw);
  final motivoRaw =
      (action['motivo'] ?? 'Gerado com base nos sinais atuais do aluno.')
          .toString();
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
  required AsyncValue<Map<String, dynamic>>? iaAsync,
}) {
  if (forceIa && iaAsync != null) {
    return iaAsync.maybeWhen(
      data: (action) => proximaAcaoResumoFromIaPayload(
        action,
        fallback: proximaAcao360,
      ),
      orElse: () => proximaAcao360,
    );
  }
  return proximaAcao360;
}

ProximaAcaoResumo? proximaAcaoResumoFromIaPayload(
  Map<String, dynamic> action, {
  ProximaAcaoResumo? fallback,
}) {
  final raw =
      (action['acao'] ?? action['mensagem'] ?? action['descricao'] ?? '')
          .toString();
  final acao = normalizeIaCopilotAcao(raw);
  if (acao.isEmpty && raw.trim().isEmpty) return fallback;
  return ProximaAcaoResumo(
    acao: acao.isEmpty ? cleanCopilotText(raw) : acao,
    motivo: formatCopilotIaMotivo(
      (action['motivo'] ?? 'Gerado com base nos sinais atuais do aluno.')
          .toString(),
    ),
    fonte: 'IA',
    prioridade: 'P1',
    tipoAcao: action['tipoAcao'] as String?,
    mensagemSugerida: action['mensagemSugerida'] as String?,
    stickyLabel: action['stickyLabel'] as String?,
    stickyLabelCompact: action['stickyLabelCompact'] as String?,
    wearableRelevant: action['wearableRelevant'] as bool?,
  );
}

String resolveOutreachMessage(
  Aluno aluno, {
  required String acao,
  String? backendMessage,
  bool wearableRelevant = true,
}) {
  final trimmed = backendMessage?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    if (!wearableRelevant && _mensagemMencionaWearable(trimmed)) {
      return copilotMensagemPronta(
        aluno,
        contactPriorityOutreachAcao(),
        wearableRelevant: false,
      );
    }
    return sanitizeOutreachGenderTerms(trimmed, genero: aluno.genero);
  }
  return copilotMensagemPronta(
    aluno,
    acao,
    wearableRelevant: wearableRelevant,
  );
}

String contactPriorityOutreachAcao() => 'Contate o aluno para retomar treino.';

bool alunoTemHistoricoWearable(RecoverySnapshot? recovery) => recovery != null;

bool _mensagemMencionaWearable(String text) => copilotAcaoMencionaWearable(text);

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
  final acao = sanitizeCopilotAcaoWearable(resumo.acao, wearableRelevant: false);
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

/// Maps copilot UI action types to backend executar endpoint values.
class CopilotExecutarAcaoSpec {
  const CopilotExecutarAcaoSpec({
    required this.backendTipo,
    required this.label,
    required this.icon,
    required this.executingLabel,
    required this.executingSemantics,
    this.parametros,
  });

  final String backendTipo;
  final String label;
  final IconData icon;
  final String executingLabel;
  final String executingSemantics;
  final String? parametros;
}

/// Confirmation copy for copilot executar bottom sheet (testable).
String copilotExecutarConfirmBody(String backendTipo) {
  return switch (backendTipo) {
    'REDUZIR_CARGA' =>
      'Reduziremos cerca de 15% das cargas do treino ativo e avisaremos o aluno por notificação.',
    'ENVIAR_PUSH' =>
      'Enviaremos uma notificação ao aluno. Revise a mensagem antes de confirmar.',
    'MARCAR_RISCO' =>
      'Registraremos contato prioritário para hoje e notificaremos o aluno.',
    _ => 'Confirme para aplicar esta ação no perfil do aluno.',
  };
}

CopilotExecutarAcaoSpec? resolveCopilotExecutarAcao({
  required String? tipoAcao,
  required Aluno aluno,
  ProximaAcaoResumo? proxima,
  String? outreachMessage,
}) {
  final tipo = tipoAcao?.toUpperCase();
  if (tipo == 'TREINO') {
    return const CopilotExecutarAcaoSpec(
      backendTipo: 'REDUZIR_CARGA',
      label: 'Aplicar ajuste de carga (−15%)',
      icon: Icons.fitness_center_rounded,
      executingLabel: 'Aplicando…',
      executingSemantics: 'Aplicando ajuste de carga',
    );
  }

  final pushMessage = _copilotExecutarPushMessage(
    proxima: proxima,
    outreachMessage: outreachMessage,
    aluno: aluno,
    acao: proxima?.acao,
  );

  if (tipo == 'CONTATO' || tipo == 'WEARABLE') {
    if (pushMessage != null) {
      return CopilotExecutarAcaoSpec(
        backendTipo: 'ENVIAR_PUSH',
        parametros: pushMessage,
        label: 'Enviar notificação ao aluno',
        icon: Icons.notifications_active_outlined,
        executingLabel: 'Enviando…',
        executingSemantics: 'Enviando notificação ao aluno',
      );
    }
    if (aluno.emRisco) {
      return const CopilotExecutarAcaoSpec(
        backendTipo: 'MARCAR_RISCO',
        label: 'Registrar contato prioritário',
        icon: Icons.warning_amber_rounded,
        executingLabel: 'Registrando…',
        executingSemantics: 'Registrando contato prioritário',
      );
    }
  }

  if (aluno.emRisco && (tipo == 'GERAL' || tipo == null)) {
    return const CopilotExecutarAcaoSpec(
      backendTipo: 'MARCAR_RISCO',
      label: 'Registrar contato prioritário',
      icon: Icons.warning_amber_rounded,
      executingLabel: 'Registrando…',
      executingSemantics: 'Registrando contato prioritário',
    );
  }

  return null;
}

String? _copilotExecutarPushMessage({
  ProximaAcaoResumo? proxima,
  String? outreachMessage,
  required Aluno aluno,
  String? acao,
}) {
  final backend = proxima?.mensagemSugerida?.trim();
  if (backend != null && backend.isNotEmpty) return backend;
  final outreach = outreachMessage?.trim();
  if (outreach != null && outreach.isNotEmpty) return outreach;
  final action = acao?.trim();
  if (action != null && action.isNotEmpty) {
    return resolveOutreachMessage(aluno, acao: action);
  }
  return null;
}

String? copilotExecutarBackendTipo(String? tipoAcao) {
  switch (tipoAcao?.toUpperCase()) {
    case 'TREINO':
      return 'REDUZIR_CARGA';
    case 'CONTATO':
    case 'WEARABLE':
      return 'ENVIAR_PUSH';
    default:
      return null;
  }
}

bool shouldShowCopilotExecutarAcao({
  required String? tipoAcao,
  required Aluno aluno,
  ProximaAcaoResumo? proxima,
  String? outreachMessage,
}) =>
    resolveCopilotExecutarAcao(
      tipoAcao: tipoAcao,
      aluno: aluno,
      proxima: proxima,
      outreachMessage: outreachMessage,
    ) !=
    null;

String copilotExecutarAcaoLabel(String? tipoAcao) {
  switch (tipoAcao?.toUpperCase()) {
    case 'TREINO':
      return 'Aplicar ajuste de carga (−15%)';
    case 'CONTATO':
    case 'WEARABLE':
      return 'Enviar notificação ao aluno';
    default:
      return 'Aplicar ajuste';
  }
}

String cleanCopilotText(String value) {
  return value
      .replaceAll(RegExp(r'\*\*|__|`'), '')
      .replaceAll(RegExp(r'^\s*[-•]\s*', multiLine: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Fixes common English words leaked by LLMs into PT-BR coach copy.
String sanitizeCopilotIaLanguage(String text) {
  var result = text;
  const leaks = {
    'understanding': 'entender',
    'understand': 'entender',
    'personalized': 'personalizado',
    'customized': 'personalizado',
    'engagement': 'engajamento',
    'workout': 'treino',
    'training': 'treino',
    'schedule': 'cronograma',
    'interruption': 'interrupção',
    'discuss': 'discutir',
    'feedback': 'retorno',
    'follow-up': 'follow-up',
    'motivating': 'motivar',
    'reasons': 'motivos',
    'reason': 'motivo',
    'inactivity': 'inatividade',
  };
  for (final entry in leaks.entries) {
    result = result.replaceAll(
      RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false),
      entry.value,
    );
  }
  return result;
}

/// Splits copilot prescription footer into scannable segments.
List<String> copilotPrescriptionReasonSegments(String reason) {
  return reason
      .split(' · ')
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
}

bool isRedundantCopilotReasonSegment(
  String segment, {
  bool statusMetricsVisible = false,
  bool hideMetricFooter = false,
}) {
  final lower = segment.toLowerCase().trim();
  if (lower.isEmpty) return true;

  final metricNoise =
      lower.contains('aderência') ||
      lower.contains('aderencia') ||
      lower.contains('risco operacional') ||
      lower.contains('sem check-in') ||
      lower.contains('check-ins recentes') ||
      lower.contains('sem registro') ||
      lower.contains('últimos 7 dias') ||
      lower.contains('ultimos 7 dias') ||
      lower.contains('0 de 7') ||
      lower.contains('dias parados') ||
      lower.contains('dias sem treino') ||
      lower.contains('inativid') ||
      (lower.contains('priorize contato') && lower.contains('ader'));

  if (metricNoise || hideMetricFooter) return true;

  if (!statusMetricsVisible) return false;

  return lower.startsWith('priorize contato') ||
      lower.contains('evoluir o plano') ||
      lower.contains('contato direto hoje');
}

/// Hides metric bullets already visible in the status grid (non-focus mode).
String sanitizeCopilotPrescriptionReason(
  String reason, {
  required bool statusMetricsVisible,
  bool hideMetricFooter = false,
}) {
  if (reason.trim().isEmpty) return '';
  if (hideMetricFooter) return '';
  if (!statusMetricsVisible) return reason.trim();
  final segments =
      copilotPrescriptionReasonSegments(reason)
          .where(
            (segment) => !isRedundantCopilotReasonSegment(
              segment,
              statusMetricsVisible: true,
            ),
          )
          .toList(growable: false);
  if (segments.isEmpty) return '';
  return segments.join(' · ');
}

/// Strips LLM preambles so UI shows the actionable sentence, not boilerplate.
String normalizeIaCopilotAcao(String raw) {
  var text = sanitizeCopilotIaLanguage(cleanCopilotText(raw));
  if (text.isEmpty) return text;

  const preambles = [
    r'^a próxima ação mais importante é\s*',
    r'^a próxima ação mais importante:\s*',
    r'^a próxima melhor ação é\s*',
    r'^próxima ação:\s*',
    r'^sugiro que você\s*',
    r'^recomendo que você\s*',
    r'^recomendo\s*',
  ];
  for (final pattern in preambles) {
    text = text.replaceFirst(RegExp(pattern, caseSensitive: false), '');
  }
  text = text.trim();
  if (text.isEmpty) return cleanCopilotText(raw);
  return text[0].toUpperCase() + text.substring(1);
}

String humanizeCopilotMotivoDiasFragment(int dias, {String kind = 'atividade'}) {
  if (dias >= 90) return 'sem registro recente';
  if (dias == 0) return kind == 'treino' ? 'treinou hoje' : 'sem pausa hoje';
  if (dias == 1) {
    return kind == 'treino' ? '1 dia sem treino' : '1 dia parado';
  }
  return kind == 'treino' ? '$dias dias sem treino' : '$dias dias parados';
}

String _humanizeCopilotMotivoDiasInText(String text) {
  var result = text.replaceAllMapped(
    RegExp(r'(\d+) dia\(s\) sem (atividade|treino)', caseSensitive: false),
    (match) {
      final dias = int.tryParse(match.group(1)!) ?? 0;
      final kind = match.group(2)!.toLowerCase() == 'treino' ? 'treino' : 'atividade';
      return humanizeCopilotMotivoDiasFragment(dias, kind: kind);
    },
  );
  result = result.replaceAllMapped(
    RegExp(r'[Úú]ltima atividade há (\d+) dia\(s\)', caseSensitive: false),
    (match) {
      final dias = int.tryParse(match.group(1)!) ?? 0;
      return humanizeCopilotMotivoDiasFragment(dias, kind: 'treino');
    },
  );
  return result;
}

String formatCopilotIaMotivo(String motivo) {
  final trimmed = motivo.trim();
  if (trimmed.isEmpty) {
    return 'Gerado com base nos sinais atuais do aluno.';
  }

  final match = RegExp(
    r'[Úú]ltima atividade há (\d+) dia\(s\), aderência de (\d+)%',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (match != null) {
    final dias = int.tryParse(match.group(1)!) ?? 0;
    final aderencia = match.group(2)!;
    if (dias >= 90) {
      return 'Sem treinos recentes · aderência de $aderencia% nos últimos 30 dias.';
    }
    if (dias == 0) return 'Treinou hoje · aderência de $aderencia%.';
    if (dias == 1) return 'Último treino ontem · aderência de $aderencia%.';
    return 'Sem treino há $dias dias · aderência de $aderencia%.';
  }

  final contatoMatch = RegExp(
    r'Priorize contato · (\d+) dia\(s\) sem atividade · aderência (\d+)%',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (contatoMatch != null) {
    final dias = int.tryParse(contatoMatch.group(1)!) ?? 0;
    final aderencia = contatoMatch.group(2)!;
    final diasLabel = humanizeCopilotMotivoDiasFragment(dias);
    return 'Priorize contato · $diasLabel · aderência $aderencia%.';
  }

  return _humanizeCopilotMotivoDiasInText(trimmed);
}

String copilotChatActionLabel(String acao) {
  final lower = normalizeIaCopilotAcao(acao).toLowerCase();
  if (lower.contains('whatsapp')) return 'Enviar WhatsApp';
  if (lower.contains('mensagem')) return 'Enviar mensagem';
  if (copilotAcaoMencionaWearable(acao)) return 'Retomar contato';
  if (lower.contains('contato') ||
      lower.contains('contate') ||
      lower.contains('contatar') ||
      lower.contains('contactar') ||
      lower.contains('retomar') ||
      lower.contains('inativid') ||
      lower.contains('incentiv')) {
    return 'Retomar contato';
  }
  return 'Abrir chat';
}

String copilotMensagemPronta(
  Aluno aluno,
  String acao, {
  bool wearableRelevant = true,
}) {
  final primeiroNome =
      aluno.nome.trim().isEmpty
          ? 'tudo bem'
          : aluno.nome.trim().split(' ').first;
  final lower = cleanCopilotText(acao).toLowerCase();
  if (lower.contains('financeir') || lower.contains('inadimpl')) {
    return 'Oi, $primeiroNome. Preciso alinhar uma pendência rápida para manter seu acesso sem bloqueio. Me responde por aqui?';
  }
  if (lower.contains('perfil') || lower.contains('medida')) {
    return 'Oi, $primeiroNome. Quero completar alguns dados seus para ajustar melhor o plano. Me responde por aqui?';
  }
  if (lower.contains('treino') || lower.contains('carga')) {
    return 'Oi, $primeiroNome. Quero ajustar seu treino para o próximo passo com segurança. Me responde por aqui?';
  }
  if (wearableRelevant &&
      (copilotAcaoMencionaWearable(acao) || lower.contains('sincroniz'))) {
    return 'Oi, $primeiroNome. Vi que seu wearable não sincronizou. Consegue abrir o app e me dar um ok por aqui?';
  }
  if (lower.contains('inativid') ||
      lower.contains('incentiv') ||
      lower.contains('contate') ||
      lower.contains('contatar')) {
    final junto = retomarTreinoJuntoTerm(aluno.genero);
    return 'Oi, $primeiroNome. Notei sua ausência nos treinos. Quer retomar $junto? Me responde por aqui que eu ajusto o plano.';
  }
  return 'Oi, $primeiroNome. Notei que você se afastou um pouco dos treinos. Quer retomar? Me responde por aqui que eu ajusto o plano.';
}

String copilotCardSubtitle({
  required bool forceIa,
  required AsyncValue<Map<String, dynamic>>? iaAsync,
  required bool resumoLoading,
}) {
  if (forceIa && iaAsync != null) {
    return iaAsync.when(
      loading: () => 'Gerando sugestão com IA…',
      error: (_, __) => 'Sugestão do Aluno 360 · IA indisponível agora',
      data: (_) => 'Atualizado com IA · toque em atualizar para regenerar',
    );
  }
  if (resumoLoading) return 'Carregando sinais do perfil…';
  return 'Sugestão com base no perfil de hoje.';
}

String copilotDisplayAction(Aluno aluno, String acao) {
  final normalized = normalizeIaCopilotAcao(acao);
  final lower = normalized.toLowerCase();
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
  if (acaoSugereChat(normalized)) {
    if (normalized.length <= 140) return normalized;
    return '${copilotChatActionLabel(normalized)} com o aluno.';
  }
  if (normalized.length <= 140 && normalized.isNotEmpty) return normalized;
  return 'Retomar contato e ajustar plano com base na resposta.';
}

bool copilotAcaoMencionaWearable(String acao) {
  final lower = normalizeIaCopilotAcao(acao).toLowerCase();
  return lower.contains('wearable') ||
      lower.contains('apple health') ||
      lower.contains('google fit') ||
      lower.contains('sincroniz') ||
      lower.contains(' sync') ||
      lower.startsWith('sync') ||
      lower.contains('garmin') ||
      lower.contains('terra');
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
      acaoSugereChat(full) &&
      copilotAcaoMencionaWearable(full)) {
    return 'Retomar contato e pedir sync do wearable.';
  }
  if (acaoSugereChat(full)) {
    if (full.length <= 88) return full;
    final firstName = aluno.nome.trim().isEmpty
        ? null
        : aluno.nome.trim().split(' ').first;
    final contatoComNome =
        firstName == null
            ? 'Retomar contato e checar como está o treino.'
            : 'Retomar contato com $firstName e checar como está o treino.';
    if (lower.contains('inativid') ||
        lower.contains('reengaj') ||
        lower.contains('ausên') ||
        lower.contains('ausen') ||
        lower.contains('reaviv') ||
        lower.contains('aderência') ||
        lower.contains('aderencia')) {
      return contatoComNome;
    }
    if (lower.contains('check-in') || lower.contains('check in')) {
      return firstName == null
          ? 'Pedir check-in e entender como foi a semana.'
          : 'Pedir check-in com $firstName e entender como foi a semana.';
    }
    final label = copilotChatActionLabel(full);
    if (label != 'Abrir chat' && label != 'Retomar contato') {
      return firstName == null ? '$label com o aluno.' : '$label com $firstName.';
    }
    return contatoComNome;
  }

  final templated = copilotDisplayAction(aluno, sanitized);
  if (templated != full && full.length > 88) return templated;
  if (full.length <= 96) return full;
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
      lower.contains('inativid') ||
      lower.contains('incentiv') ||
      lower.contains('reengaj') ||
      lower.contains('retomar') ||
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
  final firstName = aluno.nome.trim().isEmpty
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
          profile >= 80
              ? 'dados bons para prescrição'
              : 'perfil incompleto',
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
  required AsyncValue<Map<String, dynamic>>? iaAsync,
  required String fallback,
}) {
  if (forceIa && iaAsync != null) {
    return iaAsync.maybeWhen(
      data: (action) {
        final raw =
            (action['acao'] ??
                    action['mensagem'] ??
                    action['descricao'] ??
                    fallback)
                .toString();
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
  final motivoRaw = (action['motivo'] ?? 'Baseado nos sinais atuais.')
      .toString();
  final isIa = (action['fonte'] ?? '').toString().toUpperCase() == 'IA';
  final sanitizedAcao = sanitizeCopilotAcaoWearable(
    rawAcao,
    wearableRelevant: wearableRelevant,
  );
  final fullAction = copilotPrescriptionFullAction(aluno, sanitizedAcao);
  final displayAction = copilotPrescriptionDisplayAction(
    aluno,
    sanitizedAcao,
    wearableRelevant: wearableRelevant,
  );
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
    fullAction:
        copilotPrescriptionActionsEquivalent(fullAction, displayAction)
            ? null
            : fullAction,
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
