import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
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
    this.utilityOnly = false,
    this.showPrioritiesAction = false,
    this.trailingActionLabel,
    this.onTrailingAction,
  });

  final bool isDark;
  final Color primary;
  final String subtitle;
  /// Modo foco: sticky curto, sem subtítulo — evita título duplicado.
  final bool compact;
  /// Barra só com Prioridades — não rotula Pulso/financeiro como Central.
  final bool utilityOnly;
  final bool showPrioritiesAction;
  final String? trailingActionLabel;
  final VoidCallback? onTrailingAction;

  static const double _maxExtent = 72;
  static const double _minExtent = 48;
  static const double _compactExtent = 44;
  static const double _utilityExtent = 48;

  @override
  double get minExtent =>
      utilityOnly ? _utilityExtent : (compact ? _compactExtent : _minExtent);

  @override
  double get maxExtent =>
      utilityOnly ? _utilityExtent : (compact ? _compactExtent : _maxExtent);

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
    final showSubtitle = !utilityOnly && !compact && progress < 0.55;
    final link = BrandPalette.sectionLink(primary, dark: isDark);
    final hasTrailing =
        trailingActionLabel != null &&
        onTrailingAction != null &&
        trailingActionLabel!.trim().isNotEmpty;

    final showTrailingChip = hasTrailing && showPrioritiesAction;
    final semanticsLabel =
        utilityOnly
            ? (trailingActionLabel?.trim().isNotEmpty == true
                ? trailingActionLabel!
                : 'Prioridades')
            : showSubtitle
            ? '${DashboardMicrocopy.commandCenterTitle}. $subtitle'
            : DashboardMicrocopy.commandCenterTitle;

    return Semantics(
      header: !utilityOnly,
      label: semanticsLabel,
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
              final layoutCompact =
                  utilityOnly || compact || constraints.maxHeight < 52;
              final showSubtitleLine =
                  showSubtitle && !layoutCompact && !showPrioritiesAction;
              final chipLabel =
                  (utilityOnly || layoutCompact) && hasTrailing
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
                    if (!utilityOnly)
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
                                  style: FocuxHubTypography.sectionTitle(
                                    context,
                                    color: heading,
                                  ),
                                ),
                                if (showSubtitleLine) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: FocuxHubTypography.bodyMuted(
                                      color: mute,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    if (showTrailingChip && chipLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Semantics(
                          button: true,
                          label: chipLabel,
                          child: TextButton(
                            onPressed: onTrailingAction,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
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
        oldDelegate.utilityOnly != utilityOnly ||
        oldDelegate.showPrioritiesAction != showPrioritiesAction ||
        oldDelegate.trailingActionLabel != trailingActionLabel;
  }
}
