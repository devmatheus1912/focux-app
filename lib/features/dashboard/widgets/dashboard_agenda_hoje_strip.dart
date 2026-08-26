import 'package:flutter/material.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../constants/dashboard_layout.dart';
import '../data/command_center_data.dart';
import '../utils/dashboard_microcopy.dart';
import 'dashboard_section_header.dart';

/// Próximos compromissos de hoje — grupo inset, top 3.
class DashboardAgendaHojeStrip extends StatelessWidget {
  const DashboardAgendaHojeStrip({
    super.key,
    required this.items,
  });

  final List<AgendamentoResumo> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final visible = items.take(3).toList(growable: false);

    return Padding(
      padding: DashboardLayout.foldCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(
            title: DashboardMicrocopy.agendaHoje,
            actionLabel: DashboardMicrocopy.verAgenda,
            onAction: () => goPersonalShellTab(context, '/agenda'),
          ),
          const SizedBox(height: FxSettingsLayout.headerToGroup),
          FxSettingsGroup(
            children: [
              for (var i = 0; i < visible.length; i++)
                FxSettingsTile(
                  fxIcon: 'calendar',
                  label: fxTitleCaseName(visible[i].nomeAluno),
                  subtitle: _agendaStatusLabel(visible[i].status),
                  value: visible[i].horario,
                  numeric: true,
                  showDivider: i < visible.length - 1,
                  semanticsLabel:
                      '${visible[i].horario}. ${visible[i].nomeAluno}. '
                      'Status ${_agendaStatusLabel(visible[i].status)}. Abrir agenda',
                  onTap: () => goPersonalShellTab(context, '/agenda'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _agendaStatusLabel(String status) {
  return switch (status.trim().toUpperCase()) {
    'CONFIRMADO' => 'Confirmado',
    'PENDENTE' => 'Pendente',
    'CANCELADO' => 'Cancelado',
    'CONCLUIDO' || 'CONCLUÍDO' => 'Concluído',
    _ => fxTitleCaseName(status.replaceAll('_', ' ')),
  };
}
