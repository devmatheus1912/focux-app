part of 'relatorio_screen.dart';

extension on _RelatorioScreenState {
  List<Widget> _metricTiles({
    required AderenciaData? dados,
    required bool isDark,
    required Color primary,
  }) {
    if (dados == null || dados.treinosTotal == 0) {
      return [
        const SizedBox(height: TokensStrip.s3),
        Row(
          children: [
            Expanded(
              child: OperationalMetricTile(
                label: 'Taxa',
                value: '—',
                hint: 'Sem treinos neste recorte',
                color: primary,
                isDark: isDark,
                dense: true,
                emphasis: OperationalMetricEmphasis.muted,
              ),
            ),
            const SizedBox(width: TokensStrip.s2),
            Expanded(
              child: OperationalMetricTile(
                label: 'Dias',
                value: '0 / 0',
                hint: 'Ainda sem dias com check-in',
                color: primary,
                isDark: isDark,
                dense: true,
                emphasis: OperationalMetricEmphasis.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: TokensStrip.s2),
        Row(
          children: [
            Expanded(
              child: OperationalMetricTile(
                label: 'Período',
                value: relatorioAlunoPeriodoMetricValue(
                  dados?.diasAnalisados ?? _dias,
                ),
                hint: relatorioAlunoPeriodoMetricHint(),
                color: primary,
                isDark: isDark,
                dense: true,
                emphasis: OperationalMetricEmphasis.muted,
              ),
            ),
            const SizedBox(width: TokensStrip.s2),
            Expanded(
              child: OperationalMetricTile(
                label: 'Check-ins',
                value: '—',
                hint: relatorioAlunoCheckinsMetricHint(null),
                color: primary,
                isDark: isDark,
                dense: true,
                emphasis: OperationalMetricEmphasis.muted,
              ),
            ),
          ],
        ),
      ];
    }
    return [
      Padding(
        padding: const EdgeInsets.only(
          top: TokensStrip.s3,
          bottom: TokensStrip.s2,
        ),
        child: Row(
          children: [
            Expanded(
              child: OperationalMetricTile(
                label: 'Taxa',
                value: relatorioAderenciaMediaLabel(dados.taxaAderenciaPercent),
                hint: relatorioAlunoAderenciaStatus(dados.taxaAderenciaPercent),
                color:
                    relatorioAlunoAderenciaBaixa(dados.taxaAderenciaPercent)
                        ? EagleTokens.bad
                        : primary,
                isDark: isDark,
                dense: true,
                emphasis:
                    relatorioAlunoAderenciaBaixa(dados.taxaAderenciaPercent)
                        ? OperationalMetricEmphasis.alert
                        : OperationalMetricEmphasis.normal,
              ),
            ),
            const SizedBox(width: TokensStrip.s2),
            Expanded(
              child: OperationalMetricTile(
                label: 'Dias',
                value: '${dados.treinosConcluidos} / ${dados.treinosTotal}',
                hint: relatorioTreinosSubtitle(
                  dados.treinosConcluidos,
                  dados.treinosTotal,
                ),
                color: primary,
                isDark: isDark,
                dense: true,
              ),
            ),
          ],
        ),
      ),
      Row(
        children: [
          Expanded(
            child: OperationalMetricTile(
              label: 'Período',
              value: relatorioAlunoPeriodoMetricValue(dados.diasAnalisados),
              hint: relatorioAlunoPeriodoMetricHint(),
              color: primary,
              isDark: isDark,
              dense: true,
            ),
          ),
          const SizedBox(width: TokensStrip.s2),
          Expanded(
            child: OperationalMetricTile(
              label: 'Check-ins',
              value: relatorioAlunoCheckinsMetricValue(_comparativo?.checkInsAtual),
              hint: relatorioAlunoCheckinsMetricHint(_comparativo?.checkInsAtual),
              color: primary,
              isDark: isDark,
              dense: true,
              emphasis:
                  _comparativo == null
                      ? OperationalMetricEmphasis.muted
                      : OperationalMetricEmphasis.normal,
            ),
          ),
        ],
      ),
    ];
  }
}
