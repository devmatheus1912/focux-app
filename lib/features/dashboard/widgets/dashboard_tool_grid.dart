import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../planos/utils/effective_plano_features.dart';
import '../data/dashboard_tool_shortcuts.dart';
import '../utils/dashboard_a11y.dart';
import '../utils/dashboard_haptic.dart';
import '../utils/dashboard_readability.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../utils/dashboard_tool_groups.dart';

class DashboardExpandableToolGroups extends ConsumerStatefulWidget {
  const DashboardExpandableToolGroups({
    super.key,
    required this.groups,
    required this.isDark,
    required this.shortcutAspectRatio,
    required this.searchQuery,
    required this.onShortcut,
  });

  final List<DashboardToolGroupSection> groups;
  final bool isDark;
  final double shortcutAspectRatio;
  final String searchQuery;
  final void Function(DashboardToolShortcut shortcut) onShortcut;

  @override
  ConsumerState<DashboardExpandableToolGroups> createState() =>
      DashboardExpandableToolGroupsState();
}

class DashboardExpandableToolGroupsState
    extends ConsumerState<DashboardExpandableToolGroups> {
  late Set<String> _openGroups;

  @override
  void initState() {
    super.initState();
    _openGroups = <String>{};
  }

  @override
  void didUpdateWidget(covariant DashboardExpandableToolGroups oldWidget) {
    super.didUpdateWidget(oldWidget);
    final q = widget.searchQuery.trim();
    final oldQ = oldWidget.searchQuery.trim();
    if (q.isNotEmpty && q != oldQ) {
      _openGroups = widget.groups.map((g) => g.title).toSet();
    } else if (q.isEmpty && oldQ.isNotEmpty) {
      _openGroups = <String>{};
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final link = BrandPalette.sectionLink(primary, dark: widget.isDark);
    final badgeBg = BrandPalette.soft(primary, dark: widget.isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in widget.groups) ...[
          Material(
            color: Colors.transparent,
            child: Semantics(
              button: true,
              expanded: _openGroups.contains(group.title),
              label: dashboardToolGroupSemanticsLabel(
                group.title,
                _openGroups.contains(group.title),
                group.shortcuts.length,
              ),
              child: InkWell(
                onTap:
                    () => setState(() {
                      dashboardHapticCollapseToggle();
                      if (_openGroups.contains(group.title)) {
                        _openGroups.remove(group.title);
                      } else {
                        _openGroups.add(group.title);
                      }
                    }),
                borderRadius: BorderRadius.circular(TokensStrip.rInput),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        group.title,
                        style: FocuxHubTypography.eyebrow(
                          context,
                          color: link,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${group.shortcuts.length}',
                          style: dashboardChipLabelStyle(
                            link.withValues(alpha: 0.88),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _openGroups.contains(group.title)
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 20,
                        color: link,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_openGroups.contains(group.title))
            DashboardShortcutGrid(
              shortcuts: group.shortcuts,
              isDark: widget.isDark,
              aspectRatio: widget.shortcutAspectRatio,
              onShortcut: widget.onShortcut,
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class DashboardShortcutGrid extends ConsumerWidget {
  const DashboardShortcutGrid({
    super.key,
    required this.shortcuts,
    required this.isDark,
    required this.aspectRatio,
    required this.onShortcut,
  });

  final List<DashboardToolShortcut> shortcuts;
  final bool isDark;
  final double aspectRatio;
  final void Function(DashboardToolShortcut shortcut) onShortcut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = effectivePlanoFeatures(ref);
    final rows = <Widget>[];

    Widget tile(DashboardToolShortcut shortcut) {
      return DashboardShortcutTile(
        icon: shortcut.icon,
        label: shortcut.label,
        semanticsLabel: dashboardShortcutSemanticsLabel(shortcut),
        isDark: isDark,
        locked: !shortcut.isUnlocked(features),
        tierLabel:
            shortcut.isUnlocked(features) ? null : shortcut.tierBadgeLabel(),
        onTap: () => onShortcut(shortcut),
      );
    }

    for (var i = 0; i < shortcuts.length; i += 2) {
      if (i + 1 < shortcuts.length) {
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: tile(shortcuts[i]),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: tile(shortcuts[i + 1]),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        final gridWidth =
            MediaQuery.sizeOf(context).width - (TokensStrip.s4 * 2);
        final tileHeight = ((gridWidth - 10) / 2) / aspectRatio;
        rows.add(
          SizedBox(
            height: tileHeight,
            width: double.infinity,
            child: tile(shortcuts[i]),
          ),
        );
      }
      if (i + 2 < shortcuts.length) {
        rows.add(const SizedBox(height: 9));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class DashboardShortcutTile extends StatelessWidget {
  final String icon;
  final String label;
  final String? semanticsLabel;
  final VoidCallback onTap;
  final bool isDark;
  final bool locked;
  final String? tierLabel;

  const DashboardShortcutTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.semanticsLabel,
    this.locked = false,
    this.tierLabel,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryAccent = BrandPalette.accent(primary);
    final rowAccent = BrandPalette.sectionAccent(primary, dark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = dashboardReadableMuted(context, isDark: isDark);
    final iconAccent =
        locked
            ? (isDark ? primaryAccent : rowAccent).withValues(alpha: 0.45)
            : (isDark ? primaryAccent : rowAccent);
    final labelColor = locked ? ink.withValues(alpha: 0.52) : ink;

    return Semantics(
      label:
          locked
              ? '${semanticsLabel ?? label}, trancado. Plano ${tierLabel ?? 'upgrade'}'
              : (semanticsLabel ?? label),
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        child: Opacity(
          opacity: locked ? 0.92 : 1,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            clipBehavior: Clip.hardEdge,
            decoration: fxStripCardDecoration(
              context,
              accent: primary,
              radius: TokensStrip.rCard,
              glowStrength: locked ? 0.06 : 0.12,
            ).copyWith(
              border:
                  locked
                      ? Border.all(
                        color: mute.withValues(alpha: 0.22),
                        width: 1,
                      )
                      : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            iconAccent.withValues(alpha: isDark ? 0.20 : 0.12),
                            iconAccent.withValues(alpha: isDark ? 0.08 : 0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: FxIcon(
                          name: icon,
                          size: 17,
                          color: iconAccent,
                          strokeWidth: 1.9,
                        ),
                      ),
                    ),
                    if (locked)
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? EagleTokens.cardSurfaceDark
                                    : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: mute.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Icon(
                            Icons.lock_rounded,
                            size: 10,
                            color: mute.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: dashboardCardTitleStyle(labelColor).copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                          maxLines: locked ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (locked && tierLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            tierLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: dashboardChipLabelStyle(
                              iconAccent.withValues(alpha: 0.95),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  locked
                      ? Icons.lock_outline_rounded
                      : Icons.chevron_right_rounded,
                  size: locked ? 15 : 18,
                  color: mute.withValues(alpha: locked ? 0.7 : 0.55),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
