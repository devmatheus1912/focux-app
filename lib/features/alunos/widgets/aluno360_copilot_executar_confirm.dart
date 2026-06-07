import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../utils/aluno360_copilot_logic.dart';

/// Confirmation sheet before executing copilot actions (push, load adjust, risk).
Future<bool> showCopilotExecutarConfirmSheet(
  BuildContext context, {
  required CopilotExecutarAcaoSpec spec,
  required Color primary,
}) {
  final ink = fxScreenInk(context);
  final mute = fxScreenMute(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;

  String body;
  switch (spec.backendTipo) {
    case 'REDUZIR_CARGA':
      body =
          'Reduziremos ~15% das cargas do treino ativo e avisaremos o aluno por push.';
    case 'ENVIAR_PUSH':
      body =
          'Enviaremos uma notificação push ao aluno. Revise a mensagem antes de confirmar.';
    case 'MARCAR_RISCO':
      body =
          'Sinalizaremos risco operacional e enviaremos push pedindo contato do aluno.';
    default:
      body = 'Confirme para aplicar esta ação no perfil do aluno.';
  }

  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            4,
            16,
            16 + MediaQuery.paddingOf(sheetContext).bottom,
          ),
          child: ShellSurface(
            radius: TokensStrip.rCard,
            accent: primary,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(spec.icon, color: primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        spec.label,
                        style: TextStyle(
                          color: ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: TextStyle(color: mute, fontSize: 13, height: 1.35),
                ),
                if (spec.parametros != null && spec.parametros!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: isDark ? 0.12 : 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      spec.parametros!,
                      style: TextStyle(
                        color: ink,
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        icon: Icon(spec.icon, size: 17),
                        label: const Text('Confirmar'),
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  ).then((value) => value ?? false);
}
