import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_anel.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/pt.dart';
import '../data/evolucao_repository.dart';

/// Antes disso o aluno está começando: sem porcentagem nem risco.
const aderenciaDiasComecando = 14;

/// Topo da tela: a porcentagem, os primeiros dias ou a falta de ficha.
class EngajamentoCardAderencia extends StatelessWidget {
  const EngajamentoCardAderencia({
    super.key,
    required this.resumo,
    required this.aderenciaCadastro,
    required this.frase,
    required this.tendencia,
    this.onMontarFicha,
  });

  final AderenciaResumo? resumo;
  final int aderenciaCadastro;
  final String frase;
  final ({int diferenca, String texto})? tendencia;
  final VoidCallback? onMontarFicha;

  @override
  Widget build(BuildContext context) {
    final sobre = fxPaletaSobreMarca(context);
    final r = resumo;
    final percent =
        r == null
            ? (aderenciaCadastro > 0 ? aderenciaCadastro : null)
            : r.percent;
    final comecando = r?.comecando == true;
    final semFicha = !comecando && percent == null;
    final fracao =
        comecando
            ? (r!.diaDaFicha / aderenciaDiasComecando).clamp(0.0, 1.0).toDouble()
            : (percent ?? 0) / 100;
    final centro = comecando ? ptS.aderenciaDia(r!.diaDaFicha) : '$percent%';
    final titulo =
        comecando
            ? ptS.aderenciaComecando
            : semFicha
            ? ptS.aderenciaSemFicha
            : ptS.aderenciaFichaCumprida;
    final apoio =
        comecando
            ? ptS.aderenciaTreinosAteAgora(r!.feitos)
            : semFicha || r == null
            ? null
            : ptS.aderenciaDiasPrevistos(r.feitos, r.previstos);
    final tend = tendencia;
    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: FocuxHubTypography.cardTitle(color: sobre.ink)),
        if (apoio != null)
          Text(apoio, style: FocuxHubTypography.bodyMuted(color: sobre.mute)),
        const SizedBox(height: TokensStrip.s1),
        Text(
          comecando ? ptS.aderenciaPorcentagemNoDia15 : frase,
          style: FocuxHubTypography.bodyMuted(color: sobre.ink),
        ),
        if (tend != null && !comecando && !semFicha) ...[
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
        if (semFicha && onMontarFicha != null) ...[
          const SizedBox(height: TokensStrip.s2),
          Theme(
            data: fxTemaSobreMarca(context),
            child: FxTonalButton(
              label: ptS.aderenciaMontarFicha,
              compact: true,
              onPressed: onMontarFicha,
            ),
          ),
        ],
      ],
    );
    return FxStripCard(
      marca: true,
      child:
          semFicha
              ? SizedBox(width: double.infinity, child: textos)
              : Row(
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
                  Expanded(child: textos),
                ],
              ),
    );
  }
}
