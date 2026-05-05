import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'brand_palette.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData buildTheme(Color primary) => _build(primary, false);
  static ThemeData buildDarkTheme(Color primary) => _build(primary, true);

  static Color _readableOn(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : EagleTokens.ink;
  }

  static TextStyle _spaceGrotesk({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    if (!GoogleFonts.config.allowRuntimeFetching) {
      return TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
    }

    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle _inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    if (!GoogleFonts.config.allowRuntimeFetching) {
      return TextStyle(
        fontFamily: 'Inter',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
    }

    return GoogleFonts.inter(
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
    final surface    = dark ? EagleTokens.darkCard    : EagleTokens.card;
    final scaffold   = dark ? EagleTokens.darkBg      : EagleTokens.paper;
    final onSurface  = dark ? EagleTokens.darkInk     : EagleTokens.ink;
    final onSurfMute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final outline    = dark ? EagleTokens.darkLine    : EagleTokens.line;

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
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface:    dark ? EagleTokens.card    : EagleTokens.darkCard,
      onInverseSurface:  dark ? EagleTokens.ink     : EagleTokens.darkInk,
      inversePrimary:    dark ? primary : primaryAccent,
      surfaceTint: primary,
    );

    final textTheme = TextTheme(
      displayLarge:   _spaceGrotesk(fontSize: 42, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: 0),
      displayMedium:  _spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: 0),
      displaySmall:   _spaceGrotesk(fontSize: 25, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: 0),
      headlineLarge:  _spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: 0),
      headlineMedium: _spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: 0),
      headlineSmall:  _spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: 0),
      titleLarge:     _inter(fontSize: 15, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: 0),
      titleMedium:    _inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: 0),
      titleSmall:     _inter(fontSize: 12, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: 0.1),
      bodyLarge:      _inter(fontSize: 15, fontWeight: FontWeight.w400, color: onSurface, letterSpacing: 0),
      bodyMedium:     _inter(fontSize: 13, fontWeight: FontWeight.w400, color: onSurface, letterSpacing: 0),
      bodySmall:      _inter(fontSize: 11.5, fontWeight: FontWeight.w400, color: onSurfMute),
      labelLarge:     _inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: onSurface,  letterSpacing: 0.05),
      labelMedium:    _inter(fontSize: 11, fontWeight: FontWeight.w600, color: onSurfMute, letterSpacing: 0.5),
      labelSmall:     _inter(fontSize: 10, fontWeight: FontWeight.w600, color: onSurfMute, letterSpacing: 0.8),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: _spaceGrotesk().fontFamily,
      visualDensity: VisualDensity.compact,
      colorScheme: cs,
      scaffoldBackgroundColor: scaffold,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: _spaceGrotesk(fontSize: 16.5, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: 0),
        systemOverlayStyle: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent),
        iconTheme: IconThemeData(color: onSurface),
        actionsIconTheme: IconThemeData(color: onSurface),
      ),

      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EagleTokens.radiusLg),
          side: BorderSide(color: outline),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        clipBehavior: Clip.antiAlias,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: _inter(color: onSurfMute, fontSize: 14),
        labelStyle: _inter(color: onSurfMute, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(EagleTokens.radiusSm), borderSide: BorderSide(color: outline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(EagleTokens.radiusSm), borderSide: BorderSide(color: outline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(EagleTokens.radiusSm), borderSide: BorderSide(color: primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(EagleTokens.radiusSm), borderSide: const BorderSide(color: EagleTokens.bad)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(EagleTokens.radiusSm), borderSide: const BorderSide(color: EagleTokens.bad, width: 1.5)),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary, foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EagleTokens.radiusSm)),
          textStyle: _inter(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EagleTokens.radiusSm)),
          side: BorderSide(color: primary, width: 1.5),
          textStyle: _inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: _inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: dark ? EagleTokens.darkCardHi : EagleTokens.lineSoft,
        selectedColor:   dark ? EagleTokens.darkCardHi : primarySoft,
        labelStyle: _inter(fontSize: 12, color: onSurface, fontWeight: FontWeight.w500),
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: onSurfMute,
        tileColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EagleTokens.radiusMd)),
      ),

      dividerTheme: DividerThemeData(color: outline, thickness: 0.5, space: 0),

      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EagleTokens.radiusXl)),
        backgroundColor: surface,
        titleTextStyle: _spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(EagleTokens.radius2xl))),
        backgroundColor: surface,
        elevation: 0,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark
            ? EagleTokens.darkCard.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.88),
        indicatorColor: dark ? EagleTokens.darkCardHi : primarySoft,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return IconThemeData(color: primary, size: 21);
          return IconThemeData(color: onSurfMute, size: 21);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: primary);
          return _inter(fontSize: 10.5, fontWeight: FontWeight.w500, color: onSurfMute);
        }),
        elevation: 0,
        height: 70,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary, foregroundColor: onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EagleTokens.radiusMd)),
        elevation: 2,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EagleTokens.radiusSm)),
        backgroundColor: dark ? EagleTokens.darkCardHi : EagleTokens.ink,
        contentTextStyle: _inter(color: Colors.white, fontSize: 14),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.white : onSurfMute),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? primary : outline),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? primary : Colors.transparent),
        checkColor: WidgetStateProperty.all(onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: outline, width: 1.5),
      ),
    );
  }
}
