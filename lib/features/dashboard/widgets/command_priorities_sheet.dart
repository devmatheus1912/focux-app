import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../data/command_action_item.dart';
import '../utils/dashboard_haptic.dart';
import '../utils/dashboard_readability.dart';
import 'command_action_tile.dart';

class CommandPrioritiesSheet extends StatefulWidget {
  const CommandPrioritiesSheet({
    super.key,
    required this.parentContext,
    required this.sheetContext,
    required this.isDark,
    required this.primary,
    required this.actions,
  });

  final BuildContext parentContext;
  final BuildContext sheetContext;
  final bool isDark;
  final Color primary;
  final List<CommandActionItem> actions;

  @override
  State<CommandPrioritiesSheet> createState() => _CommandPrioritiesSheetState();
}

class _CommandPrioritiesSheetState extends State<CommandPrioritiesSheet> {
  late bool _radarExpanded;

  @override
  void initState() {
    super.initState();
    final radarCount =
        widget.actions.where((action) => action.isRadarStudent).length;
    final impactOnly = widget.actions.where((a) => !a.isRadarStudent).isEmpty;
    _radarExpanded = radarCount <= 2 || impactOnly;
  }

  void _openAction(CommandActionItem item) {
    AnalyticsService.instance.track(
      ProductEvents.homeDayFocusAction,
      props: {
        'route': item.route,
        'title': item.title,
        'priority': item.priorityBadge,
        'source': 'priorities_sheet',
      },
    );
    Navigator.of(widget.sheetContext).pop();
    widget.parentContext.go(item.route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primary = widget.primary;
    final heading = BrandPalette.sectionHeading(primary, dark: isDark);
    final link = BrandPalette.sectionLink(primary, dark: isDark);
    final impactActions =
        widget.actions.where((action) => !action.isRadarStudent).toList();
    final radarActions =
        widget.actions.where((action) => action.isRadarStudent).toList();
    final title =
        impactActions.isEmpty && radarActions.isNotEmpty
            ? 'Quem atender agora'
            : 'Prioridades';
    final subtitle =
        impactActions.isEmpty && radarActions.isNotEmpty
            ? 'Um toque abre o aluno. Ordem = urgência.'
            : 'Impacto primeiro · depois contato por aluno.';

    final sheetHeight = MediaQuery.sizeOf(widget.sheetContext).height;
    final itemEstimate =
        (impactActions.length +
                (radarActions.isEmpty ? 0 : radarActions.length + 1)) *
            64.0 +
        28;
    final listMaxHeight = (sheetHeight * FxHomeSheetChrome.maxHeightFactor - 108)
        .clamp(96.0, sheetHeight * 0.55);

    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight: sheetHeight * FxHomeSheetChrome.maxHeightFactor,
      expand: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          SizedBox(height: TokensStrip.s2),
          FxHomeSheetHeader(
            isDark: isDark,
            title: title,
            subtitle: subtitle,
            leading: FxIcon(name: 'route', size: 18, color: primary),
          ),
          SizedBox(height: TokensStrip.s2),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: itemEstimate.clamp(96.0, listMaxHeight),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              children: [
                if (impactActions.isNotEmpty)
                  FxSettingsGroup(
                    accent: primary,
                    children: [
                      for (var index = 0; index < impactActions.length; index++)
                        CommandActionTile(
                          item: impactActions[index],
                          isDark: isDark,
                          primary: primary,
                          showDivider: index < impactActions.length - 1,
                          onTap: () => _openAction(impactActions[index]),
                        ),
                    ],
                  ),
                if (radarActions.isNotEmpty) ...[
                  if (impactActions.isNotEmpty) ...[
                    SizedBox(height: TokensStrip.s3),
                    Semantics(
                      button: true,
                      expanded: _radarExpanded,
                      label:
                          'Ações por aluno, ${radarActions.length} itens. '
                          '${_radarExpanded ? 'Expandido' : 'Recolhido'}',
                      child: InkWell(
                        onTap: () {
                          dashboardHapticCollapseToggle();
                          setState(() => _radarExpanded = !_radarExpanded);
                        },
                        borderRadius: BorderRadius.circular(TokensStrip.rInput),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: TokensStrip.s1,
                            vertical: TokensStrip.s2,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Ações por aluno (${radarActions.length})',
                                  style: FocuxHubTypography.eyebrow(
                                    context,
                                    color: heading,
                                  ),
                                ),
                              ),
                              Icon(
                                _radarExpanded
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                size: 22,
                                color: link,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (_radarExpanded || impactActions.isEmpty) ...[
                    if (impactActions.isNotEmpty)
                      SizedBox(height: TokensStrip.s2),
                    FxSettingsGroup(
                      accent: primary,
                      children: [
                        for (
                          var index = 0;
                          index < radarActions.length;
                          index++
                        )
                          CommandActionTile(
                            item: radarActions[index],
                            isDark: isDark,
                            primary: primary,
                            showDivider: index < radarActions.length - 1,
                            onTap: () => _openAction(radarActions[index]),
                          ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
