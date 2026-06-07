import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
/// Layout tokens for Aluno 360 (hero, sticky CTA, scroll insets).
abstract final class Aluno360Layout {
  Aluno360Layout._();

  static const double screenPadding = 16;
  static const double sectionGap = 12;
  static const double cardPadding = 14;
  static const double tabBarHeight = 44;
  static const double tabContentGap = 0;
  static const double stickyBarContentHeight = 56;
  static const double snackbarStickyReserve = 72;

  /// Identity strip height (compact strip + padding at textScale ≤ 1.25).
  static double heroBodyHeight(
    BuildContext context, {
    bool compactContactPriority = false,
  }) {
    final textScale =
        MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    final base = compactContactPriority ? 52.0 : 70.0;
    return base + ((textScale - 1) * 20);
  }

  /// Status bar + toolbar + tab bar (header collapsed).
  static double heroHeaderMinExtent(BuildContext context) {
    return MediaQuery.paddingOf(context).top + kToolbarHeight + tabBarHeight;
  }

  /// Collapsed header + identity strip body.
  static double heroHeaderMaxExtent(
    BuildContext context, {
    bool compactContactPriority = false,
  }) {
    return heroHeaderMinExtent(context) +
        heroBodyHeight(
          context,
          compactContactPriority: compactContactPriority,
        );
  }

  /// @deprecated Use [heroHeaderMaxExtent].
  static double heroExpandedHeight(
    BuildContext context, {
    bool compactContactPriority = false,
  }) =>
      heroHeaderMaxExtent(
        context,
        compactContactPriority: compactContactPriority,
      );

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

  /// Nested prescription block inside the copilot card (inset + optional IA accent).
  static BoxDecoration operacaoPrescriptionDecoration(
    BuildContext context, {
    required Color primary,
    required bool isDark,
    bool iaAccent = false,
  }) {
    final base = operacaoInsetSectionDecoration(
      context,
      primary: primary,
      isDark: isDark,
    );
    if (!iaAccent) return base;
    return base.copyWith(
      border: Border.all(
        color: primary.withValues(alpha: isDark ? 0.22 : 0.16),
      ),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: isDark ? 0.08 : 0.05),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  /// Inset surface shared by Operação follow-up + status cards (teal tint).
  static BoxDecoration operacaoInsetSectionDecoration(
    BuildContext context, {
    required Color primary,
    required bool isDark,
  }) {
    final line = ShellChrome.of(context).line;
    return BoxDecoration(
      color:
          isDark
              ? Colors.white.withValues(alpha: 0.04)
              : primary.withValues(alpha: 0.035),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark ? line : line.withValues(alpha: 0.85),
      ),
    );
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
