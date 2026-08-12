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
import '../utils/dashboard_shortcut_navigation.dart';
import '../utils/dashboard_tool_groups.dart';
import 'dashboard_tool_grid.dart';

export 'dashboard_tool_grid.dart';

class DashboardCollapsibleToolsSection extends ConsumerStatefulWidget {
  const DashboardCollapsibleToolsSection({
    super.key,
    required this.isDark,
    required this.shortcutAspectRatio,
    this.hideFeaturedTools = false,
  });

  final bool isDark;
  final double shortcutAspectRatio;
  /// Modo foco: só header + expand abre o catálogo (sem grid featured).
  final bool hideFeaturedTools;

  @override
  ConsumerState<DashboardCollapsibleToolsSection> createState() =>
      DashboardCollapsibleToolsSectionState();
}

class DashboardCollapsibleToolsSectionState
    extends ConsumerState<DashboardCollapsibleToolsSection> {
  bool _expanded = false;
  String _searchQuery = '';

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
    final featuredShortcuts = DashboardToolShortcut.featuredTools;
    final featuredCount = featuredShortcuts.length;
    final hideFeatured = widget.hideFeaturedTools;
    final collapsedHint =
        hideFeatured
            ? (lockedCount > 0
                ? '$totalTools no catálogo · $lockedCount no upgrade'
                : '$totalTools atalhos · toque para abrir')
            : lockedCount > 0
            ? '$featuredCount em destaque · $lockedCount no upgrade'
            : '$featuredCount em destaque · $totalTools no catálogo';
    final expandedHint =
        lockedCount > 0
            ? '$unlockedCount liberados · busca e grupos'
            : '$totalTools atalhos · busca e grupos';

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
                  setState(() => _expanded = !_expanded);
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
                              _expanded ? expandedHint : collapsedHint,
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
            firstChild:
                hideFeatured
                    ? const SizedBox.shrink()
                    : Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardShortcutGrid(
                    shortcuts: featuredShortcuts,
                    isDark: widget.isDark,
                    aspectRatio: widget.shortcutAspectRatio,
                    onShortcut:
                        (shortcut) =>
                            openDashboardShortcut(context, ref, shortcut),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: Colors.transparent,
                      child: Semantics(
                        button: true,
                        label: DashboardMicrocopy.verCatalogoCompleto,
                        child: InkWell(
                          onTap: () {
                            dashboardHapticCollapseToggle();
                            setState(() => _expanded = true);
                          },
                          borderRadius: BorderRadius.circular(
                            TokensStrip.rInput,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DashboardMicrocopy.verCatalogoCompleto,
                                  style: AppTypography.inter(
                                    fontSize: TokensStrip.fontBodySm,
                                    fontWeight: FontWeight.w800,
                                    color: link,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: link,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            secondChild: SafeArea(
              top: true,
              bottom: false,
              minimum: const EdgeInsets.only(top: 4),
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
