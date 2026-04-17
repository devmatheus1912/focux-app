import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paleta Focux — estilo Airbnb com azul suave no lugar do coral/vermelho.
class AppTheme {
  // Azul principal — suave, sem tom rosado
  static const Color defaultPrimary = Color(0xFF0288D1);

  // Paleta neutra inspirada no Airbnb
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _background = Color(0xFFF7F7F7);
  static const Color _onSurface = Color(0xFF222222);
  static const Color _onSurfaceVariant = Color(0xFF717171);
  static const Color _outline = Color(0xFFDDDDDD);

  static ThemeData buildTheme(Color primary) {
    final cs = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      // Forçar azul — impede Material You de derivar tons rosas/roxos
      primary: primary,
      secondary: const Color(0xFF0097A7),   // ciano complementar
      tertiary: const Color(0xFF00897B),    // verde-teal suave
      error: const Color(0xFFD32F2F),       // vermelho apenas para erros reais
      surface: _surface,
      surfaceContainerHighest: const Color(0xFFF0F0F0),
      onSurface: _onSurface,
      onSurfaceVariant: _onSurfaceVariant,
      outline: _outline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: _background,

      // ── AppBar — branco, sem sombra, ícones escuros (Airbnb style) ──
      appBarTheme: AppBarTheme(
        backgroundColor: _surface,
        foregroundColor: _onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: _onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        iconTheme: const IconThemeData(color: _onSurface),
        actionsIconTheme: const IconThemeData(color: _onSurface),
      ),

      // ── Cards — bordas suaves, sombra mínima ──
      cardTheme: CardTheme(
        color: _surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _outline, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Inputs — limpos, bordas arredondadas ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1),
        ),
        hintStyle: const TextStyle(color: _onSurfaceVariant, fontSize: 14),
        labelStyle: const TextStyle(color: _onSurfaceVariant, fontSize: 14),
      ),

      // ── Botão primário — pill arredondado, azul ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),

      // ── Botão outlined ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: primary, width: 1.5),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Botão texto ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Chips ──
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF0F0F0),
        selectedColor: primary.withValues(alpha: 0.15),
        labelStyle: const TextStyle(fontSize: 13, color: _onSurface),
        side: const BorderSide(color: _outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // ── ListTile ──
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: _onSurfaceVariant,
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(
        color: _outline,
        thickness: 1,
        space: 0,
      ),

      // ── Dialog ──
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        backgroundColor: _surface,
        titleTextStyle: const TextStyle(
          color: _onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      // ── BottomSheet ──
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        backgroundColor: _surface,
        elevation: 8,
      ),

      // ── FAB ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),

      // ── Snack bar ──
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: _onSurface,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      ),

      // ── Tipografia — leve, moderna ──
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: _onSurface, letterSpacing: -0.5),
        displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: _onSurface, letterSpacing: -0.3),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _onSurface),
        headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _onSurface),
        headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _onSurface),
        titleLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _onSurface),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _onSurface),
        titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _onSurface),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: _onSurface),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: _onSurface),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: _onSurfaceVariant),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _onSurface),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _onSurfaceVariant),
      ),
    );
  }
}
