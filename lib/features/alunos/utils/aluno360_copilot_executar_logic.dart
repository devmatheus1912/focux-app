import 'package:flutter/material.dart';

import '../data/aluno_repository.dart';
import 'aluno360_copilot_outreach_logic.dart';

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
