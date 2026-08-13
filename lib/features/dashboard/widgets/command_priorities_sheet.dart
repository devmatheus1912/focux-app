import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/command_action_item.dart';
import '../utils/dashboard_haptic.dart';
import '../utils/dashboard_readability.dart';
import '../../../core/theme/focux_hub_typography.dart';
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
    Navigator.of(widget.sheetContext).pop();
    widget.parentContext.go(item.route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primary = widget.primary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final mute = dashboardReadableCaption(widget.sheetContext, isDark: isDark);
    final heading = BrandPalette.sectionHeading(primary, dark: isDark);
    final link = BrandPalette.sectionLink(primary, dark: isDark);
    final impactActions =
        widget.actions.where((action) => !action.isRadarStudent).toList();
    final radarActions =
        widget.actions.where((action) => action.isRadarStudent).toList();
    final media = MediaQuery.of(widget.sheetContext);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        0,
        14,
        math.max(12, media.viewPadding.bottom + 10),
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.72),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: fxStripCardDecoration(
          widget.sheetContext,
          radius: 28,
          glowStrength: isDark ? 0.10 : 0.16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: line.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: BrandPalette.soft(primary, dark: isDark),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: FxIcon(name: 'route', size: 18, color: primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        impactActions.isEmpty && radarActions.isNotEmpty
                            ? 'Ações por aluno'
                            : 'Todas as prioridades',
                        style: TokensStrip.h2(
                          color: primary,
                          fontFamily:
                              Theme.of(
                                widget.sheetContext,
                              ).textTheme.bodyLarge?.fontFamily,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        impactActions.isEmpty && radarActions.isNotEmpty
                            ? 'Contato e retenção dos alunos em risco.'
                            : 'Extra além do que já está na Home.',
                        style: TokensStrip.bodyMuted(
                          color: mute,
                          fontFamily:
                              Theme.of(
                                widget.sheetContext,
                              ).textTheme.bodyLarge?.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(widget.sheetContext).pop(),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, size: 18, color: mute),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                children: [
                  for (
                    var index = 0;
                    index < impactActions.length;
                    index++
                  ) ...[
                    if (index > 0) const SizedBox(height: 8),
                    CommandActionTile(
                      item: impactActions[index],
                      isDark: isDark,
                      primary: primary,
                      entranceIndex: index,
                      onTap: () => _openAction(impactActions[index]),
                    ),
                  ],
                  if (radarActions.isNotEmpty) ...[
                    if (impactActions.isNotEmpty) ...[
                      const SizedBox(height: 12),
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
                          borderRadius:
                              BorderRadius.circular(TokensStrip.rInput),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
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
                      if (impactActions.isNotEmpty) const SizedBox(height: 8),
                      for (
                        var index = 0;
                        index < radarActions.length;
                        index++
                      ) ...[
                        if (index > 0) const SizedBox(height: 8),
                        CommandActionTile(
                          item: radarActions[index],
                          isDark: isDark,
                          primary: primary,
                          onTap: () => _openAction(radarActions[index]),
                        ),
                      ],
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
