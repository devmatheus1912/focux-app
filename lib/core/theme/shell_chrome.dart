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

  Color get ink => isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
  Color get mute =>
      isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
  Color get line => isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;
  Color get lineStrong => isDark ? EagleTokens.glassBorder : EagleTokens.line;

  Color get cardFill => TokensStrip.glassFill(dark: isDark, opacity: 0.94);

  Color get sheetFill =>
      isDark
          ? EagleTokens.darkBg.withValues(alpha: 0.96)
          : Colors.white.withValues(alpha: 0.98);

  BoxDecoration panel({
    double radius = TokensStrip.rCard,
    Color? accent,
    int elevationLevel = 3,
  }) {
    if (isDark) {
      return TokensStrip.glassPanel(
        dark: true,
        radius: radius,
        accent: accent,
        elevationLevel: elevationLevel,
      );
    }
    return BoxDecoration(
      color: TokensStrip.cardBg.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color:
            accent != null
                ? accent.withValues(alpha: 0.28)
                : TokensStrip.borderDefault,
        width: accent != null ? 1.2 : 1,
      ),
      boxShadow: [
        ...TokensStrip.cardShadow(),
        ...TokensStrip.coloredDepthGlow(
          accent ?? TokensStrip.primary,
          strength: accent != null ? 0.32 : 0.22,
        ),
      ],
    );
  }

  BoxDecoration listCard({
    bool selected = false,
    Color? primary,
    double radius = TokensStrip.rCard,
  }) {
    final accent = primary ?? EagleTokens.brandAccent;
    if (selected) {
      return BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
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
    if (isDark) {
      return TokensStrip.glassPanel(
        dark: true,
        radius: radius,
        elevationLevel: 4,
      );
    }
    return BoxDecoration(
      color: TokensStrip.cardBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: TokensStrip.primary.withValues(alpha: 0.14)),
      boxShadow: [
        ...TokensStrip.cardShadow(),
        ...TokensStrip.coloredDepthGlow(TokensStrip.primary, strength: 0.22),
      ],
    );
  }

  BoxDecoration bottomSheet({double radius = TokensStrip.rXl}) {
    return BoxDecoration(
      color: sheetFill,
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
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

/// Moon/sun toggle — TOKENS STRIP header chrome.
class ShellThemeToggle extends ConsumerWidget {
  const ShellThemeToggle({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chrome = ShellChrome.of(context);
    final icon = chrome.isDark ? 'sun' : 'moon';

    return ShellHeaderIconButton(
      icon: icon,
      size: size,
      onTap: () => ref.read(themeModeProvider.notifier).toggle(),
    );
  }
}

/// Circular header control — strip card (light) / glass (dark).
class ShellHeaderIconButton extends StatelessWidget {
  const ShellHeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 38,
    this.badgeCount = 0,
    this.tooltip,
  });

  final String icon;
  final VoidCallback onTap;
  final double size;
  final int badgeCount;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final radius = size / 2;
    final compact = size <= 38;
    final dotSize = compact ? 7.0 : 8.0;

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: size,
          height: size,
          decoration: chrome.headerAction(radius: radius),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              FxIcon(name: icon, size: size * 0.48, color: chrome.ink),
              if (badgeCount > 0)
                Positioned(
                  top: compact ? -1 : size * 0.06,
                  right: compact ? -1 : size * 0.08,
                  child: Container(
                    width: badgeCount > 9 ? null : dotSize,
                    height: badgeCount > 9 ? null : dotSize,
                    constraints:
                        badgeCount > 9
                            ? BoxConstraints(
                              minWidth: compact ? 15 : 18,
                              minHeight: compact ? 14 : 16,
                            )
                            : null,
                    padding:
                        badgeCount > 9
                            ? EdgeInsets.symmetric(
                              horizontal: compact ? 3 : 4,
                              vertical: compact ? 1 : 0,
                            )
                            : null,
                    decoration: BoxDecoration(
                      color: TokensStrip.primary,
                      shape:
                          badgeCount > 9 ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius:
                          badgeCount > 9 ? BorderRadius.circular(999) : null,
                      border: Border.all(
                        color:
                            chrome.isDark
                                ? TokensStrip.cinematicSurface
                                : TokensStrip.cardBg,
                        width: compact ? 1.25 : 1.5,
                      ),
                      boxShadow: TokensStrip.coloredDepthGlow(
                        TokensStrip.primary,
                        strength: compact ? 0.28 : 0.35,
                      ),
                    ),
                    alignment: Alignment.center,
                    child:
                        badgeCount > 9
                            ? Text(
                              '9+',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: compact ? 7 : 8,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            )
                            : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
