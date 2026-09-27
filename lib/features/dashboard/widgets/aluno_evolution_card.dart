import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
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

/// "Evolução": força (1RM est.) e volume das últimas semanas, variação da
/// força e o último recorde. O texto do insight fica só no card de foco.
class AlunoEvolutionCard extends StatelessWidget {
  const AlunoEvolutionCard({
    super.key,
    required this.volumePorSemana,
    required this.forcaPorSemana,
    this.forcaDeltaPercent,
    this.ultimoRecorde,
  });

  final List<double> volumePorSemana;
  final List<double> forcaPorSemana;
  final double? forcaDeltaPercent;
  final RecordePessoal? ultimoRecorde;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = ShellChrome.of(context).mute;
    final hasChart =
        alunoTrendPlot(volumePorSemana) != null ||
        alunoTrendPlot(forcaPorSemana) != null;
    final delta = forcaDeltaPercent;
    final recorde = ultimoRecorde;
    final recordeTexto =
        recorde == null
            ? null
            : alunoRecordeTexto(s, recorde.exercicioNome, recorde.cargaKg);

    final tiles = [
      if (delta != null)
        OperationalMetricTile(
          label: s.alunoEvolucaoForcaLabel,
          value: alunoForcaDeltaTexto(s, delta),
          color: EagleTokens.good,
          isDark: isDark,
          dense: true,
        ),
      if (recordeTexto != null)
        OperationalMetricTile(
          label: s.alunoEvolucaoRecordeLabel,
          value: recordeTexto,
          color: primary,
          isDark: isDark,
          dense: true,
          semanticsLabel: '${s.alunoEvolucaoRecordeLabel}: $recordeTexto',
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
                _DualTrendChart(
                  volume: volumePorSemana,
                  forca: forcaPorSemana,
                  volumeColor: primary,
                  forcaColor: EagleTokens.good,
                  semanticsLabel: s.alunoEvolucaoGraficoSemantics(
                    volumePorSemana.length,
                  ),
                ),
                const SizedBox(height: TokensStrip.s2),
                Row(
                  children: [
                    _LegendDot(
                      color: primary,
                      label: s.alunoEvolucaoLegendaVolume,
                    ),
                    const SizedBox(width: TokensStrip.s3),
                    _LegendDot(
                      color: EagleTokens.good,
                      label: s.alunoEvolucaoLegendaForca,
                    ),
                  ],
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

class _DualTrendChart extends StatelessWidget {
  final List<double> volume;
  final List<double> forca;
  final Color volumeColor;
  final Color forcaColor;
  final String semanticsLabel;

  const _DualTrendChart({
    required this.volume,
    required this.forca,
    required this.volumeColor,
    required this.forcaColor,
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
        child: CustomPaint(
          painter: _DualTrendPainter(
            volume: volume,
            forca: forca,
            volumeColor: volumeColor,
            forcaColor: forcaColor,
          ),
        ),
      ),
    );
  }
}

class _DualTrendPainter extends CustomPainter {
  final List<double> volume;
  final List<double> forca;
  final Color volumeColor;
  final Color forcaColor;

  _DualTrendPainter({
    required this.volume,
    required this.forca,
    required this.volumeColor,
    required this.forcaColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintSeries(canvas, size, forca, forcaColor, strokeWidth: 2);
    _paintSeries(canvas, size, volume, volumeColor, strokeWidth: 2.4);
  }

  void _paintSeries(
    Canvas canvas,
    Size size,
    List<double> data,
    Color color, {
    required double strokeWidth,
  }) {
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
  bool shouldRepaint(covariant _DualTrendPainter oldDelegate) {
    return oldDelegate.volume != volume ||
        oldDelegate.forca != forca ||
        oldDelegate.volumeColor != volumeColor ||
        oldDelegate.forcaColor != forcaColor;
  }
}
