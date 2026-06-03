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
    final aderenciaAsync = ref.watch(alunoAderenciaSemanalProvider(alunoId));
    final primary = Theme.of(context).colorScheme.primary;

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
                    'PESO · ÚLTIMAS 7 SEMANAS',
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
            child: aderenciaAsync.when(
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
              data: (semana) {
                if (semana.isEmpty && aluno.peso == null) {
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
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap:
                      () => context.push(
                        '/alunos/$alunoId/evolucao',
                        extra: aluno.nome,
                      ),
                  child: _WeeklyActivitySparkline(
                    values:
                        semana
                            .map(
                              (e) =>
                                  (e['checkins'] as num?)?.toDouble() ?? 0.0,
                            )
                            .toList(growable: false),
                    color: EagleTokens.aderenciaColor(
                      (aluno.aderenciaPercent ?? 0).toDouble(),
                      isDark: isDark,
                    ),
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

class _WeeklyActivitySparkline extends StatelessWidget {
  const _WeeklyActivitySparkline({
    required this.values,
    required this.color,
    required this.trackColor,
    required this.isDark,
  });

  final List<double> values;
  final Color color;
  final Color trackColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final maxValue = values.fold<double>(0, (p, v) => v > p ? v : p);
    final effectiveMax = maxValue <= 0 ? 1.0 : maxValue;

    return Semantics(
      label: 'Atividade dos últimos ${values.length} dias',
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
            Text(
              'Check-ins por dia',
              style: TextStyle(
                color: mute,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < values.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final heightFactor = (values[i] / effectiveMax).clamp(
                            0.08,
                            1.0,
                          );
                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              width: double.infinity,
                              height: constraints.maxHeight * heightFactor,
                              decoration: BoxDecoration(
                                color:
                                    values[i] > 0
                                        ? color
                                        : color.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

