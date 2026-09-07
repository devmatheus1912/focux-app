import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../ferramentas/providers/ferramentas_catalogo_provider.dart';
import '../../planos/data/planos_repository.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_shortcut_navigation.dart';
import '../utils/dashboard_tool_groups.dart';
import 'dashboard_tool_shortcut_group.dart';

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
    final maxHeight =
        MediaQuery.sizeOf(context).height *
        FxHomeSheetChrome.expandHeightFactor;
    final catalogoAsync = widget.parentRef.watch(ferramentasCatalogoProvider);

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
            child: catalogoAsync.when(
              loading: () => const SkeletonList(count: 6),
              error:
                  (e, _) => ListView(
                    padding: const EdgeInsets.only(bottom: TokensStrip.s4),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Column(
                          children: [
                            Text(
                              'Catálogo offline',
                              textAlign: TextAlign.center,
                              style: FocuxHubTypography.body(
                                color: chrome.ink,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: TokensStrip.s2),
                            Text(
                              'Toque para tentar de novo.',
                              textAlign: TextAlign.center,
                              style: FocuxHubTypography.bodyMuted(
                                color: chrome.mute,
                              ),
                            ),
                            const SizedBox(height: TokensStrip.s3),
                            TextButton.icon(
                              onPressed:
                                  () => widget.parentRef.invalidate(
                                    ferramentasCatalogoProvider,
                                  ),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              data: (catalogo) {
                final groups = groupCatalogoHubs(
                  catalogo,
                  query: _searchQuery,
                );
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
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: TokensStrip.s4),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final tile = DashboardToolShortcutGroup(
                      header: group.collapsed ? null : group.title,
                      shortcuts: group.shortcuts,
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
                    );
                    if (!group.collapsed) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              index < groups.length - 1
                                  ? FxSettingsLayout.groupGap
                                  : 0,
                        ),
                        child: tile,
                      );
                    }
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom:
                            index < groups.length - 1
                                ? FxSettingsLayout.groupGap
                                : 0,
                      ),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: _searchQuery.trim().isNotEmpty,
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: EdgeInsets.zero,
                          title: Text(
                            group.title,
                            style: FocuxHubTypography.body(
                              color: chrome.ink,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          subtitle:
                              group.subtitulo == null
                                  ? null
                                  : Text(
                                    group.subtitulo!,
                                    style: FocuxHubTypography.bodyMuted(
                                      color: chrome.mute,
                                    ),
                                  ),
                          children: [tile],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
