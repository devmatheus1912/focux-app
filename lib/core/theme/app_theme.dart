import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'brand_palette.dart';
import 'design_tokens.dart';
import 'fx_page_transitions_builder.dart';

class AppTheme {
  static ThemeData buildTheme(Color primary) => _build(primary, false);
  static ThemeData buildDarkTheme(Color primary) => _build(primary, true);

  static Color _readableOn(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : EagleTokens.ink;
  }

  // ── Premium Typography: Outfit ──────────────────────────────────────
  // Replaces Inter (banned) and Space Grotesk with a single cohesive
  // geometric sans-serif that has strong character without shouting.
  static TextStyle _outfit({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    if (!GoogleFonts.config.allowRuntimeFetching) {
      return TextStyle(
        fontFamily: 'Outfit',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }

    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // ── Technical Mono: JetBrains Mono ──────────────────────────────────
  // For metric numbers, technical labels, and uppercase micro-type.
  static TextStyle _mono({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    if (!GoogleFonts.config.allowRuntimeFetching) {
      return TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
    }

    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static ThemeData _build(Color primary, bool dark) {
    final primarySoft = BrandPalette.soft(primary, dark: dark);
    final primarySofter = BrandPalette.softer(primary, dark: dark);
    final primaryDeep = BrandPalette.deep(primary);
    final primaryAccent = BrandPalette.accent(primary);
    final onPrimary = _readableOn(primary);
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
      secondary: dark ? primaryAccent : primaryDeep,
      onSecondary: Colors.white,
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

    // ── Text Theme (Outfit throughout, tight tracking on display) ─────
    final textTheme = TextTheme(
      displayLarge: _outfit(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: -0.5,
      ),
      displayMedium: _outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: -0.3,
      ),
      displaySmall: _outfit(
        fontSize: 25,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: -0.2,
      ),
      headlineLarge: _outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: -0.2,
      ),
      headlineMedium: _outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: -0.1,
      ),
      headlineSmall: _outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: 0,
      ),
      titleLarge: _outfit(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: 0,
      ),
      titleMedium: _outfit(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: 0,
      ),
      titleSmall: _outfit(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: 0.1,
      ),
      bodyLarge: _outfit(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: onSurface,
        letterSpacing: 0,
      ),
      bodyMedium: _outfit(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: onSurface,
        letterSpacing: 0,
      ),
      bodySmall: _outfit(
        fontSize: 11.5,
        fontWeight: FontWeight.w400,
        color: onSurfMute,
      ),
      labelLarge: _outfit(
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
      fontFamily: _outfit().fontFamily,
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
        titleTextStyle: _outfit(
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

      // ── Cards: glass-style border, tinted shadow for depth ──────────
      cardTheme: CardTheme(
        color: dark ? EagleTokens.darkCard : surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EagleTokens.radiusLg),
          side: BorderSide(
            color: dark
                ? EagleTokens.glassBorder
                : outline.withValues(alpha: 0.6),
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        clipBehavior: Clip.antiAlias,
        shadowColor: shadowColor,
      ),

      // ── Inputs: clean with refined focus ring ───────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? EagleTokens.darkCardHi : EagleTokens.lineSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        hintStyle: _outfit(color: onSurfMute, fontSize: 14),
        labelStyle: _outfit(color: onSurfMute, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EagleTokens.radiusSm),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EagleTokens.radiusSm),
          borderSide: BorderSide(
            color: dark ? EagleTokens.darkLine : outline.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EagleTokens.radiusSm),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EagleTokens.radiusSm),
          borderSide: const BorderSide(color: EagleTokens.bad),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EagleTokens.radiusSm),
          borderSide: const BorderSide(color: EagleTokens.bad, width: 1.5),
        ),
      ),

      // ── Filled Button: gradient feel via elevation, tactile press ───
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EagleTokens.radiusSm),
          ),
          textStyle: _outfit(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EagleTokens.radiusSm),
          ),
          side: BorderSide(color: primary, width: 1.5),
          textStyle: _outfit(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: _outfit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Chips: pill-shaped, subtle glass tint ───────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: dark ? EagleTokens.darkCardHi : EagleTokens.lineSoft,
        selectedColor: dark ? EagleTokens.darkCardHi : primarySoft,
        labelStyle: _outfit(
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

      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EagleTokens.radiusXl),
        ),
        backgroundColor: dark ? EagleTokens.darkCard : surface,
        titleTextStyle: _outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(EagleTokens.radius2xl),
          ),
        ),
        backgroundColor: dark ? EagleTokens.darkCard : surface,
        elevation: 0,
      ),

      // ── Navigation Bar: cinematic glass dock ────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            dark
                ? EagleTokens.darkCard.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.85),
        indicatorColor: dark ? EagleTokens.darkCardHi : primarySoft,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 21);
          }
          return IconThemeData(color: onSurfMute, size: 21);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: primary,
            );
          }
          return _outfit(
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
        contentTextStyle: _outfit(color: Colors.white, fontSize: 14),
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
      tabBarTheme: TabBarTheme(
        labelColor: primary,
        unselectedLabelColor: onSurfMute,
        indicatorColor: primary,
        labelStyle: _outfit(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: _outfit(fontSize: 13, fontWeight: FontWeight.w500),
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
        textStyle: _outfit(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
