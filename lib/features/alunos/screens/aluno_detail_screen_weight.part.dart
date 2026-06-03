part of 'aluno_detail_screen.dart';

class _AlunoWeightActivityCard extends ConsumerWidget {
  const _AlunoWeightActivityCard({
    required this.aluno,
    required this.alunoId,
    required this.isDark,
    required this.ink,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color ink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pesoHistoricoAsync = ref.watch(alunoPesoHistoricoProvider(alunoId));
    final primary = Theme.of(context).colorScheme.primary;
    final trendColor = primary;

    return Container(
      decoration: fxListCardDecoration(context),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PESO · TENDÊNCIA',
                    style: TextStyle(
                      color:
                          isDark
                              ? EagleTokens.darkInkMute
                              : TokensStrip.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Semantics(
                    label:
                        aluno.peso == null
                            ? 'Peso não registrado'
                            : 'Peso ${aluno.peso!.toStringAsFixed(1)} quilogramas',
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          aluno.peso?.toStringAsFixed(1) ?? '--',
                          style: TextStyle(
                            color: ink,
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (aluno.peso != null) ...[
                          const SizedBox(width: 3),
                          Text(
                            'kg',
                            style: TextStyle(
                              color:
                                  isDark
                                      ? EagleTokens.darkInkMute
                                      : TokensStrip.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              Text(
                aluno.peso == null
                    ? 'Sem medida registrada'
                    : 'Ver evolução completa',
                style: TextStyle(
                  color:
                      isDark
                          ? EagleTokens.darkInkMute
                          : TokensStrip.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 72,
            child: pesoHistoricoAsync.when(
              loading:
                  () => FxLoading.sectionShimmer(
                    context,
                    height: 72,
                    showHeader: false,
                  ),
              error:
                  (_, __) => InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap:
                        () => context.push(
                          '/alunos/$alunoId/evolucao',
                          extra: aluno.nome,
                        ),
                    child: _EmptyMiniState(
                      icon: Icons.show_chart_rounded,
                      text: 'Abrir evolução de peso',
                      isDark: isDark,
                    ),
                  ),
              data: (series) {
                final weightSeries = _resolveWeightSeries(series, aluno.peso);
                if (weightSeries.isEmpty) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap:
                        () => context.push(
                          '/alunos/$alunoId/evolucao',
                          extra: aluno.nome,
                        ),
                    child: _EmptyMiniState(
                      icon: Icons.monitor_weight_outlined,
                      text: 'Registrar primeira medida',
                      isDark: isDark,
                    ),
                  );
                }
                final delta =
                    weightSeries.length >= 2
                        ? weightSeries.last - weightSeries.first
                        : 0.0;
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap:
                      () => context.push(
                        '/alunos/$alunoId/evolucao',
                        extra: aluno.nome,
                      ),
                  child: _WeightTrendSparkline(
                    values: weightSeries,
                    deltaKg: delta,
                    color: trendColor,
                    trackColor: primary.withValues(alpha: isDark ? 0.18 : 0.12),
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

List<double> _resolveWeightSeries(List<double> avaliacoes, double? currentPeso) {
  if (avaliacoes.isNotEmpty) return avaliacoes;
  if (currentPeso == null) return const [];
  return [currentPeso, currentPeso];
}

class _WeightTrendSparkline extends StatelessWidget {
  const _WeightTrendSparkline({
    required this.values,
    required this.deltaKg,
    required this.color,
    required this.trackColor,
    required this.isDark,
  });

  final List<double> values;
  final double deltaKg;
  final Color color;
  final Color trackColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final deltaLabel =
        deltaKg.abs() < 0.05
            ? 'Estável'
            : '${deltaKg > 0 ? '+' : ''}${deltaKg.toStringAsFixed(1)} kg';
    final deltaColor =
        deltaKg.abs() < 0.05
            ? mute
            : deltaKg < 0
                ? EagleTokens.good
                : EagleTokens.warn;

    return Semantics(
      label:
          'Tendência de peso com ${values.length} medições. Variação $deltaLabel',
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Histórico de avaliações',
                    style: TextStyle(
                      color: mute,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  deltaLabel,
                  style: TextStyle(
                    color: deltaColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return FxSparkline(
                    data: values.length >= 2 ? values : [values.first, values.first],
                    color: color,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    strokeWidth: 2.2,
                    fill: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
