import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../l10n/app_localizations.dart';
import '../data/aluno_home_insight.dart';
import '../utils/aluno_insight_analytics.dart';
import '../utils/aluno_insight_display.dart';

/// Um insight por vez no card "Hoje", quando o BFF manda. Só leitura: o CTA do
/// card é o único toque.
class AlunoHomeInsightLine extends StatefulWidget {
  const AlunoHomeInsightLine({
    super.key,
    required this.insight,
    required this.onPrimary,
  });

  final AlunoHomeInsight insight;
  final Color onPrimary;

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
    final texto = alunoInsightTexto(S.of(context), widget.insight);
    return Semantics(
      label: '${texto.titulo}. ${texto.detalhe}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            alunoInsightIcone(widget.insight.tipo),
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
                  style: FocuxHubTypography.bodyMuted(color: widget.onPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
