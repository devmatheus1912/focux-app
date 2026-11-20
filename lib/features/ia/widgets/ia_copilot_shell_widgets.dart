import 'package:flutter/material.dart';
import '../../../core/widgets/fx_tonal_button.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/chao_da_marca.dart';

/// Chip sticky S1 após gerar — paridade [DashboardPrioritiesOverlay].
/// Overlay flutuante (não barra `bottomNavigationBar` / S3–S5).
/// O pai posiciona no Stack; scroll reserva folga para não cobrir Insights.
/// Rodapé do resultado: "Concluir" sempre e, à direita, a próxima ação que
/// falta. Sem pendente, só "Concluir" (como botão principal).
class IaCopilotResultActionBar extends StatelessWidget {
  const IaCopilotResultActionBar({
    super.key,
    required this.onConcluir,
    this.proximaLabel,
    this.onProxima,
  });

  final VoidCallback onConcluir;
  final String? proximaLabel;
  final VoidCallback? onProxima;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final proxima = onProxima;
    return Material(
      color: isDark ? context.tons.chao : TokensStrip.pageBg,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          TokensStrip.s4,
          TokensStrip.s2,
          TokensStrip.s4,
          TokensStrip.s2 + MediaQuery.paddingOf(context).bottom,
        ),
        child:
            proxima == null
                ? FxLiquidPrimaryButton(label: 'Concluir', onPressed: onConcluir)
                : Row(
                  children: [
                    Expanded(
                      child: FxTonalButton(
                        label: 'Concluir',
                        expanded: true,
                        onPressed: onConcluir,
                      ),
                    ),
                    const SizedBox(width: TokensStrip.s2),
                    Expanded(
                      flex: 2,
                      child: FxLiquidPrimaryButton(
                        label: proximaLabel ?? '',
                        onPressed: proxima,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class IaCopilotGenerationStatus extends StatelessWidget {
  const IaCopilotGenerationStatus({
    super.key,
    required this.gerando,
    required this.gerado,
    required this.elapsedMs,
    required this.ink,
    required this.mute,
    required this.wash,
  });

  final bool gerando;
  final bool gerado;
  final int elapsedMs;
  final Color ink;
  final Color mute;
  final Color wash;

  @override
  Widget build(BuildContext context) {
    final elapsed =
        elapsedMs >= 1000
            ? '${formatBrDecimal(elapsedMs / 1000)}s'
            : '${elapsedMs}ms';

    // Pós-gerar: linha compacta — não empurra Insights abaixo do fold (§9 S1 / pilar 13).
    if (gerado && !gerando) {
      return Row(
        children: [
          const Icon(
            FxIcons.concluido,
            color: EagleTokens.copilotSuccess,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pronto para revisão',
              style: TextStyle(
                color: ink,
                fontSize: TokensStrip.fontRotulo,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (elapsedMs > 0)
            Text(
              elapsed,
              style: TextStyle(
                color: mute,
                fontSize: TokensStrip.fontMinimo,
                fontFamily: 'monospace',
              ),
            ),
        ],
      );
    }

    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context, accent: primary, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: EagleTokens.copilotSuccess,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gerando recomendações...',
                  style: TextStyle(
                    color: ink,
                    fontSize: TokensStrip.fontRotulo,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              backgroundColor: wash,
              valueColor: const AlwaysStoppedAnimation(
                EagleTokens.copilotSuccess,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
