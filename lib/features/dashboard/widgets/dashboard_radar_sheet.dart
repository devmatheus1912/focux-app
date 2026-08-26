import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../data/command_center_data.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_radar_items.dart';

Future<void> showDashboardRadarSheet(
  BuildContext parentContext, {
  required List<AlunoScoreResumo> items,
}) {
  if (items.isEmpty) return Future.value();
  return showFxHomeSheet<void>(
    parentContext,
    builder: (sheetContext) {
      final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
      final brand = Theme.of(sheetContext).colorScheme.primary;
      return FxHomeSheetSurface(
        isDark: isDark,
        maxHeight:
            MediaQuery.sizeOf(sheetContext).height *
            FxHomeSheetChrome.maxHeightFactor,
        expand: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FxHomeSheetHandle(isDark: isDark),
            SizedBox(height: FxSettingsLayout.headerToGroup),
            FxHomeSheetHeader(
              isDark: isDark,
              title: DashboardMicrocopy.radarDaBase,
              subtitle: DashboardMicrocopy.radarSheetSubtitle,
              leading: FxIcon(
                name: 'trend',
                size: FxSettingsLayout.iconSize,
                color: brand,
              ),
            ),
            SizedBox(height: FxSettingsLayout.headerToGroup),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  return DashboardRadarTile(
                    item: items[i],
                    index: i,
                    total: items.length,
                    showDivider: i < items.length - 1,
                    onOpen: () => _openAluno(
                      parent: parentContext,
                      sheet: sheetContext,
                      item: items[i],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

void _openAluno({
  required BuildContext parent,
  required BuildContext sheet,
  required AlunoScoreResumo item,
}) {
  _trackRadarTap(item);
  Navigator.of(sheet).pop();
  final url = item.acaoUrl.trim();
  parent.push(url.isNotEmpty ? url : '/alunos/${item.alunoId}');
}

void _trackRadarTap(AlunoScoreResumo item) {
  AnalyticsService.instance.track(
    ProductEvents.homeRadarTap,
    props: {
      'alunoId': item.alunoId,
      'score': item.score,
      'prioridade': item.prioridade,
    },
  );
}

class DashboardRadarTile extends StatelessWidget {
  const DashboardRadarTile({
    super.key,
    required this.item,
    required this.index,
    required this.total,
    required this.showDivider,
    this.onOpen,
  });

  final AlunoScoreResumo item;
  final int index;
  final int total;
  final bool showDivider;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final nome = fxTitleCaseName(item.alunoNome);
    final subtitle = '${item.risco} · ${item.proximaAcao}';
    final semantics =
        '$nome, score ${item.score}. $subtitle. Item ${index + 1} de $total.';

    return Tooltip(
      message: DashboardMicrocopy.scoreComoCalculamos,
      child: FxSettingsTile(
        fxIcon: dashboardRadarIcon(item.risco),
        label: nome,
        subtitle: subtitle,
        value: '${item.score}',
        numeric: true,
        showDivider: showDivider,
        semanticsLabel: semantics,
        onTap: () {
          if (onOpen != null) {
            onOpen!();
            return;
          }
          _trackRadarTap(item);
          final url = item.acaoUrl.trim();
          if (url.isNotEmpty) {
            context.push(url);
          } else {
            context.push('/alunos/${item.alunoId}');
          }
        },
      ),
    );
  }
}
