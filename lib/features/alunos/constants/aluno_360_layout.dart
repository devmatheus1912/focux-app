import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
/// Layout tokens for Aluno 360 (hero, sticky CTA, scroll insets).
abstract final class Aluno360Layout {
  Aluno360Layout._();

  static const double screenPadding = 16;
  static const double sectionGap = 10;
  static const double cardPadding = 14;
  static const double tabBarHeight = 44;
  static const double stickyBarContentHeight = 56;

  /// Approximate hero card body (matches [AlunoDetailHeroCard] at textScale ≤ 1.25).
  static double heroBodyHeight(BuildContext context) {
    final textScale =
        MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.25);
    return 106 + ((textScale - 1) * 28);
  }

  /// Toolbar inset + hero card + bottom padding — no dead gap above the card.
  static double heroExpandedHeight(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return top + kToolbarHeight + 2 + heroBodyHeight(context) + 4;
  }

  /// Pinned toolbar + tab bar (content should not scroll under this stack).
  static double pinnedHeaderHeight(BuildContext context) {
    return MediaQuery.paddingOf(context).top + kToolbarHeight + tabBarHeight;
  }

  /// Bottom padding so Operação content clears the sticky CTA bar.
  static double operacaoScrollBottomReserve(BuildContext context) {
    return stickyBarContentHeight +
        MediaQuery.paddingOf(context).bottom +
        40;
  }

  /// WCAG-friendly caption for cards (min 12px, gray-700 on light).
  static TextStyle captionStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 12,
      height: 1.35,
      fontWeight: FontWeight.w500,
      color:
          isDark
              ? EagleTokens.darkInk.withValues(alpha: 0.82)
              : const Color(0xFF374151),
    );
  }

  /// Secondary metadata — still ≥11.5px with stronger contrast.
  static TextStyle metaStyle(BuildContext context) {
    return captionStyle(context).copyWith(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
    );
  }
}
