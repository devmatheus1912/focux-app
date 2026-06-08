import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';

class CheckinLiveCoachingCard extends StatelessWidget {
  final Color brand;
  final Color brandDeep;
  final bool dark;
  final VoidCallback onApply;
  final VoidCallback onSkip;

  const CheckinLiveCoachingCard({super.key, 
    required this.brand,
    required this.brandDeep,
    required this.dark,
    required this.onApply,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              dark ? [brandDeep, const Color(0xFF0F1A3C)] : [brand, brandDeep],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'IA FOCUX | SUGESTAO AO VIVO',
                style: TextStyle(
                  color: Color(0xD9FFFFFF),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Use o coach de execucao ou a camera MediaPipe para contar reps e manter a tecnica. Registre feedback apos cada serie.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.42,
            ),
          ),
          const SizedBox(height: TokensStrip.s4),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onApply,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: brand,
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text('Registrar ajuste'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onSkip,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.32)),
                  minimumSize: const Size(92, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Ignorar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CheckinRestTimerDock extends StatelessWidget {
  final int seconds;
  final int totalSeconds;
  final Color brand;
  final bool dark;
  final Color ink;
  final Color mute;
  final Color line;
  final VoidCallback onSkip;

  const CheckinRestTimerDock({super.key, 
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
          decoration: chrome.panel(radius: 20).copyWith(
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
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: mute,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '$seconds',
                    style: AppTypography.inter(
                      fontSize: 42,
                      fontWeight: FontWeight.w600,
                      color: ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text('seg', style: TextStyle(fontSize: 12, color: mute)),
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

