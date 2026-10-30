import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../models/ia_copilot_insight.dart';

class IaCopilotInsightItem extends StatefulWidget {
  const IaCopilotInsightItem({
    super.key,
    required this.index,
    required this.insight,
    required this.highlighted,
    required this.brand,
    required this.mute,
  });

  final int index;
  final IaCopilotInsight insight;
  final bool highlighted;
  final Color brand;
  final Color mute;

  @override
  State<IaCopilotInsightItem> createState() => _IaCopilotInsightItemState();
}

class _IaCopilotInsightItemState extends State<IaCopilotInsightItem> {
  bool _expanded = false;

  static const _linhasFechado = 3;
  static const _charsPorLinha = 40;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final insight = widget.insight;
    final ink = fxScreenInk(context);
    final recomendacao = insight.recomendacao;
    final longo =
        insight.detalhe.length + recomendacao.length >
        _linhasFechado * 2 * _charsPorLinha;
    final linhas = _expanded || !longo ? null : _linhasFechado;

    Widget bloco(String rotulo, String texto) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: FocuxHubTypography.bodyMuted(
            color: widget.mute,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          texto,
          maxLines: linhas,
          overflow: linhas == null ? null : TextOverflow.ellipsis,
          style: FocuxHubTypography.body(color: ink),
        ),
      ],
    );

    return Semantics(
      button: longo,
      label: [
        insight.titulo,
        insight.detalhe,
        if (recomendacao.isNotEmpty) recomendacao,
      ].join('. '),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: TokensStrip.s2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: longo ? () => setState(() => _expanded = !_expanded) : null,
            borderRadius: BorderRadius.circular(TokensStrip.rCard),
            child: Ink(
              decoration: fxListCardDecoration(
                context,
                accent: widget.highlighted ? widget.brand : null,
              ),
              padding: const EdgeInsets.all(TokensStrip.s3),
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
                      if (longo)
                        Icon(
                          _expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 20,
                          color: widget.mute,
                        ),
                    ],
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  bloco(s.copilotoOQueVimos, insight.detalhe),
                  if (recomendacao.isNotEmpty) ...[
                    const SizedBox(height: TokensStrip.s2),
                    bloco(s.copilotoOQueFazer, recomendacao),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class IaCopilotInsightsLoading extends StatelessWidget {
  const IaCopilotInsightsLoading({
    super.key,
    required this.ink,
    required this.mute,
    required this.brand,
  });

  final Color ink;
  final Color mute;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    final soft = brand.withValues(alpha: 0.10);
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context, accent: primary, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome, color: brand, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preparando recomendações',
                      style: TextStyle(
                        color: ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Organizando as recomendações...',
                      style: TextStyle(
                        color: mute,
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s4),
          for (final width in const [0.92, 0.74, 0.84])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FractionallySizedBox(
                widthFactor: width,
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
