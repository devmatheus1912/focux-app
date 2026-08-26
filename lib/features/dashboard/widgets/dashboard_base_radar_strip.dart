import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../constants/dashboard_layout.dart';
import '../data/command_center_data.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_radar_items.dart';

/// Radar da base — grupo inset (Perfil), top-N do BFF, sem accordion/KPI.
class DashboardBaseRadarStrip extends StatelessWidget {
  const DashboardBaseRadarStrip({super.key, required this.scores, this.limit});

  final List<AlunoScoreResumo> scores;
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final take = limit ?? DashboardLayout.radarCardLimit(context);
    final items = dashboardRadarItems(scores, limit: take);
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: DashboardLayout.foldCard,
      child: FxSettingsGroup(
        header: DashboardMicrocopy.radarDaBase,
        caption: dashboardRadarCaption(items.length),
        children: [
          for (var i = 0; i < items.length; i++)
            _RadarTile(
              item: items[i],
              index: i,
              total: items.length,
              showDivider: i < items.length - 1,
            ),
        ],
      ),
    );
  }
}

class _RadarTile extends StatelessWidget {
  const _RadarTile({
    required this.item,
    required this.index,
    required this.total,
    required this.showDivider,
  });

  final AlunoScoreResumo item;
  final int index;
  final int total;
  final bool showDivider;

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
          AnalyticsService.instance.track(
            ProductEvents.homeRadarTap,
            props: {
              'alunoId': item.alunoId,
              'score': item.score,
              'prioridade': item.prioridade,
            },
          );
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
