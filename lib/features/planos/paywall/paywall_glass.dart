import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_glass_surface.dart';
import '../../subscription/models/subscription_plan.dart';
import 'paywall_catalog.dart';

IconData _tierIconFor(SubscriptionPlan plan) => switch (plan) {
  SubscriptionPlan.PREMIUM => Icons.trending_up_rounded,
  SubscriptionPlan.ENTERPRISE => Icons.diamond_outlined,
  SubscriptionPlan.ENTERPRISE_PRO => Icons.workspace_premium_rounded,
  _ => Icons.layers_outlined,
};

/// Intensidade do destaque por tier (não altera [TokensStrip.primary] global).
enum PaywallTierEmphasis { low, mid, high }

/// Chrome visual compartilhado — rail, wash, tema de expansão.
abstract class PaywallTierChrome {
  static const double cardRadius = TokensStrip.rCard;

  static PaywallTierEmphasis emphasisFor({
    required bool isCurrent,
    required bool isSelected,
    required bool nested,
  }) {
    if (isCurrent || isSelected) return PaywallTierEmphasis.high;
    if (nested) return PaywallTierEmphasis.mid;
    return PaywallTierEmphasis.mid;
  }

  static double _washAlpha(PaywallTierEmphasis e, bool isDark) => switch (e) {
    PaywallTierEmphasis.high => isDark ? 0.16 : 0.11,
    PaywallTierEmphasis.mid => isDark ? 0.09 : 0.06,
    PaywallTierEmphasis.low => isDark ? 0.05 : 0.03,
  };

  static double _railAlpha(PaywallTierEmphasis e) => switch (e) {
    PaywallTierEmphasis.high => 1.0,
    PaywallTierEmphasis.mid => 0.72,
    PaywallTierEmphasis.low => 0.45,
  };

  static Widget accentRail(
    Color accent, {
    PaywallTierEmphasis emphasis = PaywallTierEmphasis.mid,
  }) {
    final rail = accent.withValues(alpha: _railAlpha(emphasis));
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(cardRadius),
          ),
          color: emphasis == PaywallTierEmphasis.high ? rail : null,
          gradient:
              emphasis == PaywallTierEmphasis.high
                  ? null
                  : LinearGradient(
                    colors: [rail, accent.withValues(alpha: 0.08)],
                  ),
        ),
      ),
    );
  }

  static Widget cardWash({
    required Color accent,
    required bool isDark,
    PaywallTierEmphasis emphasis = PaywallTierEmphasis.mid,
  }) {
    final alpha = _washAlpha(emphasis, isDark);
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cardRadius),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accent.withValues(alpha: alpha),
                accent.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.52],
            ),
          ),
        ),
      ),
    );
  }

  static ThemeData expansionTheme(BuildContext context, Color accent) {
    return Theme.of(context).copyWith(
      canvasColor: Colors.transparent,
      dividerColor: Colors.transparent,
      splashColor: accent.withValues(alpha: 0.08),
      highlightColor: accent.withValues(alpha: 0.04),
      expansionTileTheme: const ExpansionTileThemeData(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
      ),
    );
  }
}

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
  });

  final Widget child;
  final Color? accent;
  final bool glow;
  final bool blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final int elevationLevel;
  final double radius;

  /// Atenua glow de tiers (ouro/teal profundo) para não competir com o CTA do app.
  final double glowStrength;

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? TokensStrip.primary;
    return Padding(
      padding: margin ?? const EdgeInsets.only(bottom: TokensStrip.s4),
      child: _TierGlowWrapper(
        enabled: glow,
        color: tint,
        radius: radius,
        strength: glowStrength,
        child: FxGlassSurface(
          accent: tint,
          glow: false,
          blur: blur,
          radius: radius,
          padding: padding,
          elevationLevel: elevationLevel,
          child: child,
        ),
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

/// Shell premium por plano — todos os cards seguem o mesmo layout.
class PaywallTierCard extends StatelessWidget {
  const PaywallTierCard({
    super.key,
    required this.plan,
    required this.isDark,
    required this.child,
    this.isCurrent = false,
    this.isSelected = false,
    this.nestedInAccordion = false,
    this.glow,
  });

  final SubscriptionPlan plan;
  final bool isDark;
  final Widget child;
  final bool isCurrent;
  final bool isSelected;
  final bool nestedInAccordion;
  final bool? glow;

  @override
  Widget build(BuildContext context) {
    final accent = PaywallCatalog.accentForPlan(plan);
    final emphasis = PaywallTierChrome.emphasisFor(
      isCurrent: isCurrent,
      isSelected: isSelected,
      nested: nestedInAccordion,
    );
    final showGlow = glow ?? (isCurrent || isSelected);

    return PaywallGlassCard(
      margin:
          nestedInAccordion
              ? const EdgeInsets.fromLTRB(4, 0, 4, 8)
              : const EdgeInsets.only(bottom: TokensStrip.s4),
      accent: accent,
      glow: showGlow && !TokensStrip.prefersReducedMotion(context),
      glowStrength: isCurrent ? 0.42 : 0.32,
      blur: false,
      elevationLevel: isCurrent ? 12 : (isSelected ? 10 : 8),
      padding: EdgeInsets.zero,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          PaywallTierChrome.cardWash(
            accent: accent,
            isDark: isDark,
            emphasis: emphasis,
          ),
          PaywallTierChrome.accentRail(accent, emphasis: emphasis),
          child,
        ],
      ),
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

/// Medallion do tier — reutilizado no hero e nos cards.
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
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
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

/// Pill de tier unificada (hero FOCUX · tier e chip SEU PLANO / badges).
class PaywallTierBrandPill extends StatelessWidget {
  const PaywallTierBrandPill({
    super.key,
    required this.label,
    required this.accent,
    required this.isDark,
    this.icon,
    this.iconSize = 14,
  });

  final String label;
  final Color accent;
  final bool isDark;
  final IconData? icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final fg = PaywallCatalog.readableTierAccent(accent, isDark: isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: ShellChrome.forDark(
        isDark,
      ).panel(radius: TokensStrip.rPill, accent: accent, elevationLevel: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              height: 1.1,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Accordion glass com glow ao expandir.
class PaywallGlassAccordion extends StatefulWidget {
  const PaywallGlassAccordion({
    super.key,
    this.tileKey,
    required this.title,
    this.subtitle,
    required this.children,
    required this.ink,
    required this.mute,
    required this.isDark,
    this.accent,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
  });

  final Key? tileKey;
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Color ink;
  final Color mute;
  final bool isDark;
  final Color? accent;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<PaywallGlassAccordion> createState() => _PaywallGlassAccordionState();
}

class _PaywallGlassAccordionState extends State<PaywallGlassAccordion> {
  late bool _expanded;
  late bool _mountedChildren;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _mountedChildren = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(PaywallGlassAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _expanded = widget.initiallyExpanded;
      if (_expanded) _mountedChildren = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tint = widget.accent ?? TokensStrip.primary;
    final secondary = PaywallCatalog.readableSecondary(
      widget.ink,
      widget.mute,
      isDark: widget.isDark,
    );
    final reduceMotion = TokensStrip.prefersReducedMotion(context);
    final expandHint = _expanded ? 'Recolher seção' : 'Expandir seção';
    final titleSemantics =
        '${widget.title}${widget.subtitle != null ? ', ${widget.subtitle}' : ''}. $expandHint';

    return PaywallGlassCard(
      padding: EdgeInsets.zero,
      accent: tint,
      glow: _expanded && !reduceMotion,
      glowStrength: 0.28,
      blur: _expanded,
      elevationLevel: _expanded ? 10 : 7,
      child: Stack(
        children: [
          PaywallTierChrome.cardWash(
            accent: tint,
            isDark: widget.isDark,
            emphasis:
                _expanded ? PaywallTierEmphasis.mid : PaywallTierEmphasis.low,
          ),
          PaywallTierChrome.accentRail(
            tint,
            emphasis:
                _expanded ? PaywallTierEmphasis.mid : PaywallTierEmphasis.low,
          ),
          Theme(
            data: PaywallTierChrome.expansionTheme(context, tint),
            child: Semantics(
              button: true,
              expanded: _expanded,
              label: titleSemantics,
              child: ExpansionTile(
                key: widget.tileKey,
                initiallyExpanded: widget.initiallyExpanded,
                onExpansionChanged: (open) {
                  setState(() {
                    _expanded = open;
                    if (open) _mountedChildren = true;
                  });
                  widget.onExpansionChanged?.call(open);
                },
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
                title: Text(
                  widget.title,
                  style: AppTypography.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: widget.ink,
                  ),
                ),
                subtitle:
                    widget.subtitle == null
                        ? null
                        : Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: secondary,
                          ),
                        ),
                children: _mountedChildren ? widget.children : const [],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero glass para assinante — alinhado ao _HeroCard de Convites.
class PaywallSubscriberHeroGlass extends StatelessWidget {
  const PaywallSubscriberHeroGlass({
    super.key,
    required this.plan,
    required this.planLabel,
    required this.ink,
    required this.mute,
    required this.isDark,
    required this.isMaxTier,
    required this.hasUpgradePath,
    required this.viewingCurrentPlan,
    this.upgradeOffersExpanded = false,
    this.upgradeTargetSelected = false,
  });

  final SubscriptionPlan plan;
  final String planLabel;
  final Color ink;
  final Color mute;
  final bool isDark;
  final bool isMaxTier;
  final bool hasUpgradePath;
  final bool viewingCurrentPlan;
  final bool upgradeOffersExpanded;
  final bool upgradeTargetSelected;

  String get _subtitle {
    if (isMaxTier) {
      return 'Plano máximo ativo. Gerencie na loja do dispositivo.';
    }
    if (!hasUpgradePath) {
      return 'Gerencie a assinatura na loja do dispositivo.';
    }
    if (upgradeTargetSelected) {
      return 'Revise preço e benefícios abaixo — decisão rápida.';
    }
    if (upgradeOffersExpanded) {
      return 'Upgrade aberto — escolha o tier e confirme abaixo.';
    }
    if (viewingCurrentPlan) {
      return 'Recursos do seu plano abaixo. Upgrade opcional está recolhido.';
    }
    return 'Abra upgrade disponível ou gerencie na loja.';
  }

  @override
  Widget build(BuildContext context) {
    final accent = PaywallCatalog.accentForPlan(plan);
    final secondary = PaywallCatalog.readableSecondary(
      ink,
      mute,
      isDark: isDark,
    );

    return PaywallGlassCard(
      margin: const EdgeInsets.fromLTRB(0, 4, 0, TokensStrip.s3),
      accent: accent,
      glow: false,
      glowStrength: 0.35,
      blur: false,
      elevationLevel: 12,
      padding: EdgeInsets.zero,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          PaywallTierChrome.cardWash(
            accent: accent,
            isDark: isDark,
            emphasis: PaywallTierEmphasis.mid,
          ),
          PaywallTierChrome.accentRail(
            accent,
            emphasis: PaywallTierEmphasis.mid,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    PaywallTierMedallion(
                      plan: plan,
                      accent: accent,
                      isDark: isDark,
                    ),
                    const SizedBox(width: TokensStrip.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PaywallTierBrandPill(
                            label: 'FOCUX · $planLabel',
                            accent: accent,
                            isDark: isDark,
                            icon: Icons.verified_rounded,
                          ),
                          const SizedBox(height: TokensStrip.s3),
                          Text(
                            isMaxTier
                                ? 'Plano máximo'
                                : 'Você está no $planLabel',
                            style: AppTypography.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              letterSpacing: -0.5,
                              color: ink,
                              height: 1.12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TokensStrip.s3),
                Text(
                  _subtitle,
                  style: TokensStrip.bodyMuted(
                    color: secondary,
                  ).copyWith(fontSize: TokensStrip.fontBodySm, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
