import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../constants/aluno_360_layout.dart';

class Aluno360MeasurementCard extends StatelessWidget {
  const Aluno360MeasurementCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.isDark,
    this.emptyHint,
    this.onTap,
    this.semanticsLabel,
  });

  final String label;
  final String value;
  final String unit;
  final bool isDark;
  final String? emptyHint;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final primary = Theme.of(context).colorScheme.primary;
    final child = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: fxListCardDecoration(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Aluno360Layout.captionStyle(context).copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: mute,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: ink,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: Aluno360Layout.captionStyle(context).copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: mute,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 14,
            child: Center(
              child:
                  emptyHint == null
                      ? const SizedBox.shrink()
                      : Text(
                        emptyHint!,
                        style: Aluno360Layout.chipLabelStyle(
                          context,
                          color: primary,
                        ).copyWith(fontSize: 10),
                      ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    final a11yLabel = semanticsLabel ?? '$label $value $unit';
    return Semantics(
      button: true,
      label: '$a11yLabel. Toque para $emptyHint',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        child: child,
      ),
    );
  }
}

/// Compact weekly trend for module tiles (e.g. Aderência).
class Aluno360FerramentasMiniSparkline extends StatelessWidget {
  const Aluno360FerramentasMiniSparkline({
    super.key,
    required this.data,
    required this.color,
    required this.semanticsLabel,
  });

  final List<double> data;
  final Color color;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: FxSparkline(
          data: data,
          color: color,
          width: 44,
          height: 18,
          strokeWidth: 1.8,
          fill: false,
        ),
      ),
    );
  }
}

class Aluno360ModuleTile extends StatelessWidget {
  const Aluno360ModuleTile({
    super.key,
    required this.icon,
    required this.label,
    required this.sub,
    required this.isDark,
    required this.onTap,
    this.badge,
    this.highlight = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String sub;
  final String? badge;
  final bool isDark;
  final bool highlight;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final badgeLabel = badge != null ? ', $badge' : '';
    final badgeInk = BrandPalette.deep(primary);

    return Semantics(
      button: true,
      label: '$label$badgeLabel. $sub',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration:
              highlight
                  ? fxListCardDecoration(
                    context,
                    accent: primary,
                    selected: true,
                  )
                  : fxListCardDecoration(context),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: highlight ? 0.18 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 17, color: primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          color: highlight ? primary : ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Aluno360Layout.cardSubtitleStyle(context).copyWith(
                          fontSize: 11,
                          color: highlight ? BrandPalette.deep(primary) : mute,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            badge!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: badgeInk,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
