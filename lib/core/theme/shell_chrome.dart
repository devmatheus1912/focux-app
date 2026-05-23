import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/fx_icon.dart';
import 'design_tokens.dart';
import 'theme_provider.dart';
import 'tokens_strip.dart';

/// Dual-theme Liquid Glass surface system for shell tabs over cinematic mesh.
class ShellPalette {
  const ShellPalette(this.isDark);

  final bool isDark;

  Color get ink => isDark ? EagleTokens.darkInk : EagleTokens.ink;
  Color get mute => isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
  Color get line => isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;
  Color get lineStrong => isDark ? EagleTokens.glassBorder : EagleTokens.line;

  Color get cardFill => TokensStrip.glassFill(dark: isDark, opacity: 0.94);

  Color get sheetFill =>
      isDark
          ? EagleTokens.darkBg.withValues(alpha: 0.96)
          : Colors.white.withValues(alpha: 0.98);

  BoxDecoration panel({
    double radius = TokensStrip.rLg,
    Color? accent,
    int elevationLevel = 8,
  }) {
    return TokensStrip.glassPanel(
      dark: isDark,
      radius: radius,
      accent: accent,
      elevationLevel: elevationLevel,
    );
  }

  BoxDecoration listCard({
    bool selected = false,
    Color? primary,
    double radius = TokensStrip.rLg,
  }) {
    final accent = primary ?? EagleTokens.brandAccent;
    if (selected) {
      return BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: accent.withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: TokensStrip.interactiveGlow(
          accent,
          intensity: 0.55,
          dark: isDark,
        ),
      );
    }
    return panel(radius: radius, accent: primary);
  }

  BoxDecoration headerAction({double radius = TokensStrip.rSm}) {
    return TokensStrip.glassPanel(
      dark: isDark,
      radius: radius,
      elevationLevel: 4,
    );
  }

  BoxDecoration bottomSheet({double radius = TokensStrip.rXl}) {
    return BoxDecoration(
      color: sheetFill,
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      border: Border(
        top: BorderSide(color: TokensStrip.glassBorder(dark: isDark)),
        left: BorderSide(
          color: TokensStrip.glassBorder(dark: isDark).withValues(alpha: 0.5),
        ),
        right: BorderSide(
          color: TokensStrip.glassBorder(dark: isDark).withValues(alpha: 0.5),
        ),
      ),
      boxShadow: TokensStrip.elevation(24, dark: isDark),
    );
  }

  BoxDecoration accentPanel({
    required Color accent,
    double radius = TokensStrip.rLg,
  }) => panel(radius: radius, accent: accent, elevationLevel: 12);

  BoxDecoration searchField({Color? primary, double radius = TokensStrip.rMd}) {
    final accent = primary ?? EagleTokens.brandAccent;
    return TokensStrip.glassPanel(
      dark: isDark,
      radius: radius,
      accent: accent,
      elevationLevel: 4,
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
        borderRadius: BorderRadius.circular(TokensStrip.rSm),
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
