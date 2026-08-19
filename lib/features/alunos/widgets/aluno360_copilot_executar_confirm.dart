import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
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

  return showFxHomeSheet<bool>(
    context,
    builder: (sheetContext) {
      return FxHomeSheetSurface(
        isDark: isDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FxHomeSheetHandle(isDark: isDark),
            SizedBox(height: TokensStrip.s4),
            FxHomeSheetHeader(
              isDark: isDark,
              title: spec.label,
              leading: Icon(spec.icon, color: primary, size: 18),
            ),
            SizedBox(height: TokensStrip.s3),
            Text(
              body,
              style: Aluno360Layout.captionStyle(
                context,
              ).copyWith(color: mute, height: 1.35),
            ),
            if (spec.parametros != null && spec.parametros!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: isDark ? 0.12 : 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primary.withValues(alpha: 0.18)),
                ),
                child: Text(
                  spec.parametros!,
                  style: Aluno360Layout.bodyEmphasisStyle(context, ink),
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
      );
    },
  ).then((value) => value ?? false);
}
