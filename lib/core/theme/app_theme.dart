import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData buildTheme(Color primary) => _build(primary, false);
  static ThemeData buildDarkTheme(Color primary) => _build(primary, true);

  static ThemeData _build(Color primary, bool dark) {
    final surface    = dark ? EagleTokens.darkCard    : EagleTokens.card;
    final scaffold   = dark ? EagleTokens.darkBg      : EagleTokens.paper;
    final onSurface  = dark ? EagleTokens.darkInk     : EagleTokens.ink;
    final onSurfMute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final outline    = dark ? EagleTokens.darkLine    : EagleTokens.line;

    final cs = ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: dark ? EagleTokens.darkCardHi  : EagleTokens.brandSoft,
      onPrimaryContainer: dark ? EagleTokens.brandAccent : EagleTokens.brandInk,
      secondary: dark ? EagleTokens.brandAccent : const Color(0xFF4A7AEA),
      onSecondary: Colors.white,
      secondaryContainer: dark ? EagleTokens.darkCard : EagleTokens.brandSofter,
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
      inversePrimary:    dark ? EagleTokens.brand   : EagleTokens.brandAccent,
      surfaceTint: primary,
    );

    final textTheme = TextTheme(
      displayLarge:   GoogleFonts.spaceGrotesk(fontSize: 48, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: -1.5),
      displayMedium:  GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: -1.0),
      displaySmall:   GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: -0.8),
      headlineLarge:  GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: -0.5),
      headlineMedium: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: -0.4),
      headlineSmall:  GoogleFonts.spaceGrotesk(fontSize: 17, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: -0.2),
      titleLarge:     GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: -0.2),
      titleMedium:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: -0.1),
      titleSmall:     GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: 0.1),
      bodyLarge:      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: onSurface, letterSpacing: -0.1),
      bodyMedium:     GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: onSurface, letterSpacing: -0.1),
      bodySmall:      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: onSurfMute),
      labelLarge:     GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: onSurface,  letterSpacing: 0.05),
      labelMedium:    GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: onSurfMute, letterSpacing: 0.5),
      labelSmall:     GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: onSurfMute, letterSpacing: 0.8),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: scaffold,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: -0.3),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: onSurfMute, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: onSurfMute, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(EagleTokens.radiusSm), borderSide: BorderSide(color: outline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(EagleTokens.radiusSm), borderSide: BorderSide(color: outline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(EagleTokens.radiusSm), borderSide: BorderSide(color: primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(EagleTokens.radiusSm), borderSide: const BorderSide(color: EagleTokens.bad)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(EagleTokens.radiusSm), borderSide: const BorderSide(color: EagleTokens.bad, width: 1.5)),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary, foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EagleTokens.radiusSm)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EagleTokens.radiusSm)),
          side: BorderSide(color: primary, width: 1.5),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: dark ? EagleTokens.darkCardHi : EagleTokens.lineSoft,
        selectedColor:   dark ? EagleTokens.darkCardHi : EagleTokens.brandSoft,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: onSurface, fontWeight: FontWeight.w500),
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
        titleTextStyle: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
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
        indicatorColor: dark ? EagleTokens.darkCardHi : EagleTokens.brandSoft,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return IconThemeData(color: primary, size: 22);
          return IconThemeData(color: onSurfMute, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: primary);
          return GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w500, color: onSurfMute);
        }),
        elevation: 0,
        height: 76,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary, foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EagleTokens.radiusMd)),
        elevation: 2,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EagleTokens.radiusSm)),
        backgroundColor: dark ? EagleTokens.darkCardHi : EagleTokens.ink,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
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
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: outline, width: 1.5),
      ),
    );
  }
}
