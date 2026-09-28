import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../../evolucao/data/evolucao_repository.dart';
import '../utils/aluno_home_texts.dart';
import '../utils/aluno_performance_evolution.dart';
import 'dashboard_section_header.dart';

/// "Evolução": força (1RM est.) das últimas semanas, variação da força e o
/// último recorde. Volume fica só em "Sua semana"; o insight, no card de foco.
class AlunoEvolutionCard extends StatelessWidget {
  const AlunoEvolutionCard({
    super.key,
    required this.forcaPorSemana,
    this.forcaDeltaPercent,
    this.ultimoRecorde,
    this.recordeRecente = false,
  });

  final List<double> forcaPorSemana;
  final double? forcaDeltaPercent;
  final RecordePessoal? ultimoRecorde;
  final bool recordeRecente;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final forcaColor = scheme.secondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = ShellChrome.of(context).mute;
    final hasChart = alunoTrendPlot(forcaPorSemana) != null;
    final delta = forcaDeltaPercent;
    final recorde = ultimoRecorde;
    final recordeTexto =
        recorde == null
            ? null
            : alunoRecordeTexto(s, recorde.exercicioNome, recorde.cargaKg);
    final recordeLabel =
        recordeRecente
            ? s.alunoEvolucaoRecordeNovoLabel
            : s.alunoEvolucaoRecordeLabel;

    final tiles = [
      if (delta != null)
        OperationalMetricTile(
          label: s.alunoEvolucaoForcaLabel,
          value: alunoForcaDeltaTexto(s, delta),
          color: alunoForcaDeltaTom(delta),
          isDark: isDark,
          dense: true,
        ),
      if (recordeTexto != null)
        OperationalMetricTile(
          label: recordeLabel,
          value: recordeTexto,
          color: primary,
          isDark: isDark,
          dense: true,
          leadingIcon: recordeRecente ? Icons.emoji_events_rounded : null,
          semanticsLabel: '$recordeLabel: $recordeTexto',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSectionHeader(title: s.alunoEvolucaoTitulo),
        const SizedBox(height: TokensStrip.s2),
        Container(
          padding: const EdgeInsets.all(TokensStrip.s4),
          decoration: fxListCardDecoration(context, accent: primary),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!hasChart && tiles.isEmpty)
                Text(
                  s.alunoEvolucaoVazio,
                  style: FocuxHubTypography.bodyMuted(color: mute),
                ),
              if (hasChart) ...[
                _TrendChart(
                  data: forcaPorSemana,
                  color: forcaColor,
                  semanticsLabel: s.alunoEvolucaoGraficoSemantics(
                    forcaPorSemana.length,
                  ),
                ),
                const SizedBox(height: TokensStrip.s2),
                _LegendDot(
                  color: forcaColor,
                  label: s.alunoEvolucaoLegendaForca,
                ),
              ],
              if (tiles.isNotEmpty) ...[
                if (hasChart) const SizedBox(height: TokensStrip.s3),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < tiles.length; i++) ...[
                        if (i > 0) const SizedBox(width: TokensStrip.s2),
                        Expanded(child: tiles[i]),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final mute = ShellChrome.of(context).mute;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: FocuxHubTypography.chip(mute)),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  final String semanticsLabel;

  const _TrendChart({
    required this.data,
    required this.color,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticsLabel,
      child: SizedBox(
        height: 88,
        width: double.infinity,
        child: CustomPaint(painter: _TrendPainter(data: data, color: color)),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  static const strokeWidth = 2.4;

  final List<double> data;
  final Color color;

  _TrendPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final plot = alunoTrendPlot(data);
    if (plot == null) return;
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    final path = Path();
    final isolated = <Offset>[];
    for (var p = 0; p < plot.indexes.length; p++) {
      final i = plot.indexes[p];
      final x =
          plot.slotCount == 1
              ? size.width / 2
              : i * size.width / (plot.slotCount - 1);
      final norm = (plot.values[p] - plot.minVal) / plot.span;
      final y = size.height - (norm * (size.height - 8)) - 4;
      if (plot.startsSegment(p)) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      if (plot.isIsolated(p)) isolated.add(Offset(x, y));
    }
    canvas.drawPath(path, paint);
    for (final at in isolated) {
      canvas.drawCircle(at, strokeWidth, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}
