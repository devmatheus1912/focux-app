import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../planos/utils/effective_plano_features.dart';
import '../data/dashboard_tool_shortcuts.dart';
import '../utils/dashboard_a11y.dart';
import '../utils/dashboard_haptic.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_readability.dart';
import '../utils/dashboard_screen_helpers.dart';
import '../utils/dashboard_shortcut_navigation.dart';
import '../utils/dashboard_tool_groups.dart';
import '../utils/dashboard_tool_recent_store.dart';
import 'dashboard_roi_quick_links.dart';
import 'dashboard_tool_grid.dart';

export 'dashboard_roi_quick_links.dart';
export 'dashboard_tool_grid.dart';

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
    final totalTools = DashboardToolShortcut.moreTools.length;
    final lockedCount = countLockedShortcuts(
      DashboardToolShortcut.moreTools,
      features,
    );
    final unlockedCount = totalTools - lockedCount;
    final collapsedHint =
        lockedCount > 0
            ? '$unlockedCount liberados · $lockedCount no upgrade'
            : '$totalTools atalhos · toque para expandir';

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
                DashboardMicrocopy.maisFerramentas,
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
                              DashboardMicrocopy.maisFerramentas,
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
                    if (_recentShortcuts.isNotEmpty &&
                        _searchQuery.isEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        DashboardMicrocopy.recentes,
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
                              DashboardRoiShortcutChip(
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
                      label: DashboardMicrocopy.buscarFerramenta,
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
                          hintText: DashboardMicrocopy.buscarFerramenta,
                          hintStyle: TextStyle(color: mute),
                          prefixIcon: Icon(Icons.search_rounded, color: mute),
                          isDense: true,
                          filled: true,
                          fillColor:
                              widget.isDark
                                  ? EagleTokens.darkCard
                                  : Colors.white,
                          border: FxInputDeco.outlineBorder(
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
                            (shortcut) =>
                                openDashboardShortcut(context, ref, shortcut),
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
