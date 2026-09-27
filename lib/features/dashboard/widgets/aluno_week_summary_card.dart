import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/aluno_home_texts.dart';
import '../utils/aluno_home_week.dart';
import 'dashboard_section_header.dart';

/// "Sua semana": sessões x meta, sequência e volume. Lido como uma frase.
class AlunoWeekSummaryCard extends StatelessWidget {
  const AlunoWeekSummaryCard({super.key, required this.summary});

  final AlunoWeekSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.isEmpty) return const SizedBox.shrink();
    final s = S.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final volume = summary.volumeKg;

    Widget tile(String label, String value) => Expanded(
      child: OperationalMetricTile(
        label: label,
        value: value,
        color: primary,
        isDark: isDark,
        dense: true,
      ),
    );

    final tiles = [
      if (summary.feitos != null)
        tile(s.alunoSemanaTreinosLabel, alunoTreinosSemanaValor(s, summary)),
      tile(
        s.alunoSemanaSequenciaLabel,
        s.alunoSemanaSequenciaValor(summary.streakSemanas),
      ),
      if (volume != null)
        tile(s.alunoSemanaVolumeLabel, alunoVolumeTexto(s, volume)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSectionHeader(title: s.alunoSemanaTitulo),
        const SizedBox(height: TokensStrip.s2),
        Semantics(
          label: alunoWeekSemantics(s, summary),
          excludeSemantics: true,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(width: TokensStrip.s2),
                  tiles[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
