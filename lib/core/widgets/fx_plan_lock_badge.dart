import 'package:flutter/material.dart';

import '../theme/brand_palette.dart';
import '../theme/tokens_strip.dart';

/// Selo compacto de recurso trancado por plano — paridade Perfil / Home.
///
/// Substitui `value` + `Icons.lock_outline` soltos na linha inset, evitando
/// truncar subtítulo em tiles de upgrade.
class FxPlanLockBadge extends StatelessWidget {
  const FxPlanLockBadge({
    super.key,
    required this.tier,
    this.brand,
    this.compact = false,
  });

  final String tier;
  final Color? brand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color =
        brand ?? BrandPalette.softened(Theme.of(context).colorScheme.primary);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = color.withValues(alpha: isDark ? 0.16 : 0.10);
    final border = color.withValues(alpha: isDark ? 0.30 : 0.24);
    final label = tier.trim().isEmpty ? 'Pro' : tier.trim();

    return Semantics(
      label: 'Recurso do plano $label',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 8,
          vertical: compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_rounded,
              size: compact ? 11 : 12,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.35,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trailing padrão de tile trancado: selo do plano + chevron de upgrade.
class FxPlanLockTrailing extends StatelessWidget {
  const FxPlanLockTrailing({
    super.key,
    required this.tier,
    this.brand,
    this.mute,
  });

  final String tier;
  final Color? brand;
  final Color? mute;

  @override
  Widget build(BuildContext context) {
    final chevronColor = mute ?? Theme.of(context).disabledColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FxPlanLockBadge(tier: tier, brand: brand, compact: true),
        const SizedBox(width: TokensStrip.s1),
        Icon(
          Icons.chevron_right,
          size: 17,
          color: chevronColor,
        ),
      ],
    );
  }
}
