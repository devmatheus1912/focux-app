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
    this.showPrioritiesAction = false,
    this.trailingActionLabel,
    this.onTrailingAction,
  });

  final bool isDark;
  final Color primary;
  final String subtitle;
  final bool showPrioritiesAction;
  final String? trailingActionLabel;
  final VoidCallback? onTrailingAction;

  static const double _maxExtent = 72;
  static const double _minExtent = 48;

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
    final link = BrandPalette.sectionLink(primary, dark: isDark);
    final hasTrailing =
        trailingActionLabel != null &&
        onTrailingAction != null &&
        trailingActionLabel!.trim().isNotEmpty;

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 52;
              final showSubtitleLine = showSubtitle && !compact;
              final topPad = compact ? 4.0 : (8 - (4 * progress));
              final bottomPad = compact ? 4.0 : 8.0;

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  TokensStrip.s4,
                  topPad,
                  TokensStrip.s4,
                  bottomPad,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: ClipRect(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Central de Comando',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.inter(
                                  fontSize:
                                      TokensStrip.fontH2 -
                                      (2 * progress) -
                                      (compact ? 1 : 0),
                                  fontWeight: TokensStrip.weightH2,
                                  letterSpacing: TokensStrip.trackingH2,
                                  height: compact ? 1.05 : 1.12,
                                  color: heading,
                                ),
                              ),
                              if (showSubtitleLine) ...[
                                const SizedBox(height: 1),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.inter(
                                    fontSize: TokensStrip.fontBodySm,
                                    fontWeight: FontWeight.w400,
                                    height: 1.2,
                                    color: mute,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (hasTrailing && showPrioritiesAction)
                      Semantics(
                        button: true,
                        label: trailingActionLabel,
                        child: TextButton(
                          onPressed: onTrailingAction,
                          style: TextButton.styleFrom(
                            minimumSize: Size(48, compact ? 32 : 36),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            foregroundColor: link,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            trailingActionLabel!,
                            style: AppTypography.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant DashboardCommandCenterStickyHeaderDelegate oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.primary != primary ||
        oldDelegate.subtitle != subtitle ||
        oldDelegate.showPrioritiesAction != showPrioritiesAction ||
        oldDelegate.trailingActionLabel != trailingActionLabel;
  }
}
