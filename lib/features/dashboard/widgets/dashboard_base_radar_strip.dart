import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/dashboard_layout.dart';
import '../data/command_center_data.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_radar_items.dart';
import 'dashboard_radar_sheet.dart';
import 'dashboard_section_header.dart';

/// Radar da base — no máximo 2 no fold; cadastro não entra.
class DashboardBaseRadarStrip extends StatelessWidget {
  const DashboardBaseRadarStrip({super.key, required this.scores});

  final List<AlunoScoreResumo> scores;

  @override
  Widget build(BuildContext context) {
    final split = dashboardRadarSplit(scores);
    if (split.fold.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: DashboardLayout.foldCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(
            title: DashboardMicrocopy.radarDaBase,
            actionLabel: split.hasMore ? DashboardMicrocopy.radarVerTodos : null,
            onAction: split.hasMore
                ? () => showDashboardRadarSheet(
                      context,
                      items: split.pool,
                    )
                : null,
          ),
          const SizedBox(height: FxSettingsLayout.headerToGroup),
          Text(
            dashboardRadarCaption(
              fold: split.fold.length,
              total: split.total,
            ),
            style: FocuxHubTypography.bodyMuted(
              color: fxScreenMute(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < split.fold.length; i++)
            DashboardRadarTile(
              item: split.fold[i],
              index: i,
              total: split.total,
            ),
        ],
      ),
    );
  }
}
