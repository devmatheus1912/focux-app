import 'package:flutter/material.dart';

import 'fx_shell_scaffold.dart';

/// Shared surface styling for operational KPI tiles (Aluno 360 + dashboard pulse).
/// Dashboard pulse chips remain tappable wrappers — see [DashboardPulseChip].
BoxDecoration operationalMetricDecoration({
  required Color accent,
  required bool isDark,
  double radius = 12,
}) {
  return BoxDecoration(
    color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: accent.withValues(alpha: isDark ? 0.24 : 0.16)),
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
  });

  final String label;
  final String value;
  final String hint;
  final Color color;
  final bool isDark;
  final String? semanticsLabel;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: operationalMetricDecoration(
        accent: color,
        isDark: isDark,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: mute,
              fontSize: 10,
              fontWeight: FontWeight.w700,
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
                  style: TextStyle(
                    color: ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          Text(hint, style: TextStyle(color: color, fontSize: 10.5)),
        ],
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
