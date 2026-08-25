import 'package:flutter/material.dart';

import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../utils/dashboard_microcopy.dart';

/// Empty de receita — tile inset, sem chip in-card.
class DashboardFinanceEmptyState extends StatelessWidget {
  const DashboardFinanceEmptyState({
    super.key,
    required this.mes,
    required this.onOpen,
    this.ctaLabel,
  });

  final String mes;
  final VoidCallback onOpen;
  final String? ctaLabel;

  @override
  Widget build(BuildContext context) {
    final cta = ctaLabel?.trim().isNotEmpty == true
        ? ctaLabel!
        : DashboardMicrocopy.abrirFinanceiro;
    return FxSettingsGroup(
      accent: Theme.of(context).colorScheme.primary,
      children: [
        FxSettingsTile(
          fxIcon: 'dollar-sign',
          label: 'Receita · $mes',
          value: 'R\$ 0',
          onTap: onOpen,
          showDivider: false,
          semanticsLabel:
              'Receita de $mes zerada. $cta',
        ),
      ],
    );
  }
}
