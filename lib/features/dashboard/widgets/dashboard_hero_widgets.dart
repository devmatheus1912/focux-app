import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/dashboard_readability.dart';
class DashboardHeroProgressRail extends StatelessWidget {
  const DashboardHeroProgressRail({
    super.key,
    required this.progress,
    required this.glow,
    this.exceeded = false,
    this.percentLabel,
    this.excessBeyondMeta = 0,
  });

  final double progress;
  final Color glow;
  final bool exceeded;
  final String? percentLabel;
  final double excessBeyondMeta;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final displayProgress = exceeded ? 1.0 : clamped;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (percentLabel != null)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              percentLabel!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        if (percentLabel != null) const SizedBox(height: 5),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final fillWidth = width * displayProgress;

            return SizedBox(
              height: exceeded ? 12 : 14,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: Colors.white.withValues(
                        alpha: exceeded ? 0.20 : 0.14,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: exceeded ? 0.30 : 0.20,
                        ),
                      ),
                    ),
                  ),
                  if (fillWidth > 2)
                    Positioned(
                      left: 0,
                      width: fillWidth,
                      height: exceeded ? 10 : 10,
                      top: exceeded ? 1 : 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: LinearGradient(
                            colors:
                                exceeded
                                    ? [
                                      Colors.white.withValues(alpha: 0.65),
                                      Colors.white.withValues(alpha: 0.95),
                                    ]
                                    : [
                                      Colors.white.withValues(alpha: 0.58),
                                      Colors.white.withValues(alpha: 0.86),
                                      glow.withValues(alpha: 0.88),
                                    ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(
                                alpha: exceeded ? 0.48 : 0.36,
                              ),
                              blurRadius: exceeded ? 16 : 12,
                              spreadRadius: exceeded ? 1 : 0,
                            ),
                            BoxShadow(
                              color: glow.withValues(
                                alpha: exceeded ? 0.72 : 0.58,
                              ),
                              blurRadius: exceeded ? 22 : 18,
                              spreadRadius: exceeded ? 2 : 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (exceeded && excessBeyondMeta > 0)
                    Positioned(
                      right: -6,
                      top: exceeded ? -1 : 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < 3; i++)
                            Container(
                              width: 5,
                              height: exceeded ? 12 : 10,
                              margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(99),
                                color: Colors.white.withValues(
                                  alpha: 0.92 - (i * 0.22),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: glow.withValues(alpha: 0.55),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class DashboardHeroMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  const DashboardHeroMiniStat({
    super.key,
    required this.label,
    required this.value,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: dashboardHeroLabelOnTeal(),
            fontSize: 10.5,
            letterSpacing: 0.08,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: value),
              if (suffix != null)
                TextSpan(
                  text: suffix,
                  style: TextStyle(
                    fontSize: 12,
                    color: dashboardHeroCaptionOnTeal(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
class DashboardHeroGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
          ..strokeWidth = 0.5;

    for (double x = 0; x <= size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
