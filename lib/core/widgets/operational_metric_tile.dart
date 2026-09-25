import 'package:flutter/material.dart';

import '../theme/focux_hub_typography.dart';
import '../theme/tokens_strip.dart';
import 'fx_shell_scaffold.dart';

/// Shared surface styling for operational KPI tiles (Aluno 360).
enum OperationalMetricEmphasis { normal, alert, muted }

BoxDecoration operationalMetricDecoration({
  required Color accent,
  required bool isDark,
  double radius = TokensStrip.rCard,
  OperationalMetricEmphasis emphasis = OperationalMetricEmphasis.normal,
}) {
  // Vidro neutro (§2/§6): cor semântica só na borda do alerta, nunca no fill.
  final border =
      emphasis == OperationalMetricEmphasis.alert
          ? accent.withValues(alpha: isDark ? 0.46 : 0.38)
          : TokensStrip.glassBorder(dark: isDark);
  return BoxDecoration(
    color: TokensStrip.glassFill(dark: isDark),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border),
  );
}

/// Display-only operational KPI tile shared by Aluno 360 and dashboard surfaces.
class OperationalMetricTile extends StatelessWidget {
  const OperationalMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.hint = '',
    required this.color,
    required this.isDark,
    this.semanticsLabel,
    this.leadingIcon,
    this.emphasis = OperationalMetricEmphasis.normal,
    this.dense = false,
    this.onInfo,
  });

  /// Tile inteiro abre a explicação da métrica (glyph `?` ao lado do rótulo).
  final VoidCallback? onInfo;

  final String label;
  final String value;
  final String hint;
  final Color color;
  final bool isDark;
  final String? semanticsLabel;
  final IconData? leadingIcon;
  final OperationalMetricEmphasis emphasis;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final labelColor = Color.lerp(ink, color, isDark ? 0.22 : 0.18)!;
    final hintColor = Color.lerp(mute, ink, isDark ? 0.55 : 0.72)!;
    // Alert = warn fill/borda mais fortes; sem rail lateral (alinha o stack
    // de métricas na Home — §11 secundário não compete com P0).
    final tile = Container(
      padding: EdgeInsets.symmetric(
        horizontal: TokensStrip.s3,
        vertical: dense ? TokensStrip.s2 : TokensStrip.s3,
      ),
      decoration: operationalMetricDecoration(
        accent: color,
        isDark: isDark,
        emphasis: emphasis,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  style: FocuxHubTypography.chip(labelColor).copyWith(
                    letterSpacing: 0.4,
                    fontSize: dense ? 10 : null,
                  ),
                ),
              ),
              if (onInfo != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.help_outline_rounded,
                  size: dense ? 13 : 15,
                  color: labelColor,
                ),
              ],
            ],
          ),
          SizedBox(height: dense ? 2 : 4),
          Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: dense ? 15 : 17, color: color),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  value,
                  maxLines: dense ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: FocuxHubTypography.kpi(
                    color: ink,
                    fontSize: dense ? FocuxHubTypography.metricEm : FocuxHubTypography.metricMd,
                  ).copyWith(letterSpacing: 0.2),
                ),
              ),
            ],
          ),
          if (hint.trim().isNotEmpty)
            Text(
              hint,
              maxLines: dense ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: FocuxHubTypography.bodyMuted(
                color: hintColor,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ).copyWith(fontSize: dense ? 11.5 : null),
            ),
        ],
      ),
    );

    final info = onInfo;
    final body =
        info == null
            ? tile
            : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: info,
                borderRadius: BorderRadius.circular(12),
                child: tile,
              ),
            );
    if (semanticsLabel == null && info == null) return body;
    return Semantics(
      label: semanticsLabel,
      button: info != null,
      hint: info != null ? 'Toque para entender a métrica' : null,
      child: body,
    );
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
