import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/checkin_execucao_display.dart';

/// RPE gravado (1 a 10) -> o botão rápido mais próximo (4, 6 ou 8).
int? _rpeNoGrupo(int? rpe) {
  if (rpe == null) return null;
  if (rpe <= 5) return 4;
  if (rpe <= 7) return 6;
  return 8;
}

/// S8: um alvo — o tempo. Pular/Trocar são botões tonais na thumb zone.
class CheckinRestFocusView extends StatelessWidget {
  final int seconds;
  final int? totalSeconds;
  final String? contextLine;
  final VoidCallback onSkip;
  final VoidCallback? onTrocar;

  /// Soma ou tira segundos do descanso (±15 s).
  final ValueChanged<int>? onAjustar;

  /// Esforço da série que acabou (opcional): três toques, sem sair do descanso.
  final ValueChanged<int>? onRpe;
  final int? rpeEscolhido;
  final int? rpeAlvo;

  const CheckinRestFocusView({
    super.key,
    required this.seconds,
    required this.onSkip,
    this.totalSeconds,
    this.contextLine,
    this.onTrocar,
    this.onAjustar,
    this.onRpe,
    this.rpeEscolhido,
    this.rpeAlvo,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s5),
        child: Semantics(
          label: checkinRestSemanticsLabel(
            s,
            seconds: seconds,
            contextLine: contextText,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.checkinDescanso,
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
                      style: FocuxHubTypography.metric(
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
              if (onRpe != null) ...[
                const SizedBox(height: TokensStrip.s4),
                Text(
                  s.checkinRpeComoFoi,
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
                const SizedBox(height: TokensStrip.s2),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: TokensStrip.s2,
                  runSpacing: TokensStrip.s2,
                  children: [
                    for (final (rotulo, valor) in [
                      (s.checkinRpeLeve, 4),
                      (s.checkinRpeModerado, 6),
                      (s.checkinRpePesado, 8),
                    ])
                      FxToggleChip(
                        label: rotulo,
                        selected: _rpeNoGrupo(rpeEscolhido) == valor,
                        isDark: chrome.isDark,
                        filledWhenSelected: true,
                        onTap: () => onRpe!(valor),
                      ),
                  ],
                ),
                if (rpeAlvo != null) ...[
                  const SizedBox(height: TokensStrip.s1),
                  Text(
                    s.checkinRpeAlvoCurto(rpeAlvo!),
                    style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                  ),
                ],
              ],
              const SizedBox(height: TokensStrip.s5),
              if (onAjustar != null) ...[
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: TokensStrip.s2,
                  children: [
                    FxTonalButton(
                      label: s.checkinDescansoMenos15,
                      icon: Icons.remove_rounded,
                      compact: true,
                      onPressed: () => onAjustar!(-15),
                    ),
                    FxTonalButton(
                      label: s.checkinDescansoMais15,
                      icon: Icons.add_rounded,
                      compact: true,
                      onPressed: () => onAjustar!(15),
                    ),
                  ],
                ),
                const SizedBox(height: TokensStrip.s2),
              ],
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  FxTonalButton(
                    label: s.checkinPularDescanso,
                    icon: Icons.skip_next_rounded,
                    onPressed: onSkip,
                  ),
                  if (onTrocar != null)
                    FxTonalButton(
                      label: s.checkinTrocar,
                      icon: Icons.swap_horiz_rounded,
                      onPressed: onTrocar,
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
