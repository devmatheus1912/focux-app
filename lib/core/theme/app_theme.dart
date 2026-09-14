import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'brand_palette.dart';
import 'curated_brand_palettes.dart';
import 'design_tokens.dart';
import 'focux_hub_typography.dart';
import 'fx_page_transitions_builder.dart';
import 'tokens_strip.dart';

class AppTheme {
  static ThemeData buildTheme(Color primary, {Color? secondary}) =>
      _build(primary, false, secondary: secondary);

  static ThemeData buildDarkTheme(Color primary, {Color? secondary}) =>
      _build(primary, true, secondary: secondary);

  static Color _readableOn(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : EagleTokens.ink;
  }

  // ── Premium Typography: Inter ───────────────────────────────────────
  // Primary UI sans-serif across TOKENS STRIP (see AppTypography).
  static TextStyle _inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      AppTypography.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle _mono({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) =>
      AppTypography.mono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static ThemeData _build(Color primary, bool dark, {Color? secondary}) {
    final primarySoft = BrandPalette.soft(primary, dark: dark);
    final primarySofter = BrandPalette.softer(primary, dark: dark);
    final primaryDeep = BrandPalette.deep(primary);
    final primaryAccent = BrandPalette.accent(primary);
    final onPrimary = _readableOn(primary);
    final resolvedSecondary =
        secondary != null
            ? CuratedBrandPalette.safeSecondaryFor(primary, secondary)
            : (dark ? primaryAccent : primaryDeep);
    final onSecondary = _readableOn(resolvedSecondary);
    final surface = dark ? EagleTokens.darkCard : EagleTokens.card;
    final scaffold = dark ? EagleTokens.darkBg : EagleTokens.paper;
    final onSurface = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final onSurfMute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final outline = dark ? EagleTokens.darkLine : EagleTokens.line;

    // Tinted shadow — brand-tinted depth with cinematic subtlety
    final shadowColor =
        dark
            ? Colors.black.withValues(alpha: 0.6)
            : Color.alphaBlend(
              primary.withValues(alpha: 0.05),
              Colors.black.withValues(alpha: 0.07),
            );

    final cs = ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: dark ? primarySofter : primarySoft,
      onPrimaryContainer: dark ? primaryAccent : primaryDeep,
      secondary: resolvedSecondary,
      onSecondary: onSecondary,
      secondaryContainer: dark ? EagleTokens.darkCardHi : primarySofter,
      onSecondaryContainer: onSurface,
      tertiary: EagleTokens.good,
      onTertiary: Colors.white,
      tertiaryContainer: EagleTokens.goodSoft,
      onTertiaryContainer: EagleTokens.good,
      error: EagleTokens.bad,
      onError: Colors.white,
      errorContainer: EagleTokens.badSoft,
      onErrorContainer: EagleTokens.bad,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfMute,
      outline: outline,
      outlineVariant: outline.withValues(alpha: 0.5),
      shadow: shadowColor,
      scrim: Colors.black,
      inverseSurface: dark ? EagleTokens.card : EagleTokens.darkCard,
      onInverseSurface: dark ? EagleTokens.ink : EagleTokens.darkInk,
      inversePrimary: dark ? primary : primaryAccent,
      surfaceTint: primary,
    );

    // ── Text Theme (Inter throughout, tight tracking on display) ──────
    final textTheme = TextTheme(
      displayLarge: _inter(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: -0.5,
      ),
      displayMedium: _inter(
        fontSize: TokensStrip.fontH1,
        fontWeight: TokensStrip.weightH1,
        color: onSurface,
        letterSpacing: TokensStrip.trackingH1,
      ),
      displaySmall: _inter(
        fontSize: 25,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: -0.2,
      ),
      headlineLarge: _inter(
        fontSize: TokensStrip.fontH2,
        fontWeight: TokensStrip.weightH2,
        color: onSurface,
        letterSpacing: TokensStrip.trackingH2,
      ),
      headlineMedium: _inter(
        fontSize: FocuxHubTypography.metricEm,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: -0.1,
      ),
      headlineSmall: _inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: 0,
      ),
      titleLarge: _inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: 0,
      ),
      titleMedium: _inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: 0,
      ),
      titleSmall: _inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: 0.1,
      ),
      bodyLarge: _inter(
        fontSize: TokensStrip.fontBody,
        fontWeight: TokensStrip.weightBody,
        color: onSurface,
        letterSpacing: 0,
        height: TokensStrip.leadingBody,
      ),
      bodyMedium: _inter(
        fontSize: TokensStrip.fontBodySm,
        fontWeight: TokensStrip.weightBody,
        color: onSurface,
        letterSpacing: 0,
        height: TokensStrip.leadingBody,
      ),
      bodySmall: _inter(
        fontSize: 11.5,
        fontWeight: FontWeight.w400,
        color: onSurfMute,
      ),
      labelLarge: _inter(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: 0.05,
      ),
      labelMedium: _mono(
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
        color: onSurfMute,
        letterSpacing: 0.8,
      ),
      labelSmall: _mono(
        fontSize: 9.5,
        fontWeight: FontWeight.w500,
        color: onSurfMute,
        letterSpacing: 1.0,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: _inter().fontFamily,
      visualDensity: VisualDensity.compact,
      colorScheme: cs,
      scaffoldBackgroundColor: scaffold,
      textTheme: textTheme,
      pageTransitionsTheme: fxPremiumPageTransitions,

      // ── App Bar: clean, no elevation, premium title ─────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? EagleTokens.darkBg : surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: _inter(
          fontSize: 16.5,
          fontWeight: FontWeight.w600,
          color: onSurface,
          letterSpacing: -0.1,
        ),
        systemOverlayStyle: (dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent),
        iconTheme: IconThemeData(color: onSurface),
        actionsIconTheme: IconThemeData(color: onSurface),
      ),

      // ── Cards: TOKENS STRIP 12px + soft shadow ───────────────────────
      cardTheme: CardThemeData(
        color: dark ? EagleTokens.darkCard : surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          side: BorderSide(
            color: dark
                ? TokensStrip.glassBorder(dark: dark, accent: primaryAccent)
                : TokensStrip.borderDefault,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: TokensStrip.s2),
        clipBehavior: Clip.antiAlias,
        shadowColor: shadowColor,
      ),

      // ── Inputs: glass fill + neon focus ring ────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            dark
                ? EagleTokens.darkCardHi.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.92),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TokensStrip.s4,
          vertical: TokensStrip.s3,
        ),
        hintStyle: _inter(color: onSurfMute, fontSize: 14),
        labelStyle: _inter(color: onSurfMute, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TokensStrip.rInput),
          borderSide: BorderSide(
            color: dark ? TokensStrip.glassBorder(dark: dark) : TokensStrip.borderDefault,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TokensStrip.rInput),
          borderSide: BorderSide(
            color: dark ? TokensStrip.glassBorder(dark: dark) : TokensStrip.borderDefault,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TokensStrip.rInput),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TokensStrip.rInput),
          borderSide: const BorderSide(color: EagleTokens.bad),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TokensStrip.rInput),
          borderSide: const BorderSide(color: EagleTokens.bad, width: 1.5),
        ),
      ),

      // ── Filled Button: TOKENS STRIP pill 50px ───────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          // Brand fills are saturated teals — always white label (onPrimary
          // would pick dark ink on bright primaries like #13C2C2).
          foregroundColor: Colors.white,
          disabledBackgroundColor: TokensStrip.disabled.withValues(alpha: 0.35),
          disabledForegroundColor: TokensStrip.disabled,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TokensStrip.rButton),
          ),
          textStyle: _inter(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
          shadowColor: primary.withValues(alpha: 0.35),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          disabledForegroundColor: TokensStrip.disabled,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TokensStrip.rButton),
          ),
          side: BorderSide(
            color: dark
                ? TokensStrip.glassBorder(dark: dark, accent: primary)
                : primary,
            width: 1.2,
          ),
          textStyle: _inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: _inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Chips: pill-shaped, subtle glass tint ───────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: dark ? EagleTokens.darkCardHi : EagleTokens.lineSoft,
        selectedColor: dark ? EagleTokens.darkCardHi : primarySoft,
        labelStyle: _inter(
          fontSize: 12,
          color: onSurface,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(
          color: dark
              ? EagleTokens.glassBorder
              : outline.withValues(alpha: 0.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: onSurfMute,
        tileColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EagleTokens.radiusMd),
        ),
      ),

      dividerTheme: DividerThemeData(color: outline, thickness: 0.5, space: 0),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EagleTokens.radiusXl),
        ),
        backgroundColor: dark ? EagleTokens.darkCard : surface,
        titleTextStyle: _inter(
          fontSize: FocuxHubTypography.metricEm,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(TokensStrip.rXl),
          ),
        ),
        backgroundColor: dark ? EagleTokens.darkCard : surface,
        elevation: 0,
      ),

      // ── Navigation Bar: Liquid Glass dock ───────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: TokensStrip.glassFill(dark: dark, opacity: 0.88),
        indicatorColor: dark ? EagleTokens.darkCardHi : primarySoft,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 21);
          }
          return IconThemeData(color: onSurfMute, size: 21);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: primary,
            );
          }
          return _inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: onSurfMute,
          );
        }),
        elevation: 0,
        height: 70,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EagleTokens.radiusMd),
        ),
        elevation: 2,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EagleTokens.radiusSm),
        ),
        backgroundColor: dark ? EagleTokens.darkCardHi : EagleTokens.ink,
        contentTextStyle: _inter(color: Colors.white, fontSize: 14),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : onSurfMute,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : outline,
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? primary
                  : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: outline, width: 1.5),
      ),

      // ── Progress / Slider — uses primary (white-label aware) ────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: dark ? EagleTokens.darkLine : EagleTokens.lineSoft,
        circularTrackColor: dark ? EagleTokens.darkLine : EagleTokens.lineSoft,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        thumbColor: primary,
        inactiveTrackColor: dark ? EagleTokens.darkLine : EagleTokens.lineSoft,
        overlayColor: primary.withValues(alpha: 0.12),
      ),

      // ── TabBar: refined with brand accent ───────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: onSurfMute,
        indicatorColor: primary,
        labelStyle: _inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: _inter(fontSize: 13, fontWeight: FontWeight.w500),
      ),

      // ── Badge ───────────────────────────────────────────────────────
      badgeTheme: BadgeThemeData(
        backgroundColor: primary,
        textColor: onPrimary,
      ),

      // ── Tooltip ─────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dark ? EagleTokens.darkCardHi : EagleTokens.ink,
          borderRadius: BorderRadius.circular(EagleTokens.radiusXs),
        ),
        textStyle: _inter(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
