import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';

/// Tipografia padronizada do módulo financeiro.
abstract class FinanceiroTypography {
  static TextStyle alunoNome(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return FocuxHubTypography.body(color: chrome.ink).copyWith(
      fontWeight: FontWeight.w800,
      height: 1.2,
      letterSpacing: -0.15,
    );
  }

  static TextStyle valorMonetario(BuildContext context, {Color? color}) {
    return AppTypography.mono(
      fontSize: TokensStrip.fontBody,
      fontWeight: FontWeight.w700,
      color: color ?? ShellChrome.of(context).ink,
    );
  }

  static TextStyle meta(BuildContext context) {
    return FocuxHubTypography.bodyMuted(
      color: ShellChrome.of(context).mute,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle badge(BuildContext context, Color fg) {
    return FocuxHubTypography.chip(fg);
  }
}
