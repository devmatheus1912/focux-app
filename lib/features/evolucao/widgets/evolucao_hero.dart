import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../l10n/pt.dart';
import '../data/evolucao_repository.dart';
import '../utils/evolucao_series.dart';

/// Topo das abas de evolução: o peso atual e quanto mudou.
class EvolucaoHero extends StatelessWidget {
  const EvolucaoHero({super.key, required this.medidas});

  final List<MedidaCorporal> medidas;

  @override
  Widget build(BuildContext context) {
    final sobre = fxPaletaSobreMarca(context);
    final pesos = serieDaMetrica(medidas, EvolucaoMetrica.peso);
    final variacao = variacaoDoPeso(pesos);
    return FxStripCard(
      marca: true,
      padding: const EdgeInsets.all(TokensStrip.s3),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ptS.evolucaoPesoAtual, style: FocuxHubTypography.chip(sobre.mute)),
            const SizedBox(height: TokensStrip.s1),
            Text(
              pesos.isEmpty ? '—' : formatBrKg(pesos.last.valor),
              style: FocuxHubTypography.metric(
                color: sobre.ink,
                fontSize: 34,
                height: 1.1,
              ),
            ),
            if (variacao != null) ...[
              const SizedBox(height: TokensStrip.s1),
              Text(
                [
                  if (variacao.texto.isNotEmpty) variacao.texto,
                  ptS.evolucaoUltimaEm(variacao.data ?? ''),
                ].join(' · '),
                style: FocuxHubTypography.bodyMuted(color: sobre.mute),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
