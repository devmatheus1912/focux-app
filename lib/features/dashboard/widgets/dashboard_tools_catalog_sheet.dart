import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_input_deco.dart';
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
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.72 : 0.40),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.58,
          minChildSize: 0.40,
          maxChildSize: 0.96,
          snap: true,
          snapSizes: const [0.40, 0.58, 0.96],
          builder:
              (_, scrollController) => TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                builder:
                    (context, value, child) => Opacity(
                      opacity: value,
                      child: child,
                    ),
                child: DashboardToolsCatalogSheet(
                  parentContext: context,
                  parentRef: ref,
                  isDark: isDark,
                  shortcutAspectRatio: shortcutAspectRatio,
                  scrollController: scrollController,
                ),
              ),
        ),
      );
    },
  );
}

class DashboardToolsCatalogSheet extends StatefulWidget {
  const DashboardToolsCatalogSheet({
    super.key,
    required this.parentContext,
    required this.parentRef,
    required this.isDark,
    required this.shortcutAspectRatio,
    this.scrollController,
  });

  final BuildContext parentContext;
  final WidgetRef parentRef;
  final bool isDark;
  final double shortcutAspectRatio;
  final ScrollController? scrollController;

  @override
  State<DashboardToolsCatalogSheet> createState() =>
      _DashboardToolsCatalogSheetState();
}

class _DashboardToolsCatalogSheetState extends State<DashboardToolsCatalogSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final mute = dashboardReadableMuted(context, isDark: widget.isDark);
    final ink =
        widget.isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final hint = ink.withValues(alpha: widget.isDark ? 0.78 : 0.62);
    final shortcuts = filterDashboardToolShortcuts(
      DashboardToolShortcut.moreTools,
      _searchQuery,
    );
    final groups = groupDashboardToolShortcuts(shortcuts);
    final media = MediaQuery.of(context);
    final sheetColor =
        widget.isDark
            ? Color.lerp(EagleTokens.darkCard, EagleTokens.darkCardHi, 0.35)!
            : Theme.of(context).colorScheme.surface;
    final searchFill =
        widget.isDark ? EagleTokens.darkCardHi : TokensStrip.pageBg;

    return Container(
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: mute.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DashboardMicrocopy.catalogoCompleto,
                    style: FocuxHubTypography.sectionTitle(
                      context,
                      color: ink,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: mute),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                    borderRadius: BorderRadius.circular(
                      TokensStrip.rInput,
                    ),
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
              controller: widget.scrollController,
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                16 + media.viewPadding.bottom,
              ),
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
