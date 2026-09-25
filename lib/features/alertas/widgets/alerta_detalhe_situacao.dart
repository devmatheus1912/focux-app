import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../utils/alerta_detalhe_display.dart';

class AlertaDetalheSituacao extends StatelessWidget {
  const AlertaDetalheSituacao({
    super.key,
    required this.alunoId,
    required this.motivos,
    required this.statusFinanceiro,
    required this.resolving,
    required this.isDark,
    required this.primary,
    required this.onAdiar,
  });

  final int alunoId;
  final List<String> motivos;
  final String statusFinanceiro;
  final bool resolving;
  final bool isDark;
  final Color primary;
  final VoidCallback onAdiar;

  @override
  Widget build(BuildContext context) {
    final visiveis = alertaMotivosVisiveis(motivos);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (visiveis.isEmpty)
          Text(
            alertaMotivosEmpty(),
            style: FocuxHubTypography.bodyMuted(
              color: fxScreenMute(context),
              fontWeight: FontWeight.w600,
            ),
          )
        else
          for (final motivo in visiveis)
            FxSatelliteListTile(
              title: motivo,
              titleCase: false,
            ),
        const SizedBox(height: TokensStrip.s4),
        Wrap(
          spacing: TokensStrip.s2,
          runSpacing: TokensStrip.s2,
          children: [
            if (alertaStatusFinanceiroRuim(statusFinanceiro))
              FxActionChip(
                label: 'Cobrar',
                accent: EagleTokens.bad,
                isDark: isDark,
                onPressed: () => context.push(
                  '/financeiro?alunoId=$alunoId',
                ),
              ),
            FxActionChip(
              label: alertaAdiarCtaLabel(),
              accent: primary,
              isDark: isDark,
              enabled: !resolving,
              onPressed: onAdiar,
            ),
          ],
        ),
      ],
    );
  }
}
