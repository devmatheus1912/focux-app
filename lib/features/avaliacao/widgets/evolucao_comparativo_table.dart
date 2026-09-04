import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/avaliacao_repository.dart';
import '../utils/evolucao_comparativo_display.dart';

class EvolucaoComparativoTable extends StatelessWidget {
  const EvolucaoComparativoTable({
    super.key,
    required this.primeira,
    required this.atual,
  });

  final SnapshotAvaliacao primeira;
  final SnapshotAvaliacao atual;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Container(
      decoration: fxListCardDecoration(
        context,
        radius: FxSettingsLayout.groupRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _headerRow(chrome),
          for (final row in evolucaoComparativoMetricas(
            primeira: primeira,
            atual: atual,
          ))
            _metricaRow(
              context,
              chrome,
              label: row.label,
              unidade: row.unidade,
              vPrimeira: row.primeira,
              vAtual: row.atual,
              menorEMelhor: row.menorEMelhor,
            ),
        ],
      ),
    );
  }

  Widget _headerRow(ShellPalette chrome) {
    final style = FocuxHubTypography.bodyMuted(
      color: chrome.mute,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Métrica', style: style)),
          Expanded(
            flex: 2,
            child: Text('Primeira', style: style, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text('Atual', style: style, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text('Delta', style: style, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _metricaRow(
    BuildContext context,
    ShellPalette chrome, {
    required String label,
    required String unidade,
    required double? vPrimeira,
    required double? vAtual,
    required bool menorEMelhor,
  }) {
    final delta = evolucaoComparativoDelta(
      primeira: vPrimeira,
      atual: vAtual,
      menorEMelhor: menorEMelhor,
    );
    final deltaColor = switch (delta.tone) {
      EvolucaoComparativoDeltaTone.better => EagleTokens.good,
      EvolucaoComparativoDeltaTone.worse => EagleTokens.bad,
      EvolucaoComparativoDeltaTone.same ||
      EvolucaoComparativoDeltaTone.missing => chrome.mute,
    };
    final ink = Theme.of(context).colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: chrome.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: FocuxHubTypography.bodyMuted(color: ink),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              evolucaoComparativoFmtValor(vPrimeira, unidade),
              textAlign: TextAlign.center,
              style: FocuxHubTypography.bodyMuted(color: ink),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              evolucaoComparativoFmtValor(vAtual, unidade),
              textAlign: TextAlign.center,
              style: FocuxHubTypography.bodyMuted(color: ink),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (delta.hasIcon) ...[
                  FxIcon(name: 'trend', size: 14, color: deltaColor),
                  const SizedBox(width: TokensStrip.s1),
                ],
                Text(
                  delta.text,
                  style: FocuxHubTypography.bodyMuted(
                    color: deltaColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
