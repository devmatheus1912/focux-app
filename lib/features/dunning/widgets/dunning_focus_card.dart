import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../data/dunning_repository.dart';
import '../utils/dunning_ops_display.dart';

class DunningFocusCard extends StatelessWidget {
  const DunningFocusCard({
    super.key,
    required this.snap,
    required this.firstFalha,
    required this.isDark,
    required this.onMarcar,
    required this.onFinanceiro,
    this.onChat,
    this.onCobrar,
    this.onAssinatura,
  });

  final DunningSnapshot snap;
  final DunningFalha? firstFalha;
  final bool isDark;
  final VoidCallback onMarcar;
  final VoidCallback onFinanceiro;
  final VoidCallback? onChat;
  final VoidCallback? onCobrar;
  final VoidCallback? onAssinatura;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final abertas = snap.abertas;
    return FxStripCard(
      emphasize: true,
      semanticsLabel: '$abertas falhas em aberto',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Em aberto', style: FocuxHubTypography.chip(chrome.mute)),
          const SizedBox(height: 6),
          Text(
            '$abertas',
            style: FocuxHubTypography.kpi(
              color: chrome.ink,
              fontSize: FocuxHubTypography.metricLg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            abertas == 0
                ? 'Nenhuma falha em aberto'
                : 'Taxa ${dunningRateLabel(snap.recoveryRate)}',
            style: FocuxHubTypography.body(
              color: chrome.ink,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: TokensStrip.s3),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: _focusChips(context),
          ),
        ],
      ),
    );
  }

  List<Widget> _focusChips(BuildContext context) {
    final falha = firstFalha;
    if (falha == null) {
      return [
        DashboardHomeActionChip(
          label: 'Ver financeiro',
          accent: Theme.of(context).colorScheme.primary,
          isDark: isDark,
          onPressed: onFinanceiro,
        ),
      ];
    }
    return [
      if (onChat != null && dunningHasAluno(falha.alunoId))
        DashboardHomeActionChip(
          label: 'Escrever',
          accent: Theme.of(context).colorScheme.primary,
          isDark: isDark,
          onPressed: onChat!,
        ),
      if (onCobrar != null && dunningHasAluno(falha.alunoId))
        DashboardHomeActionChip(
          label: 'Cobrar',
          accent: EagleTokens.moneyGreen,
          isDark: isDark,
          onPressed: onCobrar!,
        ),
      if (onAssinatura != null)
        DashboardHomeActionChip(
          label: 'Assinatura',
          accent: Theme.of(context).colorScheme.primary,
          isDark: isDark,
          onPressed: onAssinatura!,
        ),
      DashboardHomeActionChip(
        label: 'Marcar primeira',
        accent: EagleTokens.bad,
        isDark: isDark,
        onPressed: onMarcar,
      ),
    ];
  }
}
