import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/app_localizations.dart';
import '../models/ia_copilot_insight.dart';
import '../../../core/theme/fx_icons.dart';

class IaCopilotInsightItem extends StatefulWidget {
  const IaCopilotInsightItem({
    super.key,
    required this.index,
    required this.insight,
    required this.brand,
    required this.mute,
    this.acaoLabel,
    this.onAcao,
    this.onMais,
    this.feitoLabel,
    this.dispensada = false,
  });

  /// Feita: "Feito · Mensagem enviada" no lugar do botão.
  final String? feitoLabel;

  /// Dispensada: "Dispensada", em tom apagado, sem botão.
  final bool dispensada;

  final int index;
  final IaCopilotInsight insight;
  final Color brand;
  final Color mute;

  /// Verbo da ação desta recomendação ("Ajustar cargas"); sem ação, sem botão.
  final String? acaoLabel;
  final VoidCallback? onAcao;

  /// "⋯" da recomendação (criar tarefa com o "O que fazer" dela).
  final VoidCallback? onMais;

  @override
  State<IaCopilotInsightItem> createState() => _IaCopilotInsightItemState();
}

class _IaCopilotInsightItemState extends State<IaCopilotInsightItem> {
  // A primeira recomendação abre sozinha; as outras ficam no título.
  late bool _expanded = widget.index == 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final insight = widget.insight;
    final ink = fxScreenInk(context);
    final recomendacao = insight.recomendacao;

    Widget bloco(String rotulo, String texto) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: FocuxHubTypography.chip(widget.mute)),
        const SizedBox(height: 2),
        Text(texto, style: FocuxHubTypography.body(color: ink)),
      ],
    );

    final resolvida = widget.feitoLabel != null || widget.dispensada;
    final temBotoes =
        _expanded && (widget.onAcao != null || widget.onMais != null || resolvida);

    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s2),
      child: DecoratedBox(
        decoration: fxListCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              expanded: _expanded,
              label: [
                insight.titulo,
                if (_expanded) insight.detalhe,
                if (_expanded && recomendacao.isNotEmpty) recomendacao,
              ].join('. '),
              excludeSemantics: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(TokensStrip.rCard),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      TokensStrip.s3,
                      TokensStrip.s3,
                      TokensStrip.s3,
                      temBotoes ? TokensStrip.s1 : TokensStrip.s3,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                insight.titulo,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: FocuxHubTypography.cardTitle(color: ink),
                              ),
                            ),
                            Icon(
                              _expanded
                                  ? FxIcons.chevronCima
                                  : FxIcons.chevronBaixo,
                              size: 20,
                              color: widget.mute,
                            ),
                          ],
                        ),
                        if (_expanded) ...[
                          const SizedBox(height: TokensStrip.s2),
                          bloco(s.copilotoOQueVimos, insight.detalhe),
                          if (recomendacao.isNotEmpty) ...[
                            const SizedBox(height: TokensStrip.s2),
                            bloco(s.copilotoOQueFazer, recomendacao),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Fora do bloco tocável: o leitor de tela alcança cada botão.
            if (temBotoes)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TokensStrip.s3,
                  0,
                  TokensStrip.s1,
                  TokensStrip.s2,
                ),
                child: Row(
                  children: [
                    if (widget.feitoLabel case final feito?)
                      Row(
                        children: [
                          Icon(FxIcons.concluido, size: 16, color: EagleTokens.good),
                          const SizedBox(width: TokensStrip.s1),
                          Text(
                            'Feito · $feito',
                            style: FocuxHubTypography.chip(EagleTokens.good),
                          ),
                        ],
                      )
                    else if (widget.dispensada)
                      Text(
                        'Dispensada',
                        style: FocuxHubTypography.chip(widget.mute),
                      )
                    else if (widget.onAcao case final acao?)
                      FxTonalButton(
                        label: widget.acaoLabel ?? '',
                        compact: true,
                        onPressed: acao,
                      ),
                    const Spacer(),
                    if (widget.onMais case final mais?)
                      IconButton(
                        tooltip: 'Mais opções desta recomendação',
                        icon: Icon(FxIcons.mais, color: widget.mute),
                        onPressed: mais,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

