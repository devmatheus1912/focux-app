import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../utils/agenda_schedule.dart';

class AgendaDayEmptyPanel extends StatelessWidget {
  const AgendaDayEmptyPanel({
    super.key,
    required this.dayLabel,
    required this.onNew,
  });

  final String dayLabel;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final hint = agendaEmptyDayHint();

    return Semantics(
      container: true,
      label: '$dayLabel. Dia livre. $hint',
      child: FxSettingsGroup(
        header: dayLabel,
        children: [
          FxSettingsTile(
            fxIcon: 'calendar',
            label: 'Dia livre',
            subtitle: hint,
            value: 'Novo',
            showDivider: false,
            onTap: () {
              HapticFeedback.lightImpact();
              onNew();
            },
          ),
        ],
      ),
    );
  }
}
