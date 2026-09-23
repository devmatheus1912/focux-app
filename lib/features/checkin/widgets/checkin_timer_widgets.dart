import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../utils/checkin_execucao_display.dart';

/// S8: um alvo — o tempo. Pular/Trocar ficam texto na thumb zone.
class CheckinRestFocusView extends StatelessWidget {
  final int seconds;
  final int? totalSeconds;
  final String? contextLine;
  final VoidCallback onSkip;
  final VoidCallback? onTrocar;

  const CheckinRestFocusView({
    super.key,
    required this.seconds,
    required this.onSkip,
    this.totalSeconds,
    this.contextLine,
    this.onTrocar,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final countdown = checkinRestCountdownLabel(seconds);
    final total = totalSeconds;
    final progress =
        total != null && total > 0
            ? (seconds / total).clamp(0.0, 1.0)
            : 1.0;
    final contextText = contextLine?.trim();
    final hasContext = contextText != null && contextText.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Descanso',
              style: FocuxHubTypography.chip(chrome.mute),
            ),
            const SizedBox(height: TokensStrip.s4),
            SizedBox(
              width: checkinRestRingSize,
              height: checkinRestRingSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FxLoading(
                    size: checkinRestRingSize,
                    strokeWidth: TokensStrip.s2,
                    value: progress,
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: chrome.mute.withValues(alpha: 0.14),
                  ),
                  Text(
                    countdown,
                    style: FocuxHubTypography.kpi(
                      color: chrome.ink,
                      fontSize: TokensStrip.fontH1,
                      fontWeight: FontWeight.w700,
                    ).copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: -0.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TokensStrip.s3),
            Text(
              checkinRestRemainingCaption(seconds),
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
            if (hasContext) ...[
              const SizedBox(height: TokensStrip.s1),
              Text(
                contextText,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FocuxHubTypography.bodyMuted(
                  color: chrome.mute,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: TokensStrip.s5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    minimumSize: Size(
                      88,
                      checkinExecutionControlMin + 8,
                    ),
                  ),
                  child: Text(checkinPularDescansoLabel()),
                ),
                if (onTrocar != null)
                  TextButton(
                    onPressed: onTrocar,
                    style: TextButton.styleFrom(
                      minimumSize: Size(
                        72,
                        checkinExecutionControlMin + 8,
                      ),
                    ),
                    child: const Text('Trocar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
