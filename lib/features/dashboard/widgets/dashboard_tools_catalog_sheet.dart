import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brand_palette.dart';
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
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder:
        (sheetContext) => DashboardToolsCatalogSheet(
          parentContext: context,
          parentRef: ref,
          isDark: isDark,
          shortcutAspectRatio: shortcutAspectRatio,
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
  });

  final BuildContext parentContext;
  final WidgetRef parentRef;
  final bool isDark;
  final double shortcutAspectRatio;

  @override
  State<DashboardToolsCatalogSheet> createState() =>
      _DashboardToolsCatalogSheetState();
}

class _DashboardToolsCatalogSheetState extends State<DashboardToolsCatalogSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final heading = BrandPalette.sectionHeading(primary, dark: widget.isDark);
    final mute = dashboardReadableMuted(context, isDark: widget.isDark);
    final ink =
        widget.isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final shortcuts = filterDashboardToolShortcuts(
      DashboardToolShortcut.moreTools,
      _searchQuery,
    );
    final groups = groupDashboardToolShortcuts(shortcuts);
    final media = MediaQuery.of(context);
    final sheetColor =
        widget.isDark ? EagleTokens.darkCard : Theme.of(context).colorScheme.surface;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.86),
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
                        color: heading,
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
                    hintStyle: FocuxHubTypography.bodyMuted(color: mute),
                    prefixIcon: Icon(Icons.search_rounded, color: mute),
                    isDense: true,
                    filled: true,
                    fillColor:
                        widget.isDark
                            ? EagleTokens.darkBg
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
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  16 + media.viewPadding.bottom,
                ),
                children: [
                  if (groups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Nenhum atalho para "$_searchQuery".',
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
      ),
    );
  }
}
