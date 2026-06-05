import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../dashboard/data/command_center_data.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno_display_utils.dart';

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
  });

  final String title;
  final String action;
  final String reason;
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
      data: (action) {
        final raw =
            (action['acao'] ?? action['mensagem'] ?? action['descricao'] ?? '')
                .toString();
        final acao = normalizeIaCopilotAcao(raw);
        if (acao.isEmpty && raw.trim().isEmpty) return proximaAcao360;
        return ProximaAcaoResumo(
          acao: acao.isEmpty ? cleanCopilotText(raw) : acao,
          motivo: formatCopilotIaMotivo(
            (action['motivo'] ??
                    'Gerado com base nos sinais atuais do aluno.')
                .toString(),
          ),
          fonte: 'IA',
          prioridade: 'P1',
        );
      },
      orElse: () => proximaAcao360,
    );
  }
  return proximaAcao360;
}

String cleanCopilotText(String value) {
  return value
      .replaceAll(RegExp(r'\*\*|__|`'), '')
      .replaceAll(RegExp(r'^\s*[-•]\s*', multiLine: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Strips LLM preambles so UI shows the actionable sentence, not boilerplate.
String normalizeIaCopilotAcao(String raw) {
  var text = cleanCopilotText(raw);
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
    if (dias >= 90 || dias == 999) {
      return 'Sem treinos recentes · aderência de $aderencia% nos últimos 30 dias.';
    }
    if (dias == 0) return 'Treinou hoje · aderência de $aderencia%.';
    if (dias == 1) return 'Último treino ontem · aderência de $aderencia%.';
    return 'Sem treino há $dias dias · aderência de $aderencia%.';
  }
  return trimmed;
}

String copilotChatActionLabel(String acao) {
  final lower = normalizeIaCopilotAcao(acao).toLowerCase();
  if (lower.contains('whatsapp')) return 'Enviar WhatsApp';
  if (lower.contains('mensagem')) return 'Enviar mensagem';
  if (lower.contains('contato') || lower.contains('retomar')) {
    return 'Retomar contato';
  }
  return 'Abrir chat';
}

String copilotMensagemPronta(Aluno aluno, String acao) {
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
  return 'Oi, $primeiroNome. Notei que você se afastou um pouco dos treinos. Quer retomar? Me responde por aqui que eu ajusto o plano.';
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
    return '${copilotChatActionLabel(normalized)} com mensagem objetiva.';
  }
  if (normalized.length <= 140 && normalized.isNotEmpty) return normalized;
  return 'Retomar contato e ajustar plano com base na resposta.';
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
      lower.contains('follow-up') ||
      lower.contains('follow up') ||
      lower.contains('whatsapp');
}

/// Short label shared by sticky bar and prescription action line.
String copilotStickyLabel(Aluno aluno, String acao) {
  final cleaned = normalizeIaCopilotAcao(acao);
  if (cleaned.isEmpty) return 'Ver próxima ação';
  final lower = cleaned.toLowerCase();
  if (lower.contains('mapa') || lower.contains('corporal')) {
    return 'Completar mapa corporal';
  }
  if (lower.contains('objetivo')) return 'Definir objetivo';
  if (acaoSugereChat(cleaned)) return copilotChatActionLabel(cleaned);
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
  String fallback,
) {
  final rawAcao =
      (action['acao'] ?? action['mensagem'] ?? action['descricao'] ?? fallback)
          .toString();
  final motivoRaw = (action['motivo'] ?? 'Baseado nos sinais atuais.')
      .toString();
  final isIa = (action['fonte'] ?? '').toString().toUpperCase() == 'IA';
  return CopilotPrescriptionContent(
    title:
        (action['titulo'] ?? action['tipo'] ?? 'Próxima melhor ação')
            .toString(),
    action: copilotDisplayAction(aluno, rawAcao),
    reason: isIa ? formatCopilotIaMotivo(motivoRaw) : motivoRaw,
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
