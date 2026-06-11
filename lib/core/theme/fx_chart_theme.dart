import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'tokens_strip.dart';

/// Tokens para gráficos (fl_chart, sparklines, barras custom).
abstract class FxChartTheme {
  static Color seriesPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static Color seriesMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? EagleTokens.textSecondaryDark
          : EagleTokens.textSecondary;

  static Color gridLine(BuildContext context) =>
      Theme.of(context).dividerColor.withValues(alpha: 0.35);

  static const double labelFontSize = TokensStrip.fontBodySm;

  static TextStyle axisLabel(BuildContext context) => TextStyle(
        fontSize: labelFontSize,
        color: seriesMuted(context),
        fontWeight: FontWeight.w600,
      );

  static TextStyle valueLabel(BuildContext context) => TextStyle(
        fontSize: TokensStrip.fontBody,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      );

  static List<Color> donutPalette(BuildContext context) => [
        seriesPrimary(context),
        seriesPrimary(context).withValues(alpha: 0.65),
        EagleTokens.brandSoft,
        seriesMuted(context),
      ];
}
