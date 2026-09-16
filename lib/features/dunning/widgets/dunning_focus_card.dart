import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
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

  VoidCallback? _runner(DunningFocusActionId id) => switch (id) {
    DunningFocusActionId.chat => onChat,
    DunningFocusActionId.cobrar => onCobrar,
    DunningFocusActionId.assinatura => onAssinatura,
    DunningFocusActionId.marcar => onMarcar,
    DunningFocusActionId.financeiro => onFinanceiro,
  };

  Color _accent(BuildContext context, DunningFocusActionId id) {
    final primary = Theme.of(context).colorScheme.primary;
    return switch (id) {
      DunningFocusActionId.cobrar => EagleTokens.moneyGreen,
      DunningFocusActionId.marcar => EagleTokens.bad,
      _ => primary,
    };
  }

  Future<void> _openMais(
    BuildContext context,
    List<DunningFocusActionId> secondary,
  ) async {
    final chosen = await showFxInsetPickerSheet<DunningFocusActionId>(
      context,
      title: 'Mais ações',
      headerIcon: Icons.more_horiz_rounded,
      selected: null,
      items: [
        for (final id in secondary)
          FxInsetPickerSheetItem(
            value: id,
            label: dunningFocusActionLabel(id),
          ),
      ],
    );
    if (chosen == null) return;
    HapticFeedback.selectionClick();
    _runner(chosen)?.call();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forBrightness(context, isDark);
    final falha = firstFalha;
    final split = dunningFocusActions(
      hasFalha: falha != null,
      canChat: onChat != null && falha != null && dunningHasAluno(falha.alunoId),
      canCobrar:
          onCobrar != null && falha != null && dunningHasAluno(falha.alunoId),
      canAssinatura: onAssinatura != null,
    );
    final abertas = snap.abertas;
    final primaryRun = _runner(split.primary);

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
            children: [
              if (primaryRun != null)
                DashboardHomeActionChip(
                  label: dunningFocusActionLabel(split.primary),
                  accent: _accent(context, split.primary),
                  isDark: isDark,
                  onPressed: primaryRun,
                ),
              if (split.secondary.isNotEmpty)
                DashboardHomeActionChip(
                  label: 'Mais ações',
                  accent: chrome.mute,
                  isDark: isDark,
                  onPressed: () => _openMais(context, split.secondary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
