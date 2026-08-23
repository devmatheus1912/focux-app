import 'package:flutter/material.dart';

import '../theme/focux_hub_typography.dart';
import 'fx_shell_scaffold.dart';

/// Shared surface styling for operational KPI tiles (Aluno 360 + dashboard pulse).
/// Dashboard pulse chips remain tappable wrappers — see [DashboardPulseChip].
enum OperationalMetricEmphasis { normal, alert, muted }

BoxDecoration operationalMetricDecoration({
  required Color accent,
  required bool isDark,
  double radius = 12,
  OperationalMetricEmphasis emphasis = OperationalMetricEmphasis.normal,
}) {
  final bgAlpha = switch (emphasis) {
    OperationalMetricEmphasis.alert => isDark ? 0.16 : 0.11,
    OperationalMetricEmphasis.muted => isDark ? 0.08 : 0.06,
    OperationalMetricEmphasis.normal => isDark ? 0.12 : 0.08,
  };
  final borderAlpha = switch (emphasis) {
    OperationalMetricEmphasis.alert => isDark ? 0.36 : 0.28,
    OperationalMetricEmphasis.muted => isDark ? 0.18 : 0.12,
    OperationalMetricEmphasis.normal => isDark ? 0.24 : 0.16,
  };
  return BoxDecoration(
    color: accent.withValues(alpha: bgAlpha),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: accent.withValues(alpha: borderAlpha)),
  );
}

/// Display-only operational KPI tile shared by Aluno 360 and dashboard surfaces.
class OperationalMetricTile extends StatelessWidget {
  const OperationalMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.color,
    required this.isDark,
    this.semanticsLabel,
    this.leadingIcon,
    this.emphasis = OperationalMetricEmphasis.normal,
  });

  final String label;
  final String value;
  final String hint;
  final Color color;
  final bool isDark;
  final String? semanticsLabel;
  final IconData? leadingIcon;
  final OperationalMetricEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final labelColor = Color.lerp(ink, color, isDark ? 0.22 : 0.18)!;
    final hintColor = Color.lerp(mute, ink, isDark ? 0.55 : 0.72)!;
    final tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: operationalMetricDecoration(
        accent: color,
        isDark: isDark,
        emphasis: emphasis,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          if (emphasis == OperationalMetricEmphasis.alert) ...[
            Container(
              width: 3,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.88 : 0.78),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: FocuxHubTypography.chip(labelColor).copyWith(
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(leadingIcon, size: 17, color: color),
                      const SizedBox(width: 5),
                    ],
                    Flexible(
                      child: Text(
                        value,
                        style: FocuxHubTypography.kpi(
                          color: ink,
                          fontSize: FocuxHubTypography.metricMd,
                        ).copyWith(letterSpacing: 0.2),
                      ),
                    ),
                  ],
                ),
                Text(
                  hint,
                  style: FocuxHubTypography.bodyMuted(
                    color: hintColor,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );

    if (semanticsLabel == null) return tile;
    return Semantics(label: semanticsLabel, child: tile);
  }
}

IconData riscoMetricIcon(String? raw) {
  final value = (raw ?? '').trim().toUpperCase();
  return switch (value) {
    'ALTO' || 'HIGH' => Icons.warning_amber_rounded,
    'MEDIO' || 'MÉDIO' || 'MEDIUM' => Icons.error_outline_rounded,
    'BAIXO' || 'LOW' => Icons.check_circle_outline_rounded,
    _ => Icons.help_outline_rounded,
  };
}
