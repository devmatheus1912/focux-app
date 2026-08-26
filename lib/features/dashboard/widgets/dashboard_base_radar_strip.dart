import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../constants/dashboard_layout.dart';
import '../data/command_center_data.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_radar_items.dart';
import '../utils/dashboard_readability.dart';
import 'dashboard_radar_sheet.dart';

/// Radar da base — no máximo 2 no fold; cadastro não entra.
class DashboardBaseRadarStrip extends StatelessWidget {
  const DashboardBaseRadarStrip({super.key, required this.scores});

  final List<AlunoScoreResumo> scores;

  @override
  Widget build(BuildContext context) {
    final split = dashboardRadarSplit(scores);
    if (split.fold.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = dashboardReadableCaption(context, isDark: isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final link = BrandPalette.sectionLink(primary, dark: isDark);

    return Padding(
      padding: DashboardLayout.foldCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DashboardMicrocopy.radarDaBase,
                  style: FxSettingsLayout.sectionHeader(color: mute),
                ),
              ),
              if (split.hasMore)
                Semantics(
                  button: true,
                  label: DashboardMicrocopy.radarVerTodos,
                  child: TextButton(
                    onPressed: () => showDashboardRadarSheet(
                      context,
                      items: split.pool,
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      foregroundColor: link,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(DashboardMicrocopy.radarVerTodos),
                  ),
                ),
            ],
          ),
          const SizedBox(height: FxSettingsLayout.headerToGroup),
          FxSettingsGroup(
            caption: dashboardRadarCaption(
              fold: split.fold.length,
              total: split.total,
            ),
            children: [
              for (var i = 0; i < split.fold.length; i++)
                DashboardRadarTile(
                  item: split.fold[i],
                  index: i,
                  total: split.total,
                  showDivider: i < split.fold.length - 1,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
