import '../../../l10n/pt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ia/models/ia_copilot_proxima_acao.dart';
import 'aluno360_operacao_logic.dart';
import '../data/aluno_repository.dart';

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
  });

  final String title;
  final String action;
  final String reason;
}

/// Os mesmos 8 campos de `FocuxScoreCalculator.cadastroFaltando` no backend.
int copilotProfileCompletion(Aluno aluno) {
  bool tem(String? valor) => (valor ?? '').trim().isNotEmpty;
  final fields = [
    tem(aluno.telefone),
    tem(aluno.whatsapp),
    tem(aluno.objetivo),
    tem(aluno.genero),
    aluno.peso != null,
    aluno.altura != null,
    aluno.dataNascimento != null,
    tem(aluno.fotoUrl),
  ];
  return ((fields.where((ok) => ok).length / fields.length) * 100).round();
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
  if (lower.contains('cadastro') ||
      lower.contains('mapa') ||
      lower.contains('corporal')) {
    return 'Completar cadastro para orientar a prescrição.';
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
  if (lower.contains('cadastro') ||
      lower.contains('mapa') ||
      lower.contains('corporal')) {
    return 'Completar cadastro';
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
  if (lower.contains('durm') ||
      lower.contains('sono') ||
      ((lower.contains('hora') ||
              lower.contains('horár') ||
              lower.contains('horar')) &&
          lower.contains('noite'))) {
    return 'Combinar sono';
  }
  return truncateCopilotStickyLabel(copilotDisplayAction(aluno, cleaned));
}


String copilotFallbackAction(Aluno aluno, AlunoAutonomiaResumo? resumo) {
  if (aluno.statusFinanceiro == 'INADIMPLENTE') {
    return 'Regularizar financeiro antes que isso vire atrito de acesso.';
  }
  if (copilotProfileCompletion(aluno) < 60) {
    return 'Completar perfil do aluno e remover lacunas de prescrição.';
  }
  return 'Revisar treino e propor a próxima evolução de ${aluno.objetivo ?? "objetivo"}.';
}


/// "Por quê": o motivo do backend em linhas, com a mesma conta de "Agora".
/// Sem motivo, só o que há de dado real no aluno.
List<String> copilotoFatos(Aluno aluno, {String? motivo}) {
  final texto = motivo?.trim() ?? '';
  if (texto.isNotEmpty) {
    return [
      for (final parte in texto.split(' · '))
        if (parte.trim().isNotEmpty)
          '${parte.trim()[0].toUpperCase()}${parte.trim().substring(1)}',
    ].take(3).toList();
  }
  final aderencia = aluno.aderenciaPercent;
  final dias = aluno.diasSemTreino;
  return [
    if (aderencia != null) ptS.copilotoFatoAderencia(aderencia),
    if (dias != null)
      switch (dias) {
        0 => ptS.copilotoFatoTreinouHoje,
        1 => ptS.copilotoFatoUltimoTreinoUm,
        _ => ptS.copilotoFatoUltimoTreinoN(dias),
      },
  ];
}

/// A ação da folha sai do tipo da sugestão, para o botão combinar com o texto.
OperacaoStickyAction copilotoAcaoDaSugestao(
  String? tipoAcao, {
  required OperacaoStickyAction padrao,
}) => switch (tipoAcao) {
  'CONTATO' || 'WEARABLE' => OperacaoStickyAction(
    label: ptS.copilotoEnviarMensagem,
    icon: Icons.chat_bubble_outline_rounded,
    destination: OperacaoStickyDestination.chat,
  ),
  'PERFIL' => OperacaoStickyAction(
    label: ptS.copilotoCompletarCadastro,
    icon: Icons.badge_outlined,
    destination: OperacaoStickyDestination.editAluno,
  ),
  'TREINO' => OperacaoStickyAction(
    label: ptS.copilotoAbrirFicha,
    icon: Icons.fitness_center_rounded,
    destination: OperacaoStickyDestination.treino,
  ),
  'FINANCEIRO' => OperacaoStickyAction(
    label: ptS.copilotoVerFinanceiro,
    icon: Icons.payments_outlined,
    destination: OperacaoStickyDestination.financeiro,
  ),
  _ => padrao,
};
