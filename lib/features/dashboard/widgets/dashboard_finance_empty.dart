import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_readability.dart';

/// Empty de receita no hero financeiro — CTA sólido, sem grid, sem ghost.
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
    final label = ctaLabel?.trim().isNotEmpty == true
        ? ctaLabel!
        : DashboardMicrocopy.abrirFinanceiro;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Receita · $mes', style: dashboardHeroEyebrowOnTeal()),
        const SizedBox(height: 6),
        Text(
          'Sem receita em $mes. Abra o financeiro para lançar cobranças.',
          style: dashboardHeroCaptionOnTealStyle(),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: Colors.white.withValues(alpha: 0.42),
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.85),
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TokensStrip.rButton),
              ),
            ),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}
