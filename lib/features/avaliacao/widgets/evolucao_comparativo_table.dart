import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
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
          _metricaRow(
            context,
            chrome,
            label: 'Peso',
            unidade: 'kg',
            vPrimeira: primeira.pesoKg,
            vAtual: atual.pesoKg,
            menorEMelhor: true,
          ),
          _metricaRow(
            context,
            chrome,
            label: 'IMC',
            unidade: '',
            vPrimeira: primeira.imc,
            vAtual: atual.imc,
            menorEMelhor: true,
          ),
          _metricaRow(
            context,
            chrome,
            label: '% Gordura',
            unidade: '%',
            vPrimeira: primeira.percGordura,
            vAtual: atual.percGordura,
            menorEMelhor: true,
          ),
          _metricaRow(
            context,
            chrome,
            label: 'Massa Muscular',
            unidade: 'kg',
            vPrimeira: primeira.massaMuscular,
            vAtual: atual.massaMuscular,
            menorEMelhor: false,
          ),
          _metricaRow(
            context,
            chrome,
            label: 'Circ. Cintura',
            unidade: 'cm',
            vPrimeira: primeira.circCintura,
            vAtual: atual.circCintura,
            menorEMelhor: true,
          ),
          _metricaRow(
            context,
            chrome,
            label: 'Circ. Quadril',
            unidade: 'cm',
            vPrimeira: primeira.circQuadril,
            vAtual: atual.circQuadril,
            menorEMelhor: true,
          ),
          _metricaRow(
            context,
            chrome,
            label: 'Circ. Braço',
            unidade: 'cm',
            vPrimeira: primeira.circBraco,
            vAtual: atual.circBraco,
            menorEMelhor: false,
          ),
          _metricaRow(
            context,
            chrome,
            label: 'Circ. Coxa',
            unidade: 'cm',
            vPrimeira: primeira.circCoxa,
            vAtual: atual.circCoxa,
            menorEMelhor: false,
          ),
        ],
      ),
    );
  }

  Widget _headerRow(ShellPalette chrome) {
    final style = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 13,
      color: chrome.mute,
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
                  Icon(
                    delta.improved
                        ? Icons.trending_up
                        : Icons.trending_down,
                    size: 14,
                    color: deltaColor,
                  ),
                  const SizedBox(width: 2),
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
