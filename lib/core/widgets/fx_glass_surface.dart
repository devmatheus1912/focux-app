import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/tokens_strip.dart';
import 'fx_motion.dart';

/// Realistic liquid-glass surface with optional blur and interactive glow.
class FxGlassSurface extends StatelessWidget {
  const FxGlassSurface({
    super.key,
    required this.child,
    this.radius = TokensStrip.rLg,
    this.padding,
    this.accent,
    this.blur = false,
    this.glow = false,
    this.elevationLevel = 8,
    this.onTap,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final Color? accent;
  final bool blur;
  final bool glow;
  final int elevationLevel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = accent ?? Theme.of(context).colorScheme.primary;
    final decoration = TokensStrip.glassPanel(
      dark: isDark,
      radius: radius,
      accent: accent,
      elevationLevel: elevationLevel,
    );

    Widget surface = Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (blur) {
      surface = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: TokensStrip.blurFilter(
            isDark ? TokensStrip.blurMedium : TokensStrip.blurLight,
          ),
          child: surface,
        ),
      );
    } else {
      surface = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: surface,
      );
    }

    if (onTap != null) {
      surface = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: surface,
        ),
      );
    }

    if (glow && !TokensStrip.prefersReducedMotion(context)) {
      return FxInteractiveGlow(
        color: tint,
        borderRadius: radius,
        child: surface,
      );
    }

    return surface;
  }
}
