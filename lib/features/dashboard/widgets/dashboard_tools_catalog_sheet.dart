import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../planos/data/planos_repository.dart';
import '../data/dashboard_tool_shortcuts.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_readability.dart';
import '../utils/dashboard_shortcut_navigation.dart';
import '../utils/dashboard_tool_groups.dart';
import 'dashboard_tool_grid.dart';

Future<void> showDashboardToolsCatalogSheet(
  BuildContext context, {
  required WidgetRef ref,
  required bool isDark,
  required double shortcutAspectRatio,
  PlanoFeatures? homePlanoFeatures,
}) {
  return showFxHomeSheet<void>(
    context,
    builder:
        (sheetContext) => DashboardToolsCatalogSheet(
          parentContext: context,
          parentRef: ref,
          isDark: isDark,
          shortcutAspectRatio: shortcutAspectRatio,
          homePlanoFeatures: homePlanoFeatures,
        ),
  );
}

class DashboardToolsCatalogSheet extends StatefulWidget {
  const DashboardToolsCatalogSheet({
    super.key,
    required this.parentContext,
    required this.parentRef,
    required this.isDark,
    required this.shortcutAspectRatio,
    this.homePlanoFeatures,
  });

  final BuildContext parentContext;
  final WidgetRef parentRef;
  final bool isDark;
  final double shortcutAspectRatio;
  final PlanoFeatures? homePlanoFeatures;

  @override
  State<DashboardToolsCatalogSheet> createState() =>
      _DashboardToolsCatalogSheetState();
}

class _DashboardToolsCatalogSheetState
    extends State<DashboardToolsCatalogSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final mute = dashboardReadableMuted(context, isDark: widget.isDark);
    final ink = widget.isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final hint = ink.withValues(alpha: widget.isDark ? 0.78 : 0.62);
    final shortcuts = filterDashboardToolShortcuts(
      DashboardToolShortcut.moreTools,
      _searchQuery,
    );
    final groups = groupDashboardToolShortcuts(shortcuts);
    final primary = Theme.of(context).colorScheme.primary;
    final searchFill =
        widget.isDark ? EagleTokens.darkCardHi : TokensStrip.pageBg;
    final maxHeight =
        MediaQuery.sizeOf(context).height *
        FxHomeSheetChrome.expandHeightFactor;

    return FxHomeSheetSurface(
      isDark: widget.isDark,
      maxHeight: maxHeight,
      expand: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: widget.isDark),
          SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: widget.isDark,
            title: DashboardMicrocopy.catalogoCompleto,
            subtitle: DashboardMicrocopy.buscarFerramenta,
            leading: Icon(Icons.apps_rounded, color: primary, size: 18),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Semantics(
              textField: true,
              label: DashboardMicrocopy.buscarFerramenta,
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: FocuxHubTypography.body(color: ink),
                decoration: InputDecoration(
                  hintText: DashboardMicrocopy.buscarFerramenta,
                  hintStyle: FocuxHubTypography.bodyMuted(color: hint),
                  prefixIcon: Icon(Icons.search_rounded, color: hint),
                  isDense: true,
                  filled: true,
                  fillColor: searchFill,
                  border: FxInputDeco.outlineBorder(
                    borderRadius: BorderRadius.circular(TokensStrip.rInput),
                    borderSide: BorderSide(
                      color: TokensStrip.borderDefault.withValues(
                        alpha: widget.isDark ? 0.85 : 0.9,
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
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (groups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      DashboardMicrocopy.nenhumaFerramenta,
                      style: FocuxHubTypography.bodyMuted(color: mute),
                    ),
                  )
                else
                  DashboardExpandableToolGroups(
                    groups: groups,
                    isDark: widget.isDark,
                    shortcutAspectRatio: widget.shortcutAspectRatio,
                    searchQuery: _searchQuery,
                    onShortcut: (shortcut) {
                      Navigator.of(context).pop();
                      openDashboardShortcut(
                        widget.parentContext,
                        widget.parentRef,
                        shortcut,
                        homeOverride: widget.homePlanoFeatures,
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
