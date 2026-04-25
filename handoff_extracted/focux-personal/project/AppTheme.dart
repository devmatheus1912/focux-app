// ============================================================
// Focux Personal — AppTheme.dart
// Gerado automaticamente a partir dos tokens de design (v3)
// Design: HTML mockup · stack: Flutter 3.29+ / Material 3
// ============================================================
//
// COMO USAR:
//   runApp(MaterialApp(theme: AppTheme.buildTheme()));
//
// Para dark mode:
//   MaterialApp(theme: AppTheme.buildTheme(), darkTheme: AppTheme.buildTheme(dark: true))
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart'; // pubspec: google_fonts: ^6.x

/// Focux Design Tokens — fonte única da verdade.
/// Mapeados diretamente dos tokens do mockup HTML.
abstract class FocuxTokens {
  // ── Brand ──────────────────────────────────────────────
  static const Color brand       = Color(0xFF3B5FE2); // electric royal — cor primária
  static const Color brandInk    = Color(0xFF2440B8); // texto sobre fundo claro
  static const Color brandSoft   = Color(0xFFEAF0FE); // tint de fundo
  static const Color brandSofter = Color(0xFFF4F7FE); // tint mais suave
  static const Color brandDeep   = Color(0xFF0D1B5C); // hero backgrounds
  static const Color brandAccent = Color(0xFF7CC0FF); // highlight / dark mode primary

  // ── Neutral light ──────────────────────────────────────
  static const Color paper       = Color(0xFFFAFAF8); // scaffold background
  static const Color card        = Color(0xFFFFFFFF); // card surface
  static const Color ink         = Color(0xFF0B1220); // primary text
  static const Color inkSoft     = Color(0xFF3A455C); // secondary text
  static const Color inkMute     = Color(0xFF6B7689); // tertiary / placeholder
  static const Color line        = Color(0xFFE6E6E0); // dividers / borders
  static const Color lineSoft    = Color(0xFFF0EFEA); // subtle bg

  // ── Neutral dark ───────────────────────────────────────
  static const Color darkBg      = Color(0xFF0A0F1E);
  static const Color darkCard    = Color(0xFF121A30);
  static const Color darkCardHi  = Color(0xFF1A2442);
  static const Color darkLine    = Color(0xFF1F2B4A);
  static const Color darkInk     = Color(0xFFF3F4F8);
  static const Color darkInkMute = Color(0xFF8A94AE);

  // ── Semantic ───────────────────────────────────────────
  static const Color good        = Color(0xFF2B6A3F);
  static const Color goodSoft    = Color(0xFFE4F1E9);
  static const Color warn        = Color(0xFF8A5A12);
  static const Color warnSoft    = Color(0xFFFBEED6);
  static const Color bad         = Color(0xFF9E2B2B);
  static const Color badSoft     = Color(0xFFF7E3E3);

  // ── Border radius ──────────────────────────────────────
  static const double radiusXs   = 8;
  static const double radiusSm   = 12;
  static const double radiusMd   = 16;
  static const double radiusLg   = 20;
  static const double radiusXl   = 24;
  static const double radius2xl  = 28;

  // ── Spacing scale ──────────────────────────────────────
  static const double sp4  = 4;
  static const double sp8  = 8;
  static const double sp12 = 12;
  static const double sp16 = 16;
  static const double sp20 = 20;
  static const double sp24 = 24;
  static const double sp32 = 32;
}

class AppTheme {
  static ThemeData buildTheme({ bool dark = false }) {
    final primary    = dark ? FocuxTokens.brandAccent : FocuxTokens.brand;
    final surface    = dark ? FocuxTokens.darkCard    : FocuxTokens.card;
    final scaffold   = dark ? FocuxTokens.darkBg      : FocuxTokens.paper;
    final onSurface  = dark ? FocuxTokens.darkInk     : FocuxTokens.ink;
    final onSurfMute = dark ? FocuxTokens.darkInkMute : FocuxTokens.inkMute;
    final outline    = dark ? FocuxTokens.darkLine    : FocuxTokens.line;

    // Typography — Space Grotesk (display/headers) + Inter (body)
    // Falls back to system-ui if google_fonts not available.
    final TextTheme base = TextTheme(
      // Display — Space Grotesk, used for big numbers and hero titles
      displayLarge  : GoogleFonts.spaceGrotesk(fontSize: 48, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: -1.5),
      displayMedium : GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: -1.0),
      displaySmall  : GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: -0.8),

      // Headline — Space Grotesk
      headlineLarge : GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: -0.5),
      headlineMedium: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: -0.4),
      headlineSmall : GoogleFonts.spaceGrotesk(fontSize: 17, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: -0.2),

      // Title — Inter semibold
      titleLarge    : GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: -0.2),
      titleMedium   : GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: -0.1),
      titleSmall    : GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: 0.1),

      // Body — Inter regular
      bodyLarge     : GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: onSurface, letterSpacing: -0.1),
      bodyMedium    : GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: onSurface, letterSpacing: -0.1),
      bodySmall     : GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: onSurfMute),

      // Label
      labelLarge    : GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: 0.05),
      labelMedium   : GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: onSurfMute, letterSpacing: 0.5),
      labelSmall    : GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: onSurfMute, letterSpacing: 0.8),
    );

    final cs = ColorScheme(
      brightness     : dark ? Brightness.dark : Brightness.light,
      primary        : primary,
      onPrimary      : Colors.white,
      primaryContainer: dark ? FocuxTokens.darkCardHi : FocuxTokens.brandSoft,
      onPrimaryContainer: dark ? FocuxTokens.brandAccent : FocuxTokens.brandInk,
      secondary      : dark ? FocuxTokens.brandAccent : const Color(0xFF4A7AEA),
      onSecondary    : Colors.white,
      secondaryContainer: dark ? FocuxTokens.darkCard : FocuxTokens.brandSofter,
      onSecondaryContainer: onSurface,
      tertiary       : FocuxTokens.good,
      onTertiary     : Colors.white,
      tertiaryContainer: FocuxTokens.goodSoft,
      onTertiaryContainer: FocuxTokens.good,
      error          : FocuxTokens.bad,
      onError        : Colors.white,
      errorContainer : FocuxTokens.badSoft,
      onErrorContainer: FocuxTokens.bad,
      surface        : surface,
      onSurface      : onSurface,
      onSurfaceVariant: onSurfMute,
      outline        : outline,
      outlineVariant : outline.withValues(alpha: 0.5),
      shadow         : const Color(0xFF000000),
      scrim          : const Color(0xFF000000),
      inverseSurface : dark ? FocuxTokens.card    : FocuxTokens.darkCard,
      onInverseSurface: dark ? FocuxTokens.ink    : FocuxTokens.darkInk,
      inversePrimary : dark ? FocuxTokens.brand   : FocuxTokens.brandAccent,
      surfaceTint    : primary,
    );

    return ThemeData(
      useMaterial3          : true,
      colorScheme           : cs,
      scaffoldBackgroundColor: scaffold,
      textTheme             : base,

      // ── AppBar ──────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor      : surface,
        foregroundColor      : onSurface,
        elevation            : 0,
        scrolledUnderElevation: 0.5,
        centerTitle          : false,
        titleTextStyle       : GoogleFonts.spaceGrotesk(
          fontSize: 18, fontWeight: FontWeight.w600,
          color: onSurface, letterSpacing: -0.3,
        ),
        systemOverlayStyle   : (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
        iconTheme            : IconThemeData(color: onSurface),
        actionsIconTheme     : IconThemeData(color: onSurface),
      ),

      // ── Card ────────────────────────────────────────────
      cardTheme: CardTheme(
        color       : surface,
        elevation   : 0,
        shape       : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FocuxTokens.radiusLg),
          side        : BorderSide(color: outline, width: 1),
        ),
        margin      : const EdgeInsets.symmetric(vertical: 6),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Input ───────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled              : true,
        fillColor           : surface,
        contentPadding      : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle           : GoogleFonts.inter(color: onSurfMute, fontSize: 14),
        labelStyle          : GoogleFonts.inter(color: onSurfMute, fontSize: 14),
        border              : OutlineInputBorder(
          borderRadius: BorderRadius.circular(FocuxTokens.radiusSm),
          borderSide  : BorderSide(color: outline),
        ),
        enabledBorder       : OutlineInputBorder(
          borderRadius: BorderRadius.circular(FocuxTokens.radiusSm),
          borderSide  : BorderSide(color: outline),
        ),
        focusedBorder       : OutlineInputBorder(
          borderRadius: BorderRadius.circular(FocuxTokens.radiusSm),
          borderSide  : BorderSide(color: primary, width: 1.5),
        ),
        errorBorder         : OutlineInputBorder(
          borderRadius: BorderRadius.circular(FocuxTokens.radiusSm),
          borderSide  : const BorderSide(color: FocuxTokens.bad),
        ),
      ),

      // ── Buttons ─────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize    : const Size.fromHeight(52),
          shape          : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FocuxTokens.radiusSm),
          ),
          textStyle      : GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
          elevation      : 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize    : const Size.fromHeight(52),
          shape          : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FocuxTokens.radiusSm),
          ),
          side           : BorderSide(color: primary, width: 1.5),
          textStyle      : GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle      : GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Chip ────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor : dark ? FocuxTokens.darkCardHi : FocuxTokens.lineSoft,
        selectedColor   : dark ? FocuxTokens.darkCardHi : FocuxTokens.brandSoft,
        labelStyle      : GoogleFonts.inter(fontSize: 12, color: onSurface, fontWeight: FontWeight.w500),
        side            : BorderSide(color: outline),
        shape           : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding         : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // ── ListTile ────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor     : onSurfMute,
        tileColor     : surface,
        shape         : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FocuxTokens.radiusMd),
        ),
      ),

      // ── Divider ─────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color    : outline,
        thickness: 0.5,
        space    : 0,
      ),

      // ── Dialog ──────────────────────────────────────────
      dialogTheme: DialogTheme(
        shape           : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FocuxTokens.radiusXl),
        ),
        backgroundColor : surface,
        titleTextStyle  : GoogleFonts.spaceGrotesk(
          fontSize: 18, fontWeight: FontWeight.w600, color: onSurface,
        ),
      ),

      // ── Bottom sheet ────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(FocuxTokens.radius2xl)),
        ),
        backgroundColor: surface,
        elevation      : 0,
      ),

      // ── Navigation bar (bottom dock) ────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor       : dark
          ? FocuxTokens.darkCard.withValues(alpha: 0.92)
          : Colors.white.withValues(alpha: 0.88),
        indicatorColor        : dark ? FocuxTokens.darkCardHi : FocuxTokens.brandSoft,
        iconTheme             : WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 22);
          }
          return IconThemeData(color: onSurfMute, size: 22);
        }),
        labelTextStyle        : WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: primary);
          }
          return GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w500, color: onSurfMute);
        }),
        elevation             : 0,
        height                : 76,
      ),

      // ── FAB ─────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape          : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FocuxTokens.radiusMd),
        ),
        elevation      : 2,
      ),

      // ── SnackBar ────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior       : SnackBarBehavior.floating,
        shape          : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FocuxTokens.radiusSm),
        ),
        backgroundColor: dark ? FocuxTokens.darkCardHi : FocuxTokens.ink,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      ),

      // ── Switch / Checkbox / Radio ────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor   : WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? Colors.white : onSurfMute),
        trackColor   : WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? primary : outline),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? primary : Colors.transparent),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape      : RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side       : BorderSide(color: outline, width: 1.5),
      ),
    );
  }
}

// ── Usage example ────────────────────────────────────────────────────────────
//
// void main() {
//   runApp(
//     MaterialApp(
//       theme    : AppTheme.buildTheme(),
//       darkTheme: AppTheme.buildTheme(dark: true),
//       themeMode: ThemeMode.system,
//       home     : const MyHomePage(),
//     ),
//   );
// }
//
// Accessing tokens directly in widgets:
//   color: FocuxTokens.brand
//   color: Theme.of(context).colorScheme.primary   // same via MaterialApp
//
// pubspec.yaml dependencies needed:
//   google_fonts: ^6.2.1
//   flutter:
//     sdk: flutter
// ─────────────────────────────────────────────────────────────────────────────
