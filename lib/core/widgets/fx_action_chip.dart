import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/brand_palette.dart';
import '../theme/design_tokens.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/tokens_strip.dart';
import 'fx_help.dart';

/// Chip de ação in-card (§10). Tonal por padrão (P1); `solid` só no P0 da
/// viewport (§11). Largura sempre intrínseca — nunca estica no `Wrap`.
class FxActionChip extends StatelessWidget {
  const FxActionChip({
    super.key,
    required this.label,
    required this.accent,
    required this.isDark,
    required this.onPressed,
    this.enabled = true,
    this.solid = false,
  });

  final String label;
  final Color accent;
  final bool isDark;
  final VoidCallback onPressed;
  final bool enabled;
  final bool solid;

  static Color solidBackground(Color primary, {required bool isDark}) =>
      isDark ? primary.withValues(alpha: 0.94) : primary;

  static Color solidForeground({required bool isDark}) =>
      isDark ? EagleTokens.brandDeep : Colors.white;

  static Color tonalBackground(Color accent, {required bool isDark}) =>
      BrandPalette.soft(accent, dark: isDark);

  static Color tonalForeground(Color accent, {required bool isDark}) =>
      isDark
          ? Color.lerp(BrandPalette.accent(accent), Colors.white, 0.55)!
          : BrandPalette.deep(accent);

  @override
  Widget build(BuildContext context) {
    final fg =
        solid
            ? solidForeground(isDark: isDark)
            : tonalForeground(accent, isDark: isDark);
    final bg =
        solid
            ? solidBackground(accent, isDark: isDark)
            : tonalBackground(accent, isDark: isDark);
    final shape =
        solid
            ? const StadiumBorder()
            : StadiumBorder(
              side: BorderSide(
                color: accent.withValues(alpha: isDark ? 0.40 : 0.28),
              ),
            );

    return Align(
      widthFactor: 1,
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: Opacity(
          opacity: enabled ? 1 : 0.42,
          child: Material(
            color: bg,
            elevation: solid && enabled ? (isDark ? 4 : 2) : 0,
            shadowColor: accent.withValues(alpha: isDark ? 0.38 : 0.14),
            shape: shape,
            child: InkWell(
              onTap:
                  enabled
                      ? () {
                        HapticFeedback.selectionClick();
                        onPressed();
                      }
                      : null,
              customBorder: const StadiumBorder(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: FxHelpChrome.touchTarget,
                  minWidth: FxHelpChrome.touchTarget,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TokensStrip.s4,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: FocuxHubTypography.chip(fg).copyWith(
                        fontWeight: solid ? FontWeight.w800 : FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
