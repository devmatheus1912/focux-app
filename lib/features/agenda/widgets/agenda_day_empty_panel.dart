import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/fx_empty_state.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(title: dayLabel),
          FxEmptyState(
            icon: 'calendar',
            title: 'Dia livre',
            subtitle: hint,
            action: FxEmptyAction(
              label: 'Novo',
              onTap: () {
                HapticFeedback.lightImpact();
                onNew();
              },
            ),
          ),
        ],
      ),
    );
  }
}
