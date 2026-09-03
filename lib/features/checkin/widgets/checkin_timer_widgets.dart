import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/focux_typography.dart';
import '../../../core/theme/shell_chrome.dart';

class CheckinRestTimerDock extends StatelessWidget {
  final int seconds;
  final int totalSeconds;
  final Color brand;
  final bool dark;
  final Color ink;
  final Color mute;
  final Color line;
  final VoidCallback onSkip;

  const CheckinRestTimerDock({
    super.key,
    required this.seconds,
    required this.totalSeconds,
    required this.brand,
    required this.dark,
    required this.ink,
    required this.mute,
    required this.line,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final fraction = totalSeconds <= 0 ? 0.0 : seconds / totalSeconds;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 160,
          height: 160,
          decoration: chrome
              .panel(radius: 20)
              .copyWith(
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 36,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(160, 160),
                painter: CheckinRestRingPainter(
                  fraction: fraction.clamp(0.0, 1.0),
                  color: brand,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DESCANSO',
                    style: FocuxHubTypography.chip(mute).copyWith(
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '$seconds',
                    style: FocuxTypography.display(color: ink).copyWith(
                      fontSize: 42,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    'seg',
                    style: FocuxHubTypography.bodyMuted(color: mute),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: brand,
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Pular'),
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

class CheckinRestRingPainter extends CustomPainter {
  final double fraction;
  final Color color;

  const CheckinRestRingPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = (size.width / 2) - 6;
    final trackPaint =
        Paint()
          ..color = color.withValues(alpha: 0.2)
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final activePaint =
        Paint()
          ..color = color
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, r, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(CheckinRestRingPainter old) => old.fraction != fraction;
}
