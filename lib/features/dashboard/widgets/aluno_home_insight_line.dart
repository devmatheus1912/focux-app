import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../l10n/app_localizations.dart';
import '../data/aluno_home_insight.dart';
import '../utils/aluno_insight_analytics.dart';
import '../utils/aluno_insight_display.dart';

/// Um insight por vez no card "Hoje"; substitui a pill de ritmo quando o BFF manda.
class AlunoHomeInsightLine extends StatefulWidget {
  const AlunoHomeInsightLine({
    super.key,
    required this.insight,
    required this.onPrimary,
    required this.onAction,
    this.showAction = true,
  });

  final AlunoHomeInsight insight;
  final Color onPrimary;
  final ValueChanged<String> onAction;
  final bool showAction;

  @override
  State<AlunoHomeInsightLine> createState() => _AlunoHomeInsightLineState();
}

class _AlunoHomeInsightLineState extends State<AlunoHomeInsightLine> {
  @override
  void initState() {
    super.initState();
    AlunoInsightAnalytics.viewed(widget.insight);
  }

  @override
  void didUpdateWidget(covariant AlunoHomeInsightLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.insight.tipo != widget.insight.tipo) {
      AlunoInsightAnalytics.viewed(widget.insight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insight = widget.insight;
    final texto = alunoInsightTexto(S.of(context), insight);
    final acao = widget.showAction ? insight.acao : null;
    final cta = acao == null ? null : texto.cta;
    final primary = Theme.of(context).colorScheme.primary;

    return Semantics(
      button: cta != null,
      label: [texto.titulo, texto.detalhe, if (cta != null) cta].join('. '),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(TokensStrip.s2),
        onTap:
            cta == null
                ? null
                : () {
                  AlunoInsightAnalytics.actionTapped(insight);
                  widget.onAction(acao!.rota);
                },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Icon(
                alunoInsightIcone(insight.tipo),
                size: 18,
                color: widget.onPrimary,
              ),
              const SizedBox(width: TokensStrip.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      texto.titulo,
                      style: FocuxHubTypography.chip(widget.onPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: TokensStrip.s1),
                    Text(
                      texto.detalhe,
                      style: FocuxHubTypography.bodyMuted(
                        color: widget.onPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (cta != null) ...[
                const SizedBox(width: TokensStrip.s2),
                Text(cta, style: FocuxHubTypography.chip(primary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
