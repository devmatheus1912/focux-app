import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_anel.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../l10n/pt.dart';
import '../data/evolucao_repository.dart';

/// Topo da tela: o número com anel, ou "Começando" enquanto não há base justa.
class EngajamentoCardAderencia extends StatelessWidget {
  const EngajamentoCardAderencia({
    super.key,
    required this.resumo,
    required this.aderenciaCadastro,
    required this.frase,
    required this.tendencia,
  });

  final AderenciaResumo? resumo;
  final int aderenciaCadastro;
  final String frase;
  final ({int diferenca, String texto})? tendencia;

  @override
  Widget build(BuildContext context) {
    final sobre = fxPaletaSobreMarca(context);
    final r = resumo;
    final percent =
        r == null
            ? (aderenciaCadastro > 0 ? aderenciaCadastro : null)
            : r.percent;
    final previstos = r?.previstos ?? 0;
    final fracao =
        percent != null
            ? percent / 100
            : previstos > 0
            ? (r!.feitos / previstos).clamp(0.0, 1.0).toDouble()
            : 0.0;
    final centro =
        percent != null
            ? '$percent%'
            : previstos > 0
            ? '${r!.feitos}/$previstos'
            : '—';
    final titulo =
        r?.comecando == true
            ? ptS.aderenciaComecando
            : previstos == 0 && percent == null
            ? ptS.aderenciaSemFicha
            : ptS.aderenciaTitulo;
    final tend = tendencia;
    return FxStripCard(
      marca: true,
      child: Row(
        children: [
          FxAnel(
            fracao: fracao,
            cor: sobre.ink,
            fundo: sobre.ink.withValues(alpha: 0.2),
            child: Text(
              centro,
              style: FocuxHubTypography.metric(
                color: sobre.ink,
                fontSize: FocuxHubTypography.metricMd,
              ),
            ),
          ),
          const SizedBox(width: TokensStrip.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: FocuxHubTypography.cardTitle(color: sobre.ink),
                ),
                if (previstos > 0)
                  Text(
                    ptS.aderenciaTreinosPrevistos(r!.feitos, previstos),
                    style: FocuxHubTypography.bodyMuted(color: sobre.mute),
                  ),
                const SizedBox(height: TokensStrip.s1),
                Text(
                  frase,
                  style: FocuxHubTypography.bodyMuted(color: sobre.ink),
                ),
                if (tend != null) ...[
                  const SizedBox(height: TokensStrip.s1),
                  Text(
                    '${tend.diferenca > 0
                        ? '↑ '
                        : tend.diferenca < 0
                        ? '↓ '
                        : ''}${tend.texto}',
                    style: FocuxHubTypography.bodyMuted(color: sobre.mute),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
