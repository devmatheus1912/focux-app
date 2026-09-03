import 'package:flutter/material.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
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
          for (final item in visible)
            Semantics(
              label:
                  '${item.horario}. ${item.nomeAluno}. '
                  'Status ${_agendaStatusLabel(item.status)}. Abrir agenda',
              button: true,
              child: FxSatelliteListTile(
                title: fxTitleCaseName(item.nomeAluno),
                subtitle: Text(_agendaStatusLabel(item.status)),
                trailing: Text(
                  item.horario,
                  style: FocuxHubTypography.bodyMuted(
                    color: fxScreenMute(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => goPersonalShellTab(context, '/agenda'),
              ),
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
