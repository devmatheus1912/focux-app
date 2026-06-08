import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/aluno_360_layout.dart';
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

  final body = copilotExecutarConfirmBody(spec.backendTipo);

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
                        style: Aluno360Layout.panelTitleStyle(context, ink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: Aluno360Layout.captionStyle(context).copyWith(
                    color: mute,
                    height: 1.35,
                  ),
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
                      child: Semantics(
                        button: true,
                        label: 'Cancelar ação',
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(false),
                          child: const Text('Cancelar'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Semantics(
                        button: true,
                        label: 'Confirmar ${spec.label}',
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
