import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../dashboard/data/command_center_data.dart';
import '../data/aluno_repository.dart';

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
              : 'Próxima melhor ação',
  'acao': proxima.acao,
  'motivo': proxima.motivo,
  'fonte': proxima.fonte,
  'prioridade': proxima.prioridade,
};

String cleanCopilotText(String value) {
  return value
      .replaceAll(RegExp(r'\*\*|__|`'), '')
      .replaceAll(RegExp(r'^\s*[-•]\s*', multiLine: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
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
  final lower = cleanCopilotText(acao).toLowerCase();
  if (lower.contains('financeir') || lower.contains('inadimpl')) {
    return 'Alinhar pendência financeira antes de qualquer ajuste.';
  }
  if (lower.contains('perfil') || lower.contains('medida')) {
    return 'Completar dados do perfil para melhorar a prescrição.';
  }
  if (lower.contains('treino') || lower.contains('carga')) {
    return 'Ajustar treino e orientar próximo check-in.';
  }
  return 'Retomar contato e ajustar plano com base na resposta.';
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
              : 'faltam dados que melhoram decisão',
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
      data:
          (action) => cleanCopilotText(
            (action['acao'] ??
                    action['mensagem'] ??
                    action['descricao'] ??
                    fallback)
                .toString(),
          ),
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
  return CopilotPrescriptionContent(
    title:
        (action['titulo'] ?? action['tipo'] ?? 'Próxima melhor ação')
            .toString(),
    action: copilotDisplayAction(
      aluno,
      (action['acao'] ?? action['mensagem'] ?? action['descricao'] ?? fallback)
          .toString(),
    ),
    reason: (action['motivo'] ?? 'Baseado nos sinais atuais.').toString(),
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
