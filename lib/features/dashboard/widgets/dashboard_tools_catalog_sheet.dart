import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../planos/data/planos_repository.dart';
import '../../planos/utils/effective_plano_features.dart';
import '../data/dashboard_tool_shortcuts.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_shortcut_navigation.dart';
import '../utils/dashboard_tool_groups.dart';

Future<void> showDashboardToolsCatalogSheet(
  BuildContext context, {
  required WidgetRef ref,
  required bool isDark,
  PlanoFeatures? homePlanoFeatures,
}) {
  return showFxHomeSheet<void>(
    context,
    builder:
        (sheetContext) => DashboardToolsCatalogSheet(
          parentContext: context,
          parentRef: ref,
          isDark: isDark,
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
    this.homePlanoFeatures,
  });

  final BuildContext parentContext;
  final WidgetRef parentRef;
  final bool isDark;
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
    final chrome = ShellChrome.of(context);
    final brand = BrandPalette.softened(Theme.of(context).colorScheme.primary);
    final shortcuts = filterDashboardToolShortcuts(
      DashboardToolShortcut.moreTools,
      _searchQuery,
    );
    final groups = groupDashboardToolShortcuts(shortcuts);
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
          const SizedBox(height: TokensStrip.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.apps_outlined,
                size: FxSettingsLayout.iconSize,
                color: brand,
              ),
              const SizedBox(width: FxSettingsLayout.iconGap),
              Expanded(
                child: Semantics(
                  header: true,
                  label:
                      '${DashboardMicrocopy.catalogoCompleto}. '
                      '${DashboardMicrocopy.catalogoSubtitle}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DashboardMicrocopy.catalogoCompleto,
                        style: FocuxHubTypography.sectionTitle(
                          context,
                          color: chrome.ink,
                        ),
                      ),
                      const SizedBox(height: TokensStrip.s1),
                      Text(
                        DashboardMicrocopy.catalogoSubtitle,
                        style: FocuxHubTypography.bodyMuted(
                          color: chrome.mute,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Fechar',
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  minimumSize: const Size(
                    FxHomeSheetChrome.touchTarget,
                    FxHomeSheetChrome.touchTarget,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: chrome.mute,
                ),
                icon: const Icon(Icons.close_rounded, size: 22),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: TokensStrip.s3,
              bottom: TokensStrip.s3,
            ),
            child: Semantics(
              textField: true,
              label: DashboardMicrocopy.buscarFerramenta,
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                textInputAction: TextInputAction.search,
                style: FocuxHubTypography.body(color: chrome.ink),
                decoration: InputDecoration(
                  hintText: DashboardMicrocopy.buscarFerramenta,
                  hintStyle: FocuxHubTypography.bodyMuted(color: chrome.mute),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: chrome.mute,
                    size: FxSettingsLayout.iconSize,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: chrome.cardFill,
                  border: FxInputDeco.outlineBorder(
                    borderRadius: BorderRadius.circular(TokensStrip.rInput),
                    borderSide: BorderSide(color: chrome.line),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: TokensStrip.s3,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: TokensStrip.s4),
              itemCount: groups.isEmpty ? 1 : groups.length,
              itemBuilder: (context, index) {
                if (groups.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      DashboardMicrocopy.nenhumaFerramenta,
                      textAlign: TextAlign.center,
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    ),
                  );
                }
                final group = groups[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom:
                        index < groups.length - 1
                            ? FxSettingsLayout.groupGap
                            : 0,
                  ),
                  child: _DashboardCatalogGroup(
                    group: group,
                    homePlanoFeatures: widget.homePlanoFeatures,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCatalogGroup extends ConsumerWidget {
  const _DashboardCatalogGroup({
    required this.group,
    required this.onShortcut,
    this.homePlanoFeatures,
  });

  final DashboardToolGroupSection group;
  final PlanoFeatures? homePlanoFeatures;
  final void Function(DashboardToolShortcut shortcut) onShortcut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = effectivePlanoFeatures(
      ref,
      homeOverride: homePlanoFeatures,
    );
    final chrome = ShellChrome.of(context);

    return FxSettingsGroup(
      header: group.title,
      children: [
        for (var i = 0; i < group.shortcuts.length; i++)
          FxSettingsTile(
            fxIcon: group.shortcuts[i].icon,
            label: group.shortcuts[i].label,
            value:
                group.shortcuts[i].isUnlocked(features)
                    ? ''
                    : group.shortcuts[i].tierBadgeLabel(),
            locked: !group.shortcuts[i].isUnlocked(features),
            upgradeTierLabel: group.shortcuts[i].tierBadgeLabel(),
            mute: chrome.mute,
            line: chrome.line,
            showDivider: i < group.shortcuts.length - 1,
            onTap: () => onShortcut(group.shortcuts[i]),
          ),
      ],
    );
  }
}
