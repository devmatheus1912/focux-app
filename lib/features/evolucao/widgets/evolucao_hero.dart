import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_aneis_concentricos.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../l10n/pt.dart';
import '../data/evolucao_repository.dart';
import '../data/meta_corporal.dart';
import '../utils/evolucao_series.dart';

/// Topo: anéis quando há meta; peso e variação quando não há. Anel sem alvo
/// seria enfeite.
class EvolucaoHero extends StatelessWidget {
  const EvolucaoHero({
    super.key,
    required this.medidas,
    this.metas = const [],
    this.acao,
  });

  final List<MedidaCorporal> medidas;
  final List<MetaCorporal> metas;

  /// "Definir meta", só para o personal.
  final Widget? acao;

  static const _opacidades = [1.0, 0.72, 0.48];

  @override
  Widget build(BuildContext context) {
    final sobre = fxPaletaSobreMarca(context);
    final abertas = ([...metas.where((m) => m.aberta && !m.manutencao)]
          ..sort((a, b) => b.progresso.compareTo(a.progresso)))
        .take(3)
        .toList();
    final pesos = serieDaMetrica(medidas, EvolucaoMetrica.peso);
    final variacao = variacaoDoPeso(pesos);
    final peso = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ptS.evolucaoPesoAtual, style: FocuxHubTypography.chip(sobre.mute)),
        const SizedBox(height: TokensStrip.s1),
        Text(
          pesos.isEmpty ? '—' : formatBrKg(pesos.last.valor),
          style: FocuxHubTypography.metric(
            color: sobre.ink,
            fontSize: abertas.isEmpty ? 34 : FocuxHubTypography.metricLg,
            height: 1.1,
          ),
        ),
        if (variacao != null) ...[
          const SizedBox(height: TokensStrip.s1),
          Text(
            [
              if (variacao.texto.isNotEmpty) variacao.texto,
              if (abertas.isEmpty) ptS.evolucaoUltimaEm(variacao.data ?? ''),
            ].join(' · '),
            style: FocuxHubTypography.bodyMuted(color: sobre.mute),
          ),
        ],
      ],
    );
    return FxStripCard(
      marca: true,
      padding: const EdgeInsets.all(TokensStrip.s3),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (abertas.isEmpty)
              peso
            else
              Row(
                children: [
                  FxAneisConcentricos(
                    cor: sobre.ink,
                    aneis: [
                      for (final (i, m) in abertas.indexed)
                        AnelConcentrico(
                          fracao: m.progresso / 100,
                          opacidade: _opacidades[i],
                        ),
                    ],
                    resumo: abertas
                        .map(
                          (m) => ptS.metaResumo(
                            metaMetricaRotulo(m.metrica),
                            metaValor(m.metrica, m.valorAtual),
                            metaValor(m.metrica, m.valorAlvo),
                            m.progresso,
                          ),
                        )
                        .join('. '),
                  ),
                  const SizedBox(width: TokensStrip.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final m in abertas)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: TokensStrip.s1,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${metaMetricaRotulo(m.metrica)} · ${m.progresso}%',
                                  style: FocuxHubTypography.chip(sobre.mute),
                                ),
                                Text(
                                  '${metaValor(m.metrica, m.valorAtual)} → ${metaValor(m.metrica, m.valorAlvo)}',
                                  style: FocuxHubTypography.cardTitle(
                                    color: sobre.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            if (acao case final acao?) ...[
              const SizedBox(height: TokensStrip.s2),
              Theme(data: fxTemaSobreMarca(context), child: acao),
            ],
          ],
        ),
      ),
    );
  }
}
