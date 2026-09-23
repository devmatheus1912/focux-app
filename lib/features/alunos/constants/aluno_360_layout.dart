import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../utils/aluno360_readability.dart';

/// Layout tokens for Aluno 360 (hero, sticky CTA, scroll insets).
abstract final class Aluno360Layout {
  Aluno360Layout._();

  static const double screenPadding = TokensStrip.s4;
  static const double sectionGap = TokensStrip.s4;
  static const double cardPadding = TokensStrip.s4;
  static const double insetCardRadius = TokensStrip.rCard;
  static const double tabBarHeight = 52;
  static const double tabContentGap = TokensStrip.s4;
  /// Chip overlay (paridade Perfil/Home) — CTA primária sticky.
  static const double stickyBarContentHeight = 64;

  /// Reserva da segunda linha do sticky — desligada (tarefa vive em Mais ações).
  static const double stickyBarSecondaryRowHeight = 0;
  static const double stickyBarScrimHeight = 28;
  static const double snackbarStickyReserve = 76;
  static const double operacaoTopSnackHeight = 52;
  static const double operacaoMaxContentWidth = 720;

  /// Pins floating snackbar below pinned toolbar + tabs (scroll-safe).
  static EdgeInsets operacaoTopSnackMargin(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final top =
        MediaQuery.paddingOf(context).top + kToolbarHeight + tabBarHeight + 8;
    const snackBelowHeaderGap = 12.0;
    return EdgeInsets.fromLTRB(
      screenPadding,
      0,
      screenPadding,
      size.height - top - operacaoTopSnackHeight - snackBelowHeaderGap,
    );
  }

  /// Identity strip height (compact strip + padding at textScale ≤ 1.25).
  static double heroBodyHeight(
    BuildContext context, {
    bool compactContactPriority = false,
  }) {
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    final base = compactContactPriority ? 196.0 : 220.0;
    return base + ((textScale - 1) * 32);
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
        heroBodyHeight(context, compactContactPriority: compactContactPriority);
  }

  /// Pinned toolbar + tab bar (content should not scroll under this stack).
  static double pinnedHeaderHeight(BuildContext context) {
    return MediaQuery.paddingOf(context).top + kToolbarHeight + tabBarHeight;
  }

  /// Bottom padding so Operação content clears the sticky overlay CTA.
  static double stickyBarTotalHeight(BuildContext context) {
    return stickyBarContentHeight +
        stickyBarSecondaryRowHeight +
        MediaQuery.paddingOf(context).bottom +
        MediaQuery.viewInsetsOf(context).bottom;
  }

  static double operacaoScrollBottomReserve(BuildContext context) {
    return stickyBarTotalHeight(context) + stickyBarScrimHeight + 24;
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

  /// Inset surface — paridade Perfil (`fxListCardDecoration` + raio 20).
  static BoxDecoration operacaoInsetSectionDecoration(
    BuildContext context, {
    required Color primary,
    required bool isDark,
  }) {
    return fxListCardDecoration(
      context,
      radius: FxSettingsLayout.groupRadius,
    );
  }

  /// Flat surface for every tile inside the Histórico 360 sheet (no mixed InkWell fills).
  static BoxDecoration timelineModalTileDecoration(
    BuildContext context, {
    required bool isDark,
  }) {
    final chrome = ShellChrome.of(context);
    return BoxDecoration(
      color:
          isDark
              ? Colors.white.withValues(alpha: 0.04)
              : chrome.cardFill.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(12),
    );
  }

  /// Timeline metadata (dates) — stronger contrast than mute captions.
  static TextStyle timelineMetaStyle(BuildContext context) {
    return metaStyle(context);
  }

  /// Secondary copy inside cards — matches Home/Alunos muted body.
  static TextStyle captionStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FocuxHubTypography.bodyMuted(
      color: aluno360ReadableCaption(context, isDark: isDark),
    );
  }

  /// Secondary metadata — min 12px with stronger contrast.
  static TextStyle metaStyle(BuildContext context) {
    return FocuxHubTypography.bodyMuted(
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: aluno360ReadableMuted(
        context,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }

  /// Uppercase metric eyebrows (hero, operational tiles).
  static TextStyle eyebrowLabelStyle(BuildContext context, Color color) {
    return FocuxHubTypography.chip(color).copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.35,
    );
  }

  /// Micro badges (module tiles, status chips).
  static TextStyle badgeMicroStyle(BuildContext context, Color color) {
    return FocuxHubTypography.chip(color).copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    );
  }

  /// Sticky bar and primary pill labels.
  static TextStyle ctaLabelStyle(BuildContext context, Color color) {
    return FocuxHubTypography.bodyMuted(
      color: color,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
  }

  /// Tab bar selected label (Operação · Evolução · Ferramentas).
  static TextStyle tabSelectedLabelStyle() {
    return FocuxHubTypography.bodyMuted(
      color: TokensStrip.textPrimary,
      fontWeight: FontWeight.w600,
    ).copyWith(letterSpacing: -0.1);
  }

  /// Tab bar unselected label.
  static TextStyle tabUnselectedLabelStyle() {
    return FocuxHubTypography.bodyMuted(
      color: TokensStrip.textSecondary,
      fontWeight: FontWeight.w500,
    );
  }

  /// Compact secondary actions in empty states.
  static TextStyle secondaryActionLabelStyle() {
    return FocuxHubTypography.bodyMuted(
      color: TokensStrip.textPrimary,
      fontWeight: FontWeight.w600,
    );
  }

  /// Chip / button labels inside Operação cards.
  static TextStyle chipLabelStyle(BuildContext context, {Color? color}) {
    return captionStyle(context).copyWith(
      color: color,
      fontSize: TokensStrip.fontBodySm,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
  }

  /// Card section titles — same weight as Alunos list card names.
  static TextStyle sectionTitleStyle(BuildContext context, Color ink) {
    return FocuxHubTypography.body(color: ink).copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.15,
      height: 1.2,
    );
  }

  /// Collapsible inset headers (Próximo contato compact).
  static TextStyle compactSectionTitleStyle(BuildContext context, Color ink) {
    return FocuxHubTypography.cardTitle(color: ink).copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
    );
  }

  /// Titles inside nested panels (empty states, callouts).
  static TextStyle panelTitleStyle(BuildContext context, Color ink) {
    return FocuxHubTypography.cardTitle(color: ink).copyWith(
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: -0.05,
    );
  }

  /// Alias for [sectionTitleStyle] — single card-title token.
  static TextStyle cardTitleStyle(BuildContext context, Color ink) {
    return sectionTitleStyle(context, ink);
  }

  /// Emphasized body inside cards (prescription, instructions).
  static TextStyle bodyEmphasisStyle(BuildContext context, Color ink) {
    return FocuxHubTypography.bodyMuted(
      color: ink,
      fontWeight: FontWeight.w600,
      height: 1.38,
    );
  }

  /// Compact metric inside signal tiles and chips.
  static TextStyle inlineMetricStyle(BuildContext context, Color ink) {
    return FocuxHubTypography.cardTitle(color: ink).copyWith(
      fontWeight: FontWeight.w700,
      height: 1.15,
    );
  }

  /// Hero / identity name on Aluno 360 toolbar and hero card.
  static TextStyle identityNameStyle(BuildContext context, Color ink) {
    return FocuxHubTypography.body(color: ink).copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.15,
      height: 1.15,
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
      fontSize: TokensStrip.fontBodySm,
      fontWeight: FontWeight.w600,
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

  static Color operacaoOutlinedForeground(
    Color primary, {
    required bool isDark,
  }) {
    return isDark ? primary : Color.lerp(primary, Colors.black, 0.32)!;
  }

  /// Link secundário 48dp — não usa o TextButton cru do Material.
  static ButtonStyle secondaryTextLinkStyle(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return TextButton.styleFrom(
      foregroundColor: primary,
      minimumSize: const Size(48, 48),
      tapTargetSize: MaterialTapTargetSize.padded,
      padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s2),
      alignment: Alignment.centerLeft,
    );
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
  static BoxDecoration miniChipDecoration(Color color, {required bool isDark}) {
    return BoxDecoration(
      color: color.withValues(alpha: isDark ? 0.22 : 0.12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: isDark ? 0.38 : 0.28)),
    );
  }
}
