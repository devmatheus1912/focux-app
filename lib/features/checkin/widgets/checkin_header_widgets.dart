import 'package:flutter/material.dart';

import '../../../core/widgets/fx_tonal_button.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/focux_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/checkin_execucao_display.dart';

class CheckinWorkoutHeader extends StatelessWidget {
  final String treinoNome;
  final String contextLine;
  final VoidCallback onBack;
  final VoidCallback? onHelp;

  /// Abre as ações do exercício (ajustar, confirmar séries, finalizar).
  final VoidCallback? onMais;

  const CheckinWorkoutHeader({
    super.key,
    required this.treinoNome,
    required this.contextLine,
    required this.onBack,
    this.onHelp,
    this.onMais,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          TokensStrip.s3,
          TokensStrip.s3,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    treinoNome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.sectionTitle(
                      context,
                      color: chrome.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contextLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxTypography.bodySmall(color: chrome.mute),
                  ),
                ],
              ),
            ),
            if (onHelp != null)
              FxHelpIconButton(
                tooltip: s.checkinDicasExercicio,
                onTap: onHelp!,
                expandHitTarget: true,
              ),
            if (onMais != null)
              SizedBox(
                height: checkinExecutionControlMin,
                child: Center(
                  child: IconButton(
                    tooltip: s.checkinMais,
                    onPressed: onMais,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      side: BorderSide(
                        color: chrome.mute.withValues(alpha: 0.35),
                      ),
                    ),
                    icon: Icon(Icons.more_horiz_rounded, color: chrome.ink),
                  ),
                ),
              ),
            SizedBox(
              height: checkinExecutionControlMin,
              child: Center(
                child: FxTonalButton(
                  label: s.checkinSair,
                  icon: Icons.logout_rounded,
                  compact: true,
                  onPressed: onBack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
