import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/fx_motion.dart';
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
        footer: Semantics(
          button: true,
          label: 'Novo agendamento',
          child: FxLiquidPrimaryButton(
            label: 'Novo agendamento',
            onPressed: () {
              HapticFeedback.lightImpact();
              onNew();
            },
          ),
        ),
        children: [
          FxSettingsTile(
            fxIcon: 'calendar',
            label: 'Dia livre',
            subtitle: hint,
            value: '',
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
