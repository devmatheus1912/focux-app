import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';

class DashboardCommandCenterStickyHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  DashboardCommandCenterStickyHeaderDelegate({
    required this.isDark,
    required this.primary,
    required this.subtitle,
  });

  final bool isDark;
  final Color primary;
  final String subtitle;

  static const double _maxExtent = 68;
  static const double _minExtent = 46;

  @override
  double get minExtent => _minExtent;

  @override
  double get maxExtent => _maxExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final heading = BrandPalette.sectionHeading(primary, dark: isDark);
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final progress = (shrinkOffset / (_maxExtent - _minExtent)).clamp(0.0, 1.0);
    final showSubtitle = progress < 0.55;

    return Semantics(
      header: true,
      label: showSubtitle
          ? 'Central de Comando. $subtitle'
          : 'Central de Comando',
      child: Material(
        color: isDark ? EagleTokens.darkBg : Theme.of(context).colorScheme.surface,
        elevation: overlapsContent ? 1 : 0,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: overlapsContent ? 0.08 : 0.04,
                ),
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              TokensStrip.s4,
              8 - (4 * progress),
              TokensStrip.s4,
              8,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Central de Comando',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.inter(
                      fontSize: TokensStrip.fontH2 - (2 * progress),
                      fontWeight: TokensStrip.weightH2,
                      letterSpacing: TokensStrip.trackingH2,
                      height: 1.15,
                      color: heading,
                    ),
                  ),
                  if (showSubtitle) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        fontSize: TokensStrip.fontBodySm,
                        fontWeight: FontWeight.w400,
                        height: TokensStrip.leadingBody,
                        color: mute,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant DashboardCommandCenterStickyHeaderDelegate oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.primary != primary ||
        oldDelegate.subtitle != subtitle;
  }
}
