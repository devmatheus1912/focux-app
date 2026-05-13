import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Premium input decoration factory — Eagle Design System.
///
/// Drop-in replacement for the banned `InputDecoration(border: OutlineInputBorder())`.
/// Usage: `decoration: FxInputDeco.build(context, 'Label', icon: Icons.person)`
class FxInputDeco {
  static OutlineInputBorder outlineBorder({
    BorderRadius? borderRadius,
    BorderSide? borderSide,
  }) {
    return OutlineInputBorder(
      borderRadius: borderRadius ?? BorderRadius.circular(14),
      borderSide: borderSide ?? BorderSide.none,
    );
  }

  static InputDecoration build(
    BuildContext context,
    String label, {
    IconData? icon,
    String? hint,
    Widget? suffix,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final primary = Theme.of(context).colorScheme.primary;
    final card = isDark ? EagleTokens.darkCard : EagleTokens.card;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        color: mute,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(color: mute.withValues(alpha: 0.5), fontSize: 13.5),
      prefixIcon: icon != null ? Icon(icon, size: 20, color: mute) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: EagleTokens.bad),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: EagleTokens.bad, width: 1.6),
      ),
    );
  }
}
