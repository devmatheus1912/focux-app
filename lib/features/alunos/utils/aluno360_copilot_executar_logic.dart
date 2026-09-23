import 'package:flutter/material.dart';

import '../../treinos/data/treino_repository.dart';
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

/// True se algum exercício do treino tem kg > 0.
bool treinoListaTemCargaNumerica(Iterable<Treino> treinos) {
  for (final treino in treinos) {
    for (final item in treino.exercicios) {
      final kg = item.cargaKg;
      if (kg != null && kg > 0) return true;
    }
  }
  return false;
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

bool _acaoSugereAjusteCarga(String? acao) {
  final lower = (acao ?? '').toLowerCase();
  if (lower.isEmpty) return false;
  // Só carga explícita — "progresso"/"ajuste de" sozinhos geravam falso positivo (#5).
  if (lower.contains('ajuste de carga') ||
      lower.contains('reduzir carga') ||
      lower.contains('aumentar carga') ||
      lower.contains('baixar carga') ||
      lower.contains('diminuir carga')) {
    return true;
  }
  return lower.contains('carga') &&
      (lower.contains('reduzir') ||
          lower.contains('aumentar') ||
          lower.contains('ajustar') ||
          lower.contains('abaixar'));
}

CopilotExecutarAcaoSpec? resolveCopilotExecutarAcao({
  required String? tipoAcao,
  required Aluno aluno,
  ProximaAcaoResumo? proxima,
  String? outreachMessage,
  bool? treinoTemCargaNumerica,
}) {
  final tipo = tipoAcao?.toUpperCase();
  final acao = proxima?.acao;

  // Ajuste de carga só quando a ação fala explicitamente de carga/progressão.
  if (_acaoSugereAjusteCarga(acao) || tipo == 'CARGA') {
    // Sem kg no treino ativo: não oferecer CTA que vira SEM_CARGA.
    if (treinoTemCargaNumerica == false) {
      return null;
    }
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
    acao: acao,
  );

  // TREINO / check-in → notificar ou abrir fluxo de contato — nunca carga.
  if (tipo == 'TREINO') {
    if (pushMessage != null) {
      return CopilotExecutarAcaoSpec(
        backendTipo: 'ENVIAR_PUSH',
        parametros: pushMessage,
        label: 'Pedir check-in ao aluno',
        icon: Icons.notifications_active_outlined,
        executingLabel: 'Enviando…',
        executingSemantics: 'Enviando pedido de check-in',
      );
    }
    return null;
  }

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

String? copilotExecutarBackendTipo(String? tipoAcao, {String? acao}) {
  if (_acaoSugereAjusteCarga(acao) || tipoAcao?.toUpperCase() == 'CARGA') {
    return 'REDUZIR_CARGA';
  }
  switch (tipoAcao?.toUpperCase()) {
    case 'TREINO':
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
  bool? treinoTemCargaNumerica,
}) =>
    resolveCopilotExecutarAcao(
      tipoAcao: tipoAcao,
      aluno: aluno,
      proxima: proxima,
      outreachMessage: outreachMessage,
      treinoTemCargaNumerica: treinoTemCargaNumerica,
    ) !=
    null;

String copilotExecutarAcaoLabel(String? tipoAcao, {String? acao}) {
  if (_acaoSugereAjusteCarga(acao) || tipoAcao?.toUpperCase() == 'CARGA') {
    return 'Aplicar ajuste de carga (−15%)';
  }
  switch (tipoAcao?.toUpperCase()) {
    case 'TREINO':
      return 'Pedir check-in ao aluno';
    case 'CONTATO':
    case 'WEARABLE':
      return 'Enviar notificação ao aluno';
    default:
      return 'Aplicar ação';
  }
}
