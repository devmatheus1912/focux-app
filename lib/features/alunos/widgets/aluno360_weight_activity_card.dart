import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import 'aluno360_empty_mini_state.dart';

List<double> resolveWeightSeriesForAluno(
  List<double> avaliacoes,
  double? currentPeso,
) {
  if (avaliacoes.isNotEmpty) return avaliacoes;
  if (currentPeso == null) return const [];
  return [currentPeso, currentPeso];
}

class Aluno360WeightActivityCard extends ConsumerWidget {
  const Aluno360WeightActivityCard({
    super.key,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PESO · TENDÊNCIA',
                      style: Aluno360Layout.metaStyle(context).copyWith(
                        color:
                            isDark
                                ? EagleTokens.darkInkMute
                                : TokensStrip.textSecondary,
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
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  aluno.peso == null
                      ? 'Sem medida registrada'
                      : 'Ver evolução completa',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Aluno360Layout.captionStyle(context).copyWith(
                    color:
                        isDark
                            ? EagleTokens.darkInkMute
                            : TokensStrip.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
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
                    child: Aluno360EmptyMiniState(
                      icon: Icons.show_chart_rounded,
                      text: 'Abrir evolução de peso',
                      isDark: isDark,
                    ),
                  ),
              data: (series) {
                final weightSeries = resolveWeightSeriesForAluno(
                  series,
                  aluno.peso,
                );
                if (weightSeries.isEmpty) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap:
                        () => context.push(
                          '/alunos/$alunoId/evolucao',
                          extra: aluno.nome,
                        ),
                    child: Aluno360EmptyMiniState(
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
                  child: Aluno360WeightTrendSparkline(
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

class Aluno360WeightTrendSparkline extends StatelessWidget {
  const Aluno360WeightTrendSparkline({
    super.key,
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
