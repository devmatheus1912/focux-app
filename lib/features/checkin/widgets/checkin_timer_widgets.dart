import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_motion.dart';
import '../utils/checkin_execucao_display.dart';

class CheckinRestBanner extends StatelessWidget {
  final int seconds;
  final VoidCallback onSkip;

  const CheckinRestBanner({
    super.key,
    required this.seconds,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Material(
      color: chrome.cardFill,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TokensStrip.s4,
          TokensStrip.s2,
          TokensStrip.s4,
          TokensStrip.s2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Descanso · ${seconds}s',
                style: FocuxHubTypography.sectionTitle(
                  context,
                  color: chrome.ink,
                ),
              ),
            ),
            SizedBox(
              height: checkinExecutionControlMin,
              child: TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  minimumSize: const Size(64, checkinExecutionControlMin),
                ),
                child: Text(checkinPularDescansoLabel()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckinRestFocusView extends StatelessWidget {
  final int seconds;
  final VoidCallback onSkip;

  const CheckinRestFocusView({
    super.key,
    required this.seconds,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
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
            const SizedBox(height: TokensStrip.s3),
            Text(
              '$seconds',
              style: FocuxHubTypography.kpi(
                color: chrome.ink,
                fontSize: TokensStrip.fontH1,
                fontWeight: FontWeight.w600,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            const SizedBox(height: TokensStrip.s2),
            Text(
              'segundos',
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
            const SizedBox(height: TokensStrip.s5),
            SizedBox(
              height: checkinExecutionControlMin,
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
