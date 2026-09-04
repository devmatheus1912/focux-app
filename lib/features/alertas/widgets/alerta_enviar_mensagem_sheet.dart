import 'package:flutter/material.dart';

import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../utils/alerta_detalhe_display.dart';

/// Confirma o texto antes de POST `/api/alertas/aluno/{id}/mensagem-chat`.
Future<String?> showAlertaEnviarMensagemSheet(
  BuildContext context, {
  required String draft,
}) async {
  final ctrl = TextEditingController(text: draft);
  try {
    final ok = await showFxFormSheet(
      context,
      title: 'Enviar mensagem',
      subtitle: 'Revise antes de mandar. A sugestão não envia sozinha.',
      icon: Icons.send_rounded,
      confirmLabel: alertaEnviarMensagemCtaLabel(),
      child: TextField(
        controller: ctrl,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: 'Mensagem',
          border: FxInputDeco.outlineBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
    if (ok != true) return null;
    final text = ctrl.text.trim();
    return text.isEmpty ? null : text;
  } finally {
    ctrl.dispose();
  }
}
