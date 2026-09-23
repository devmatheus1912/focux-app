import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../utils/checkin_execucao_display.dart';

class CheckinRestBanner extends StatelessWidget {
  final int seconds;
  final VoidCallback onSkip;
  final VoidCallback? onTrocar;

  const CheckinRestBanner({
    super.key,
    required this.seconds,
    required this.onSkip,
    this.onTrocar,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final mm = (seconds ~/ 60).toString().padLeft(1, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    final countdown = seconds >= 60 ? '$mm:$ss' : '$seconds';

    return Material(
      color: chrome.cardFill,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TokensStrip.s4,
            TokensStrip.s3,
            TokensStrip.s4,
            TokensStrip.s3,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Descanso',
                      style: FocuxHubTypography.chip(chrome.mute),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      countdown,
                      style: FocuxHubTypography.kpi(
                        color: chrome.ink,
                        fontSize: TokensStrip.fontH2,
                        fontWeight: FontWeight.w700,
                      ).copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: checkinExecutionControlMin + 8,
                child: FilledButton(
                  onPressed: onSkip,
                  style: FilledButton.styleFrom(
                    minimumSize: Size(
                      120,
                      checkinExecutionControlMin + 8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: TokensStrip.s3,
                    ),
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    checkinPularDescansoLabel(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (onTrocar != null) ...[
                const SizedBox(width: TokensStrip.s2),
                SizedBox(
                  height: checkinExecutionControlMin + 8,
                  child: TextButton(
                    onPressed: onTrocar,
                    style: TextButton.styleFrom(
                      minimumSize: Size(
                        72,
                        checkinExecutionControlMin + 8,
                      ),
                    ),
                    child: const Text('Trocar'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CheckinRestFocusView extends StatelessWidget {
  final int seconds;
  final int? totalSeconds;
  final VoidCallback onSkip;

  const CheckinRestFocusView({
    super.key,
    required this.seconds,
    required this.onSkip,
    this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final mm = (seconds ~/ 60).toString().padLeft(1, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    final countdown = seconds >= 60 ? '$mm:$ss' : '$seconds';
    final total = totalSeconds;
    final progress =
        total != null && total > 0
            ? (seconds / total).clamp(0.0, 1.0)
            : 1.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Descanso',
              style: FocuxHubTypography.sectionTitle(
                context,
                color: chrome.mute,
              ),
            ),
            const SizedBox(height: TokensStrip.s4),
            SizedBox(
              width: 168,
              height: 168,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FxLoading(
                    size: 168,
                    strokeWidth: 6,
                    value: progress,
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: chrome.mute.withValues(alpha: 0.15),
                  ),
                  Text(
                    countdown,
                    style: FocuxHubTypography.kpi(
                      color: chrome.ink,
                      fontSize: TokensStrip.fontH1,
                      fontWeight: FontWeight.w700,
                    ).copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TokensStrip.s2),
            Text(
              seconds >= 60 ? 'minutos restantes' : 'segundos restantes',
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
            const SizedBox(height: TokensStrip.s5),
            SizedBox(
              width: double.infinity,
              height: checkinExecutionControlMin + 8,
              child: FxLiquidPrimaryButton(
                label: checkinPularDescansoLabel(),
                onPressed: onSkip,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
