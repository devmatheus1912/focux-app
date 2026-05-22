import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/fx_icon.dart';
import 'design_tokens.dart';
import 'theme_provider.dart';

/// Dual-theme surface system for shell tabs over the cinematic mesh.
class ShellPalette {
  const ShellPalette(this.isDark);

  final bool isDark;

  Color get ink => isDark ? EagleTokens.darkInk : EagleTokens.ink;
  Color get mute => isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
  Color get line => isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;
  Color get lineStrong => isDark ? EagleTokens.glassBorder : EagleTokens.line;

  /// Solid fill for inputs and flat surfaces.
  Color get cardFill =>
      isDark
          ? EagleTokens.darkCard.withValues(alpha: 0.88)
          : Colors.white.withValues(alpha: 0.94);

  /// Bottom sheet / modal surface.
  Color get sheetFill =>
      isDark
          ? EagleTokens.darkBg.withValues(alpha: 0.96)
          : Colors.white.withValues(alpha: 0.98);

  BoxDecoration panel({
    double radius = 20,
    Color? accent,
  }) {
    if (isDark) {
      final tint = accent ?? EagleTokens.brandAccent;
      return BoxDecoration(
        color: EagleTokens.darkCard.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color:
              accent != null
                  ? tint.withValues(alpha: 0.30)
                  : EagleTokens.glassBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 12),
            spreadRadius: -10,
          ),
          if (accent != null)
            BoxShadow(
              color: tint.withValues(alpha: 0.14),
              blurRadius: 32,
              offset: const Offset(0, 14),
              spreadRadius: -8,
            ),
        ],
      );
    }

    final tint = accent ?? EagleTokens.brandAccent;
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: tint.withValues(alpha: accent != null ? 0.20 : 0.14),
      ),
      boxShadow: [
        BoxShadow(
          color: EagleTokens.ink.withValues(alpha: 0.06),
          blurRadius: 22,
          offset: const Offset(0, 10),
          spreadRadius: -6,
        ),
        if (accent != null)
          BoxShadow(
            color: tint.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: -8,
          )
        else
          BoxShadow(
            color: EagleTokens.brandAccent.withValues(alpha: 0.05),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -12,
          ),
      ],
    );
  }

  BoxDecoration listCard({
    bool selected = false,
    Color? primary,
    double radius = 20,
  }) {
    final accent = primary ?? EagleTokens.brandAccent;
    if (selected) {
      return BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: accent.withValues(alpha: 0.5),
          width: 1.5,
        ),
      );
    }
    return panel(radius: radius);
  }

  BoxDecoration headerAction({double radius = 14}) {
    return BoxDecoration(
      color:
          isDark
              ? EagleTokens.darkCard.withValues(alpha: 0.78)
              : Colors.white.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.14)
                : EagleTokens.brandAccent.withValues(alpha: 0.10),
      ),
      boxShadow:
          isDark
              ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
              : [
                BoxShadow(
                  color: EagleTokens.ink.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
    );
  }

  BoxDecoration bottomSheet({double radius = 28}) {
    return BoxDecoration(
      color: sheetFill,
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      border: Border(
        top: BorderSide(color: line),
        left: BorderSide(color: line.withValues(alpha: 0.5)),
        right: BorderSide(color: line.withValues(alpha: 0.5)),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.14),
          blurRadius: 32,
          offset: const Offset(0, -12),
        ),
      ],
    );
  }

  BoxDecoration accentPanel({
    required Color accent,
    double radius = 20,
  }) => panel(radius: radius, accent: accent);

  BoxDecoration searchField({Color? primary, double radius = 16}) {
    final accent = primary ?? EagleTokens.brandAccent;
    return BoxDecoration(
      color: cardFill,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark ? line : accent.withValues(alpha: 0.12),
      ),
      boxShadow:
          isDark
              ? null
              : [
                BoxShadow(
                  color: EagleTokens.ink.withValues(alpha: 0.03),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
    );
  }
}

abstract class ShellChrome {
  static ShellPalette of(BuildContext context) =>
      ShellPalette(Theme.of(context).brightness == Brightness.dark);

  static ShellPalette forDark(bool isDark) => ShellPalette(isDark);
}

/// Moon/sun toggle used on shell tab headers.
class ShellThemeToggle extends ConsumerWidget {
  const ShellThemeToggle({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chrome = ShellChrome.of(context);
    final icon = isDark ? 'sun' : 'moon';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ref.read(themeModeProvider.notifier).toggle(),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: size,
          height: size,
          decoration: chrome.headerAction(),
          child: Center(
            child: FxIcon(name: icon, size: 18, color: chrome.mute),
          ),
        ),
      ),
    );
  }
}
