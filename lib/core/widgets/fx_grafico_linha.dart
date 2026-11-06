import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/focux_hub_typography.dart';
import '../theme/shell_chrome.dart';
import '../utils/motion_preferences.dart';
import '../utils/pt_br_display.dart';
import '../../l10n/pt.dart';

class PontoGrafico {
  const PontoGrafico(this.data, this.valor);

  final DateTime data;
  final double valor;
}

/// Linha no tempo com eixos e toque.
class FxGraficoLinha extends StatelessWidget {
  const FxGraficoLinha({
    super.key,
    required this.pontos,
    required this.unidade,
    required this.resumo,
    this.tendencia = const [],
    this.alvo,
    this.altura = 200,
  });

  final List<PontoGrafico> pontos;
  final String unidade;

  /// O que o leitor de tela diz no lugar do desenho.
  final String resumo;

  /// Com tendência, os registros ficam em segundo plano e ela vira a linha principal.
  final List<double> tendencia;

  /// Linha tracejada do alvo.
  final double? alvo;
  final double altura;

  static String _data(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  /// Eixo Y com passo redondo (1, 2, 2,5 ou 5 × 10ⁿ) e limites múltiplos
  /// dele: as marcas saem 40, 50, 60 em vez de 37, 56, 75.
  @visibleForTesting
  static ({double min, double max, double passo}) eixoY(
    double menor,
    double maior,
  ) {
    if (maior == menor) {
      menor -= 1;
      maior += 1;
    }
    // Folga pequena: ponto no limite não fica colado na borda.
    final margem = (maior - menor) * 0.08;
    final baixo = menor - margem;
    final alto = maior + margem;
    final bruto = (alto - baixo) / 3;
    final base = math.pow(10, (math.log(bruto) / math.ln10).floor()).toDouble();
    final passo = [
      1,
      2,
      2.5,
      5,
      10,
    ].map((m) => m * base).firstWhere((p) => p >= bruto);
    final min = (baixo / passo).floor() * passo;
    final max = (alto / passo).ceil() * passo;
    return (min: min, max: max, passo: passo);
  }

  double _x(int i) =>
      pontos[i].data.difference(pontos.first.data).inHours / 24 + i * 0.01;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final valores = [
      ...pontos.map((p) => p.valor),
      ...tendencia,
      if (alvo case final alvo?) alvo,
    ];
    final menor = valores.reduce((a, b) => a < b ? a : b);
    final maior = valores.reduce((a, b) => a > b ? a : b);
    final eixo = eixoY(menor, maior);
    final minY = eixo.min;
    final maxY = eixo.max;
    final casasDoEixo = eixo.passo % 1 == 0 ? 0 : 1;
    final maxX = _x(pontos.length - 1);
    final temTendencia = tendencia.length == pontos.length;
    final estiloEixo = FocuxHubTypography.chip(chrome.mute);

    final registros = LineChartBarData(
      spots: [
        for (var i = 0; i < pontos.length; i++) FlSpot(_x(i), pontos[i].valor),
      ],
      isCurved: !temTendencia,
      preventCurveOverShooting: true,
      color: temTendencia ? primary.withValues(alpha: 0.28) : primary,
      barWidth: temTendencia ? 1.5 : 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        getDotPainter:
            (_, __, ___, ____) => FlDotCirclePainter(
              radius: temTendencia ? 2.5 : 3.5,
              color: temTendencia ? primary.withValues(alpha: 0.4) : primary,
              strokeWidth: 0,
            ),
      ),
      belowBarData: BarAreaData(
        show: !temTendencia,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primary.withValues(alpha: 0.18),
            primary.withValues(alpha: 0),
          ],
        ),
      ),
    );

    return Semantics(
      label: resumo,
      excludeSemantics: true,
      child: SizedBox(
        height: altura,
        child: LineChart(
          duration:
              fxMotionDurationMs(context) == 0
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
          LineChartData(
            minX: 0,
            maxX: maxX <= 0 ? 1 : maxX,
            minY: minY,
            maxY: maxY,
            borderData: FlBorderData(show: false),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                if (alvo case final alvo?)
                  HorizontalLine(
                    y: alvo,
                    color: chrome.mute,
                    strokeWidth: 1.5,
                    dashArray: const [6, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: estiloEixo,
                      labelResolver: (_) => ptS.evolucaoAlvoDe('${formatBrDecimal(alvo)} $unidade'),
                    ),
                  ),
              ],
            ),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: eixo.passo,
              getDrawingHorizontalLine:
                  (_) => FlLine(color: chrome.line, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: eixo.passo,
                  getTitlesWidget:
                      (valor, meta) =>
                          valor == meta.min || valor == meta.max
                              ? const SizedBox.shrink()
                              : Text(
                                formatBrDecimal(valor, digits: casasDoEixo),
                                style: estiloEixo,
                              ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  interval: maxX <= 0 ? 1 : maxX / 3,
                  getTitlesWidget: (valor, meta) {
                    final data = pontos.first.data.add(
                      Duration(hours: (valor * 24).round()),
                    );
                    return SideTitleWidget(
                      meta: meta,
                      // Primeira e última data não vazam para fora do card.
                      fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                      child: Text(_data(data), style: estiloEixo),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => chrome.ink,
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItems:
                    (spots) => [
                      for (final spot in spots)
                        spot.barIndex == 0
                            ? LineTooltipItem(
                              '${formatBrDecimal(pontos[spot.spotIndex].valor)} $unidade\n'
                              '${_data(pontos[spot.spotIndex].data)}',
                              FocuxHubTypography.chip(
                                Theme.of(context).colorScheme.surface,
                              ),
                            )
                            : null,
                    ],
              ),
            ),
            lineBarsData: [
              registros,
              if (temTendencia)
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < pontos.length; i++)
                      FlSpot(_x(i), tendencia[i]),
                  ],
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
