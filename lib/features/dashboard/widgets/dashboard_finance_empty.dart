import 'package:flutter/material.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_readability.dart';
import 'dashboard_home_action_chip.dart';

/// Empty de receita — glass + chip da Home, sem CTA invertido.
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
    final chrome = ShellChrome.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    final label = ctaLabel?.trim().isNotEmpty == true
        ? ctaLabel!
        : DashboardMicrocopy.abrirFinanceiro;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Receita · $mes',
          style: FocuxHubTypography.bodyMuted(
            color: chrome.mute,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: TokensStrip.s2),
        Text(
          'Sem receita em $mes. Abra o financeiro para lançar cobranças.',
          style: FocuxHubTypography.bodyMuted(color: chrome.mute, height: 1.35),
        ),
        const SizedBox(height: TokensStrip.s4),
        Align(
          alignment: Alignment.centerLeft,
          child: DashboardHomeActionChip(
            label: label,
            accent: accent,
            isDark: chrome.isDark,
            onPressed: onOpen,
          ),
        ),
      ],
    );
  }
}
