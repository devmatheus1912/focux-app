import 'package:flutter/material.dart';


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




