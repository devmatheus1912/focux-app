import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_glass_surface.dart';
import '../../subscription/models/subscription_plan.dart';
import 'paywall_catalog.dart';

IconData _tierIconFor(SubscriptionPlan plan) => switch (plan) {
  SubscriptionPlan.PRO => Icons.trending_up_rounded,
  SubscriptionPlan.ENTERPRISE => Icons.diamond_outlined,
  _ => Icons.layers_outlined,
};

/// Card glass padrão Focux — mesmo sistema de Convites / shell.
class PaywallGlassCard extends StatelessWidget {
  const PaywallGlassCard({
    super.key,
    required this.child,
    this.accent,
    this.glow = false,
    this.blur = true,
    this.padding,
    this.margin,
    this.elevationLevel = 8,
    this.radius = TokensStrip.rCard,
    this.glowStrength = 1,
    this.expand = false,
  });

  final Widget child;
  final Color? accent;
  final bool glow;
  final bool blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final int elevationLevel;
  final double radius;
  final double glowStrength;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? TokensStrip.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget surface = expand
        ? Container(
            width: double.infinity,
            height: double.infinity,
            padding: padding,
            decoration: TokensStrip.glassPanel(
              dark: isDark,
              radius: radius,
              accent: accent,
              elevationLevel: elevationLevel,
            ),
            child: child,
          )
        : FxGlassSurface(
            accent: tint,
            glow: false,
            blur: blur,
            radius: radius,
            padding: padding,
            elevationLevel: elevationLevel,
            child: child,
          );
    if (expand) {
      surface = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: surface,
      );
    }
    return Padding(
      padding: margin ??
          (expand
              ? EdgeInsets.zero
              : const EdgeInsets.only(bottom: TokensStrip.s4)),
      child: _TierGlowWrapper(
        enabled: glow,
        color: tint,
        radius: radius,
        strength: glowStrength,
        child: surface,
      ),
    );
  }
}

class _TierGlowWrapper extends StatelessWidget {
  const _TierGlowWrapper({
    required this.enabled,
    required this.color,
    required this.radius,
    required this.strength,
    required this.child,
  });

  final bool enabled;
  final Color color;
  final double radius;
  final double strength;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled || TokensStrip.prefersReducedMotion(context)) return child;
    final isBrand = color == TokensStrip.primary;
    final s = (isBrand ? 0.28 : 0.14) * strength.clamp(0.0, 1.0);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: TokensStrip.coloredDepthGlow(color, strength: s),
      ),
      child: child,
    );
  }
}

/// Painel interno (loja, ROI, highlights) — fundo neutro + borda do tier.
class PaywallInsetPanel extends StatelessWidget {
  const PaywallInsetPanel({
    super.key,
    required this.child,
    required this.accent,
    required this.isDark,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  });

  final Widget child;
  final Color accent;
  final bool isDark;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final fill =
        isDark ? Colors.white.withValues(alpha: 0.05) : TokensStrip.cardBg;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(TokensStrip.rSm),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.32 : 0.2),
        ),
      ),
      child: child,
    );
  }
}

/// Medallion do tier — hero do compare e superfícies que ainda compartilham.
class PaywallTierMedallion extends StatelessWidget {
  const PaywallTierMedallion({
    super.key,
    required this.plan,
    required this.accent,
    required this.isDark,
    this.size = 44,
  });

  final SubscriptionPlan plan;
  final Color accent;
  final bool isDark;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isDark ? 0.36 : 0.22),
            accent.withValues(alpha: isDark ? 0.12 : 0.07),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
        boxShadow: TokensStrip.coloredDepthGlow(accent, strength: 0.1),
      ),
      child: Icon(
        _tierIconFor(plan),
        size: size * 0.48,
        color: PaywallCatalog.tierAccentOnSurface(plan, isDark: isDark),
      ),
    );
  }
}
