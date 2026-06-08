import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';

/// Layout tokens for Aluno 360 (hero, sticky CTA, scroll insets).
abstract final class Aluno360Layout {
  Aluno360Layout._();

  static const double screenPadding = 16;
  static const double sectionGap = 12;
  static const double cardPadding = 14;
  static const double tabBarHeight = 44;
  static const double tabContentGap = 12;
  static const double stickyBarContentHeight = 60;
  static const double snackbarStickyReserve = 76;
  static const double operacaoTopSnackHeight = 52;
  static const double operacaoMaxContentWidth = 720;

  /// Pins floating snackbar below pinned toolbar + tabs (scroll-safe).
  static EdgeInsets operacaoTopSnackMargin(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final top =
        MediaQuery.paddingOf(context).top +
        kToolbarHeight +
        tabBarHeight +
        8;
    return EdgeInsets.fromLTRB(
      screenPadding,
      0,
      screenPadding,
      size.height - top - operacaoTopSnackHeight,
    );
  }

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

  /// Centers Operação tab content on wide screens.
  static Widget operacaoContentWidthLimiter({required Widget child}) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: operacaoMaxContentWidth),
        child: child,
      ),
    );
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

  /// Timeline metadata (dates) — stronger contrast than mute captions.
  static TextStyle timelineMetaStyle(BuildContext context) {
    return captionStyle(context).copyWith(
      fontWeight: FontWeight.w600,
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

  /// Secondary metadata — min 12px with stronger contrast.
  static TextStyle metaStyle(BuildContext context) {
    return captionStyle(context).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
  }

  /// Chip / button labels inside Operação cards (min 12px).
  static TextStyle chipLabelStyle(BuildContext context, {Color? color}) {
    return captionStyle(context).copyWith(
      color: color,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      height: 1.2,
    );
  }

  /// H2 titles on tab surfaces (Medidas, Módulos).
  static TextStyle tabSectionTitleStyle(
    BuildContext context, {
    required Color primary,
    required bool isDark,
  }) {
    return AppTypography.inter(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: BrandPalette.sectionHeading(primary, dark: isDark),
    );
  }

  /// Section titles inside inset cards (Operação, Evolução).
  static TextStyle sectionTitleStyle(BuildContext context, Color ink) {
    return AppTypography.inter(
      color: ink,
      fontSize: 17,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.2,
    );
  }

  /// Titles inside nested panels (empty states, callouts).
  static TextStyle panelTitleStyle(BuildContext context, Color ink) {
    return AppTypography.inter(
      color: ink,
      fontSize: 14,
      fontWeight: FontWeight.w800,
      height: 1.25,
      letterSpacing: -0.1,
    );
  }

  /// Card titles shared by Operação and Evolução blocks.
  static TextStyle cardTitleStyle(BuildContext context, Color ink) {
    return TextStyle(
      color: ink,
      fontSize: 16,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.15,
    );
  }

  /// Card subtitles under titles (min 12px).
  static TextStyle cardSubtitleStyle(BuildContext context) {
    return captionStyle(context);
  }

  /// WCAG-friendly link color for timeline expand actions (≥4.5:1 on white).
  static Color timelineLinkForeground(Color primary, {required bool isDark}) {
    return operacaoOutlinedForeground(primary, isDark: isDark);
  }

  /// Timeline event title inside list tiles.
  static TextStyle timelineTileTitleStyle(BuildContext context, Color ink) {
    return metaStyle(context).copyWith(
      color: ink,
      fontSize: 13,
      fontWeight: FontWeight.w900,
      height: 1.25,
    );
  }

  /// WCAG AA outline for Operação secondary buttons (≥4.5:1 on white).
  static BorderSide operacaoOutlineSide(Color primary, {required bool isDark}) {
    return BorderSide(
      color: primary.withValues(alpha: isDark ? 0.52 : 0.58),
      width: 1.25,
    );
  }

  static Color operacaoOutlinedForeground(Color primary, {required bool isDark}) {
    return isDark ? primary : Color.lerp(primary, Colors.black, 0.32)!;
  }

  static ButtonStyle operacaoOutlinedButtonStyle(
    BuildContext context,
    Color primary,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = operacaoOutlinedForeground(primary, isDark: isDark);
    return OutlinedButton.styleFrom(
      foregroundColor: fg,
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      side: operacaoOutlineSide(primary, isDark: isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    );
  }

  static ButtonStyle operacaoFilledButtonStyle(
    BuildContext context,
    Color primary,
  ) {
    return FilledButton.styleFrom(
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      backgroundColor: primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    );
  }

  /// Tablet breakpoint for side-by-side status + copilot.
  static const double operacaoTabletBreakpoint = 600;

  /// Timeline list tile icon (aligned with section header proportions).
  static const double timelineTileIconSize = 38;
  static const double timelineTileIconRadius = 14;
  static const double timelineTileIconGlyphSize = 19;
  static const double timelineSpineWidth = 2;

  /// Pill background for mini autonomy / signal chips (WCAG-friendly contrast).
  static BoxDecoration miniChipDecoration(
    Color color, {
    required bool isDark,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: isDark ? 0.22 : 0.12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: isDark ? 0.38 : 0.28)),
    );
  }
}
