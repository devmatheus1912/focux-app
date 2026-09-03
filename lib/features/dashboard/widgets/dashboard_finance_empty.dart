import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../utils/dashboard_microcopy.dart';

/// Empty de receita — métrica S1, sem chip in-card.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Recebido de $mes zerado. $cta',
      button: true,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: OperationalMetricTile(
          label: 'Recebido · $mes',
          value: 'R\$ 0',
          hint: 'Sem receita neste mês',
          color: EagleTokens.moneyGreen,
          isDark: isDark,
          emphasis: OperationalMetricEmphasis.muted,
        ),
      ),
    );
  }
}
