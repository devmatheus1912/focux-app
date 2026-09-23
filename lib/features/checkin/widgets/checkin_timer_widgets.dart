import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
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
    final primary = Theme.of(context).colorScheme.primary;
    final brand = chrome.isDark ? BrandPalette.accent(primary) : primary;
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
        child: Semantics(
          label: checkinRestSemanticsLabel(
            seconds: seconds,
            contextLine: contextText,
          ),
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
                    ExcludeSemantics(
                      child: CustomPaint(
                        size: const Size.square(checkinRestRingSize),
                        painter: _CheckinRestRingPainter(
                          progress: progress,
                          color: brand,
                          trackColor: chrome.mute.withValues(alpha: 0.14),
                          strokeWidth: TokensStrip.s2,
                        ),
                      ),
                    ),
                    Text(
                      countdown,
                      style: FocuxHubTypography.kpi(
                        color: chrome.ink,
                        fontSize: TokensStrip.fontH1,
                        fontWeight: FontWeight.w700,
                      ).copyWith(
                        letterSpacing: TokensStrip.trackingH1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              if (hasContext) ...[
                const SizedBox(height: TokensStrip.s3),
                Text(
                  contextText,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
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
      ),
    );
  }
}

class _CheckinRestRingPainter extends CustomPainter {
  const _CheckinRestRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final track =
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
    final fill =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      (progress.clamp(0.0, 1.0)) * math.pi * 2,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _CheckinRestRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
