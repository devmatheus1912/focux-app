import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/fx_settings_layout.dart';
import '../theme/tokens_strip.dart';

/// Premium input decoration factory — TOKENS STRIP Liquid Glass.
class FxInputDeco {
  /// Placeholder e rótulo flutuante: contraste ≥ 4,5:1 sobre o card/fundo do
  /// tema — no modo [insetGrouped] o placeholder é o único rótulo visível.
  static Color placeholderColor({required bool isDark}) =>
      isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

  static OutlineInputBorder outlineBorder({
    BorderRadius? borderRadius,
    BorderSide? borderSide,
  }) {
    return OutlineInputBorder(
      borderRadius: borderRadius ?? BorderRadius.circular(TokensStrip.rSm),
      borderSide: borderSide ?? BorderSide.none,
    );
  }

  static InputDecoration build(
    BuildContext context,
    String label, {
    IconData? icon,
    String? hint,
    Widget? suffix,
    Color? iconColor,
    double iconSize = 20,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final primary = Theme.of(context).colorScheme.primary;
    final fillColor =
        isDark
            ? EagleTokens.darkCardHi.withValues(alpha: 0.88)
            : Colors.white.withValues(alpha: 0.92);
    final borderColor = TokensStrip.glassBorder(dark: isDark, accent: primary);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: FocuxHubTypography.bodyMuted(
        color: placeholderColor(isDark: isDark),
        fontWeight: FontWeight.w600,
      ),
      hintStyle: FocuxHubTypography.bodyMuted(
        color: placeholderColor(isDark: isDark),
      ),
      prefixIcon:
          icon != null
              ? Icon(icon, size: iconSize, color: iconColor ?? mute)
              : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: TokensStrip.s4,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TokensStrip.rSm),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TokensStrip.rSm),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TokensStrip.rSm),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TokensStrip.rSm),
        borderSide: const BorderSide(color: EagleTokens.bad),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TokensStrip.rSm),
        borderSide: const BorderSide(color: EagleTokens.bad, width: 1.5),
      ),
    );
  }

  /// Campo borderless dentro de [FxSettingsGroup] — sem caixa aninhada nem label
  /// flutuante (evita clip no topo do card inset).
  static InputDecoration insetGrouped(
    BuildContext context, {
    IconData? icon,
    String? hint,
    Widget? suffix,
    Color? iconColor,
    double iconSize = FxSettingsLayout.iconSize,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return InputDecoration(
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      hintStyle: FocuxHubTypography.bodyMuted(
        color: placeholderColor(isDark: isDark),
      ),
      prefixIcon:
          icon != null
              ? Icon(icon, size: iconSize, color: iconColor ?? mute)
              : null,
      prefixIconConstraints: const BoxConstraints(
        minWidth: FxSettingsLayout.insetPrefixWidth,
        minHeight: FxSettingsLayout.insetPrefixWidth,
      ),
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(
        minWidth: 28,
        minHeight: FxSettingsLayout.insetPrefixWidth,
      ),
      filled: false,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: TokensStrip.s3,
      ),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
    );
  }
}
