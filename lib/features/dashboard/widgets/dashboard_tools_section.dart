import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../utils/dashboard_readability.dart';
import '../../planos/utils/effective_plano_features.dart';
import '../data/dashboard_tool_shortcuts.dart';
import '../utils/dashboard_a11y.dart';
import '../utils/dashboard_haptic.dart';
import '../utils/dashboard_screen_helpers.dart';
import '../utils/dashboard_shortcut_navigation.dart';
import '../utils/dashboard_tool_groups.dart';
import '../utils/dashboard_tool_recent_store.dart';
class DashboardRoiQuickLinksRow extends ConsumerWidget {
  const DashboardRoiQuickLinksRow({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final link = BrandPalette.sectionLink(primary, dark: isDark);
    final features = effectivePlanoFeatures(ref);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        4,
        TokensStrip.s4,
        TokensStrip.s3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Retorno rápido',
            style: dashboardSectionKickerStyle(context, isDark: isDark),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final shortcut in DashboardToolShortcut.roiQuickLinks) ...[
                  _RoiShortcutChip(
                    shortcut: shortcut,
                    isDark: isDark,
                    locked: !shortcut.isUnlocked(features),
                    tierLabel:
                        shortcut.isUnlocked(features)
                            ? null
                            : shortcut.tierBadgeLabel(),
                    linkColor: link,
                    onTap:
                        () => openDashboardShortcut(context, ref, shortcut),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoiShortcutChip extends StatelessWidget {
  const _RoiShortcutChip({
    required this.shortcut,
    required this.isDark,
    required this.locked,
    required this.onTap,
    required this.linkColor,
    this.tierLabel,
  });

  final DashboardToolShortcut shortcut;
  final bool isDark;
  final bool locked;
  final String? tierLabel;
  final Color linkColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bg =
        locked
            ? BrandPalette.soft(primary, dark: isDark).withValues(alpha: 0.55)
            : BrandPalette.soft(primary, dark: isDark);
    final labelColor =
        locked ? linkColor.withValues(alpha: 0.78) : linkColor;

    return Semantics(
      button: true,
      label:
          locked
              ? '${shortcut.label}, trancado. Plano ${tierLabel ?? shortcut.tierBadgeLabel()}'
              : shortcut.label,
      child: ActionChip(
        avatar:
            locked
                ? Icon(Icons.lock_rounded, size: 14, color: labelColor)
                : null,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(shortcut.label),
            if (locked && tierLabel != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: labelColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tierLabel!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: labelColor,
                    height: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
        onPressed: onTap,
        backgroundColor: bg,
        side:
            locked
                ? BorderSide(color: labelColor.withValues(alpha: 0.22))
                : BorderSide.none,
        labelStyle: TextStyle(
          color: labelColor,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _DashboardShortcutGrid extends ConsumerWidget {
  const _DashboardShortcutGrid({
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
      return _ShortcutBtn(
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

class DashboardExpandableToolGroupsState extends ConsumerState<DashboardExpandableToolGroups> {
  late Set<String> _openGroups;

  @override
  void initState() {
    super.initState();
    _openGroups = {'Operação'};
  }

  @override
  void didUpdateWidget(covariant DashboardExpandableToolGroups oldWidget) {
    super.didUpdateWidget(oldWidget);
    final q = widget.searchQuery.trim();
    final oldQ = oldWidget.searchQuery.trim();
    if (q.isNotEmpty && q != oldQ) {
      _openGroups = widget.groups.map((g) => g.title).toSet();
    } else if (q.isEmpty && oldQ.isNotEmpty) {
      _openGroups = {'Operação'};
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
                        style: AppTypography.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: link,
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
                          style: AppTypography.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: link.withValues(alpha: 0.88),
                          ),
                        ),
                      ),
                      const Spacer(),
                      AnimatedRotation(
                        turns: _openGroups.contains(group.title) ? 0.25 : 0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: link,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_openGroups.contains(group.title))
            _DashboardShortcutGrid(
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

class DashboardCollapsibleToolsSection extends ConsumerStatefulWidget {
  const DashboardCollapsibleToolsSection({
    super.key,
    required this.isDark,
    required this.shortcutAspectRatio,
  });

  final bool isDark;
  final double shortcutAspectRatio;

  @override
  ConsumerState<DashboardCollapsibleToolsSection> createState() =>
      DashboardCollapsibleToolsSectionState();
}

class DashboardCollapsibleToolsSectionState
    extends ConsumerState<DashboardCollapsibleToolsSection> {
  bool _expanded = false;
  String _searchQuery = '';
  List<DashboardToolShortcut> _recentShortcuts = const [];

  @override
  void initState() {
    super.initState();
    _loadRecentShortcuts();
  }

  Future<void> _loadRecentShortcuts() async {
    final recents = await DashboardToolRecentStore.loadRecentShortcuts();
    if (!mounted) return;
    setState(() => _recentShortcuts = recents);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final heading = BrandPalette.sectionHeading(primary, dark: widget.isDark);
    final mute = dashboardReadableMuted(context, isDark: widget.isDark);
    final link = BrandPalette.sectionLink(primary, dark: widget.isDark);
    final features = effectivePlanoFeatures(ref);
    final shortcuts = filterDashboardToolShortcuts(
      DashboardToolShortcut.moreTools,
      _searchQuery,
    );
    final groups = groupDashboardToolShortcuts(shortcuts);
    final lockedCount = countLockedShortcuts(
      DashboardToolShortcut.moreTools,
      features,
    );
    final unlockedCount = shortcuts.length - lockedCount;
    final collapsedHint =
        lockedCount > 0
            ? '$unlockedCount liberados · $lockedCount no upgrade'
            : '${shortcuts.length} atalhos · toque para expandir';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        0,
        TokensStrip.s4,
        TokensStrip.s3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: Semantics(
              button: true,
              expanded: _expanded,
              label: dashboardCollapsibleSemanticsLabel(
                'Mais ferramentas',
                _expanded,
                collapsedHint: collapsedHint,
              ),
              child: InkWell(
              onTap: () {
                dashboardHapticCollapseToggle();
                final nextExpanded = !_expanded;
                setState(() => _expanded = nextExpanded);
                if (nextExpanded) {
                  _loadRecentShortcuts();
                }
              },
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: fxStripCardDecoration(
                  context,
                  radius: TokensStrip.rCard,
                  glowStrength: 0.08,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mais ferramentas',
                            style: AppTypography.inter(
                              fontSize: TokensStrip.fontH2,
                              fontWeight: TokensStrip.weightH2,
                              letterSpacing: TokensStrip.trackingH2,
                              color: heading,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _expanded
                                ? 'Acessos menos frequentes'
                                : collapsedHint,
                            style: AppTypography.inter(
                              fontSize: TokensStrip.fontBodySm,
                              fontWeight: FontWeight.w500,
                              color: mute,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: link,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: SafeArea(
              top: true,
              bottom: false,
              minimum: const EdgeInsets.only(top: 4),
              child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardRoiQuickLinksRow(isDark: widget.isDark),
                  if (_recentShortcuts.isNotEmpty && _searchQuery.isEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Recentes',
                      style: dashboardSectionKickerStyle(
                        context,
                        isDark: widget.isDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final shortcut in _recentShortcuts) ...[
                            _RoiShortcutChip(
                              shortcut: shortcut,
                              isDark: widget.isDark,
                              locked: !shortcut.isUnlocked(features),
                              tierLabel:
                                  shortcut.isUnlocked(features)
                                      ? null
                                      : shortcut.tierBadgeLabel(),
                              linkColor: link,
                              onTap:
                                  () => openDashboardShortcut(
                                    context,
                                    ref,
                                    shortcut,
                                  ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Semantics(
                    textField: true,
                    label: 'Buscar ferramenta',
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: AppTypography.inter(
                        fontSize: 14,
                        color:
                            widget.isDark
                                ? EagleTokens.darkInk
                                : TokensStrip.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar ferramenta…',
                        hintStyle: TextStyle(color: mute),
                        prefixIcon: Icon(Icons.search_rounded, color: mute),
                        isDense: true,
                        filled: true,
                        fillColor:
                            widget.isDark
                                ? EagleTokens.darkCard
                                : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            TokensStrip.rInput,
                          ),
                          borderSide: BorderSide(
                            color: TokensStrip.borderDefault.withValues(
                              alpha: 0.9,
                            ),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (groups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Nenhum atalho para "$_searchQuery".',
                        style: AppTypography.inter(fontSize: 13, color: mute),
                      ),
                    )
                  else
                    DashboardExpandableToolGroups(
                      groups: groups,
                      isDark: widget.isDark,
                      shortcutAspectRatio: widget.shortcutAspectRatio,
                      searchQuery: _searchQuery,
                      onShortcut:
                          (shortcut) => openDashboardShortcut(
                            context,
                            ref,
                            shortcut,
                          ),
                    ),
                ],
              ),
            ),
            ),
            crossFadeState:
                _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _ShortcutBtn extends StatelessWidget {
  final String icon;
  final String label;
  final String? semanticsLabel;
  final VoidCallback onTap;
  final bool isDark;
  final bool locked;
  final String? tierLabel;

  const _ShortcutBtn({
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
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
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
                        iconAccent.withValues(
                          alpha: isDark ? 0.20 : 0.12,
                        ),
                        iconAccent.withValues(
                          alpha: isDark ? 0.08 : 0.04,
                        ),
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
                                ? const Color(0xFF1A2228)
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.2,
                      fontWeight: FontWeight.w800,
                      color: labelColor,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (locked && tierLabel != null) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: iconAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tierLabel!,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: iconAccent.withValues(alpha: 0.95),
                          height: 1,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              locked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
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
