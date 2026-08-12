import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_readability.dart';

class DashboardCommandCenterStickyHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  DashboardCommandCenterStickyHeaderDelegate({
    required this.isDark,
    required this.primary,
    required this.subtitle,
    this.compact = false,
    this.showPrioritiesAction = false,
    this.trailingActionLabel,
    this.onTrailingAction,
  });

  final bool isDark;
  final Color primary;
  final String subtitle;
  /// Modo foco: sticky curto, sem subtítulo — evita título duplicado.
  final bool compact;
  final bool showPrioritiesAction;
  final String? trailingActionLabel;
  final VoidCallback? onTrailingAction;

  static const double _maxExtent = 72;
  static const double _minExtent = 48;
  static const double _compactExtent = 44;

  @override
  double get minExtent => compact ? _compactExtent : _minExtent;

  @override
  double get maxExtent => compact ? _compactExtent : _maxExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final heading = BrandPalette.sectionHeading(primary, dark: isDark);
    final mute = dashboardReadableCaption(context, isDark: isDark);
    final range = (maxExtent - minExtent).clamp(1.0, 100.0);
    final progress = (shrinkOffset / range).clamp(0.0, 1.0);
    final showSubtitle = !compact && progress < 0.55;
    final link = BrandPalette.sectionLink(primary, dark: isDark);
    final hasTrailing =
        trailingActionLabel != null &&
        onTrailingAction != null &&
        trailingActionLabel!.trim().isNotEmpty;

    final showTrailingChip = hasTrailing && showPrioritiesAction;

    return Semantics(
      header: true,
      label:
          showSubtitle
              ? '${DashboardMicrocopy.commandCenterTitle}. $subtitle'
              : DashboardMicrocopy.commandCenterTitle,
      child: Material(
        color:
            isDark ? EagleTokens.darkBg : Theme.of(context).colorScheme.surface,
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
              final layoutCompact = compact || constraints.maxHeight < 52;
              final showSubtitleLine =
                  showSubtitle && !layoutCompact && !showPrioritiesAction;
              final chipLabel =
                  layoutCompact && hasTrailing
                      ? 'Prioridades'
                      : trailingActionLabel;
              final topPad = layoutCompact ? 4.0 : (8 - (4 * progress));
              final bottomPad = layoutCompact ? 4.0 : 8.0;

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  TokensStrip.s4,
                  topPad,
                  TokensStrip.s4,
                  bottomPad,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ClipRect(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DashboardMicrocopy.commandCenterTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium!.copyWith(
                                  fontSize:
                                      15 -
                                      (1.5 * progress) -
                                      (layoutCompact ? 0.5 : 0),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  height: layoutCompact ? 1.05 : 1.12,
                                  color: heading,
                                ),
                              ),
                              if (showSubtitleLine) ...[
                                const SizedBox(height: 1),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TokensStrip.bodyMuted(
                                    color: mute,
                                  ).copyWith(height: 1.2),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (showTrailingChip && chipLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Semantics(
                          button: true,
                          label: chipLabel,
                          child: TextButton(
                            onPressed: onTrailingAction,
                            style: TextButton.styleFrom(
                              minimumSize: Size(48, layoutCompact ? 36 : 40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              foregroundColor: link,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              chipLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: dashboardActionChipStyle(link),
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
  bool shouldRebuild(
    covariant DashboardCommandCenterStickyHeaderDelegate oldDelegate,
  ) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.primary != primary ||
        oldDelegate.subtitle != subtitle ||
        oldDelegate.compact != compact ||
        oldDelegate.showPrioritiesAction != showPrioritiesAction ||
        oldDelegate.trailingActionLabel != trailingActionLabel;
  }
}
