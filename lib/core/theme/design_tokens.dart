import 'package:flutter/material.dart';

/// Eagle Precision Design System — Focux
/// Fonte única de verdade para todos os tokens visuais.
/// Use SEMPRE esses valores; nunca hardcode cores diretamente nas telas.
abstract class EagleTokens {
  // ── Brand ─────────────────────────────────────────────────────────────
  /// Azul primário Royal Blue — cor principal da marca
  static const Color primary = Color(0xFF2B4A9E);

  /// Gradiente hero claro (Dashboard, Detalhe Aluno, Treino)
  static const List<Color> heroGradientLight = [
    Color(0xFF1E3A8A),
    Color(0xFF2B4A9E),
  ];

  /// Gradiente hero escuro (Midnight theme)
  static const List<Color> heroGradientDark = [
    Color(0xFF0F1F5C),
    Color(0xFF1A2E6B),
  ];

  // ── Semânticos ────────────────────────────────────────────────────────
  /// Vermelho para inadimplente, erro, risco alto
  static const Color danger = Color(0xFFEF4444);

  /// Amarelo/laranja para inativo, atenção, risco médio
  static const Color warning = Color(0xFFF59E0B);

  /// Verde para aderência alta, sucesso, ativo
  static const Color success = Color(0xFF22C55E);

  /// Cinza secundário para texto de suporte
  static const Color textSecondary = Color(0xFF717171);

  /// Cinza secundário dark
  static const Color textSecondaryDark = Color(0xFF9090A0);

  // ── Background & Surface ──────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF9F9F9);
  static const Color backgroundDark  = Color(0xFF0D0D0D);
  static const Color surfaceLight    = Color(0xFFFFFFFF);
  static const Color surfaceDark     = Color(0xFF1A1A2E);

  // ── Texto ─────────────────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF222222);
  static const Color textPrimaryDark  = Color(0xFFF0F0F0);

  // ── Bordas ────────────────────────────────────────────────────────────
  static const Color outlineLight = Color(0xFFDDDDDD);
  static const Color outlineDark  = Color(0xFF2A2A3E);

  // ── Border Radius ─────────────────────────────────────────────────────
  static const double radiusCard   = 16.0;
  static const double radiusButton = 12.0;
  static const double radiusChip   = 20.0;
  static const double radiusSheet  = 20.0;
  static const double radiusSmall  = 8.0;

  // ── Aderência ─────────────────────────────────────────────────────────
  /// Cor semântica de aderência baseada no valor percentual
  static Color aderenciaColor(double taxa) {
    if (taxa >= 75) return success;
    if (taxa >= 50) return warning;
    return danger;
  }

  /// Rótulo de aderência
  static String aderenciaLabel(double taxa) {
    if (taxa >= 75) return 'Excelente';
    if (taxa >= 50) return 'Regular';
    return 'Baixa';
  }

  // ── Status de Aluno ───────────────────────────────────────────────────
  static Color statusAlunoColor(String status) {
    switch (status.toUpperCase()) {
      case 'ATIVO':       return success;
      case 'INADIMPLENTE': return danger;
      case 'INATIVO':     return warning;
      default:            return textSecondary;
    }
  }

  // ── Gradiente Hero Builder ────────────────────────────────────────────
  static LinearGradient heroGradient({bool dark = false}) => LinearGradient(
        colors: dark ? heroGradientDark : heroGradientLight,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
