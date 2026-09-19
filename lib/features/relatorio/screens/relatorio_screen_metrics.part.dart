part of 'relatorio_screen.dart';

extension on _RelatorioScreenState {
  List<Widget> _metricTiles({
    required AderenciaData? dados,
    required bool isDark,
    required Color primary,
  }) {
    if (dados == null || dados.treinosTotal == 0) {
      return [
        const SizedBox(height: TokensStrip.s4),
        OperationalMetricTile(
          label: 'Taxa',
          value: '—',
          hint: 'Sem treinos neste recorte',
          color: primary,
          isDark: isDark,
          emphasis: OperationalMetricEmphasis.muted,
        ),
        const SizedBox(height: TokensStrip.s2),
        OperationalMetricTile(
          label: 'Treinos',
          value: '0 / 0',
          hint: 'Ainda sem treinos',
          color: primary,
          isDark: isDark,
          emphasis: OperationalMetricEmphasis.muted,
        ),
        const SizedBox(height: TokensStrip.s2),
        OperationalMetricTile(
          label: 'Período',
          value: relatorioAlunoPeriodoMetricValue(
            dados?.diasAnalisados ?? _dias,
          ),
          hint: relatorioAlunoPeriodoMetricHint(),
          color: primary,
          isDark: isDark,
          emphasis: OperationalMetricEmphasis.muted,
        ),
        const SizedBox(height: TokensStrip.s2),
        OperationalMetricTile(
          label: 'Check-ins',
          value: '—',
          hint: relatorioAlunoCheckinsMetricHint(null),
          color: primary,
          isDark: isDark,
          emphasis: OperationalMetricEmphasis.muted,
        ),
      ];
    }
    return [
      Padding(
        padding: const EdgeInsets.only(
          top: TokensStrip.s4,
          bottom: TokensStrip.s2,
        ),
        child: OperationalMetricTile(
          label: 'Taxa',
          value: relatorioAderenciaMediaLabel(dados.taxaAderenciaPercent),
          hint: relatorioAlunoAderenciaStatus(dados.taxaAderenciaPercent),
          color:
              relatorioAlunoAderenciaBaixa(dados.taxaAderenciaPercent)
                  ? EagleTokens.bad
                  : primary,
          isDark: isDark,
          emphasis:
              relatorioAlunoAderenciaBaixa(dados.taxaAderenciaPercent)
                  ? OperationalMetricEmphasis.alert
                  : OperationalMetricEmphasis.normal,
        ),
      ),
      OperationalMetricTile(
        label: 'Dias',
        value: '${dados.treinosConcluidos} / ${dados.treinosTotal}',
        hint: relatorioTreinosSubtitle(
          dados.treinosConcluidos,
          dados.treinosTotal,
        ),
        color: primary,
        isDark: isDark,
      ),
      const SizedBox(height: TokensStrip.s2),
      OperationalMetricTile(
        label: 'Período',
        value: relatorioAlunoPeriodoMetricValue(dados.diasAnalisados),
        hint: relatorioAlunoPeriodoMetricHint(),
        color: primary,
        isDark: isDark,
      ),
      const SizedBox(height: TokensStrip.s2),
      OperationalMetricTile(
        label: 'Check-ins',
        value: relatorioAlunoCheckinsMetricValue(_comparativo?.checkInsAtual),
        hint: relatorioAlunoCheckinsMetricHint(_comparativo?.checkInsAtual),
        color: primary,
        isDark: isDark,
        emphasis:
            _comparativo == null
                ? OperationalMetricEmphasis.muted
                : OperationalMetricEmphasis.normal,
      ),
    ];
  }
}
