import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';

/// Estilo iOS inset para aviso de risco no hero — sem poço laranja.
class Aluno360HeroRiskStyle {
  const Aluno360HeroRiskStyle({
    required this.dotColor,
    required this.iconColor,
    required this.borderColor,
    required this.surfaceColor,
  });

  final Color dotColor;
  final Color iconColor;
  final Color borderColor;
  final Color surfaceColor;

  factory Aluno360HeroRiskStyle.resolve(
    BuildContext context, {
    required String nivel,
    required bool isDark,
  }) {
    final chrome = ShellChrome.of(context);
    final upper = nivel.trim().toUpperCase();
    final accent = switch (upper) {
      'ALTO' => isDark ? EagleTokens.warnAccentSoft : EagleTokens.warnDeep,
      'MÉDIO' || 'MEDIO' =>
        isDark ? EagleTokens.warmPeachSoft : EagleTokens.warnDeepDark,
      'BAIXO' => isDark ? EagleTokens.goodAccent : EagleTokens.good,
      _ => isDark ? EagleTokens.warnAccentSoft : EagleTokens.warnDeep,
    };

    return Aluno360HeroRiskStyle(
      dotColor: accent,
      iconColor: accent,
      borderColor: chrome.line.withValues(alpha: isDark ? 0.55 : 0.42),
      surfaceColor:
          isDark
              ? chrome.cardFill.withValues(alpha: 0.72)
              : chrome.cardFill.withValues(alpha: 0.94),
    );
  }
}
