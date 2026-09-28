import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../l10n/app_localizations.dart';

/// Ficha atribuída sem exercícios: explica por que ainda não dá para iniciar.
Future<void> showTreinoPreparacaoSheet(
  BuildContext context, {
  required String treinoNome,
}) {
  final s = S.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primary = Theme.of(context).colorScheme.primary;
  final chrome = ShellChrome.forBrightness(context, isDark);

  return showFxHomeSheet<void>(
    context,
    builder:
        (sheetContext) => FxHomeSheetSurface(
          isDark: isDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: isDark),
              const SizedBox(height: TokensStrip.s4),
              FxHomeSheetHeader(
                isDark: isDark,
                title: treinoNome,
                subtitle: s.treinosDestaqueEmPreparacao,
                leading: Icon(
                  Icons.pending_actions_rounded,
                  color: primary,
                  size: 18,
                ),
              ),
              const SizedBox(height: TokensStrip.s4),
              Container(
                padding: const EdgeInsets.all(TokensStrip.s4),
                decoration: chrome.panel(accent: primary),
                child: Text(
                  s.treinosPreparacaoSheetTexto,
                  style: FocuxHubTypography.bodyMuted(
                    color: chrome.ink,
                    fontWeight: FontWeight.w600,
                    height: 1.42,
                  ),
                ),
              ),
              const SizedBox(height: TokensStrip.s4),
              FxLiquidPrimaryButton(
                label: s.treinosPreparacaoSheetCta,
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
  );
}
