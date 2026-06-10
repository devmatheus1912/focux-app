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
import 'aluno360_section_header.dart';

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
    this.hasRadarP0 = false,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color ink;
  final bool hasRadarP0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pesoHistoricoAsync = ref.watch(alunoPesoHistoricoProvider(alunoId));
    final primary = Theme.of(context).colorScheme.primary;
    final mute = fxScreenMute(context);
    final trendColor = primary;
    final subtitle =
        aluno.peso == null
            ? 'Nenhuma avaliação ainda'
            : 'Última medida registrada';

    return Semantics(
      container: true,
      label: 'Peso e tendência corporal',
      child: Container(
        decoration: Aluno360Layout.operacaoInsetSectionDecoration(
          context,
          primary: primary,
          isDark: isDark,
        ),
        padding: const EdgeInsets.all(Aluno360Layout.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Aluno360SectionHeader(
              icon: Icons.monitor_weight_outlined,
              title: 'Peso · tendência',
              subtitle: subtitle,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
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
                    style: Aluno360Layout.inlineMetricStyle(
                      context,
                      ink,
                    ).copyWith(fontSize: 32, letterSpacing: -0.5, height: 1),
                  ),
                  if (aluno.peso != null) ...[
                    const SizedBox(width: 3),
                    Text(
                      'kg',
                      style: Aluno360Layout.captionStyle(
                        context,
                      ).copyWith(color: mute, fontWeight: FontWeight.w500),
                    ),
                  ],
                  const Spacer(),
                  if (aluno.peso != null)
                    Semantics(
                      button: true,
                      label: 'Ver radar e medidas corporais',
                      child: InkWell(
                        onTap:
                            () => context.push(
                              '/alunos/$alunoId/evolucao',
                              extra: aluno.nome,
                            ),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            'Ver radar e medidas',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: Aluno360Layout.chipLabelStyle(
                              context,
                              color: Aluno360Layout.timelineLinkForeground(
                                primary,
                                isDark: isDark,
                              ),
                            ).copyWith(decoration: TextDecoration.underline),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            pesoHistoricoAsync.when(
              loading:
                  () => SizedBox(
                    height: 72,
                    child: FxLoading.sectionShimmer(
                      context,
                      height: 72,
                      showHeader: false,
                    ),
                  ),
              error:
                  (_, __) => SizedBox(
                    height: 72,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap:
                          () => context.push(
                            '/alunos/$alunoId/evolucao',
                            extra: aluno.nome,
                          ),
                      child: Aluno360EmptyMiniState(
                        icon: Icons.monitor_weight_outlined,
                        text: 'Abrir avaliações corporais',
                        isDark: isDark,
                      ),
                    ),
                  ),
              data: (series) {
                final weightSeries = resolveWeightSeriesForAluno(
                  series,
                  aluno.peso,
                );
                if (weightSeries.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 72,
                        child: InkWell(
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
                            semanticsLabel:
                                'Registrar primeira medida na evolução corporal',
                          ),
                        ),
                      ),
                      if (hasRadarP0) ...[
                        const SizedBox(height: 8),
                        Text(
                          'O radar também pede mapa corporal (P0) — '
                          'registre peso e medidas na evolução corporal.',
                          style: Aluno360Layout.captionStyle(
                            context,
                          ).copyWith(color: mute, height: 1.35),
                        ),
                      ],
                    ],
                  );
                }
                final delta =
                    weightSeries.length >= 2
                        ? weightSeries.last - weightSeries.first
                        : 0.0;
                return SizedBox(
                  height: 72,
                  child: Semantics(
                    button: true,
                    label: 'Abrir histórico de medições corporais',
                    child: InkWell(
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
                        trackColor: primary.withValues(
                          alpha: isDark ? 0.18 : 0.12,
                        ),
                        isDark: isDark,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
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
                    'Últimas medições',
                    style: Aluno360Layout.captionStyle(
                      context,
                    ).copyWith(color: mute, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  deltaLabel,
                  style: Aluno360Layout.captionStyle(
                    context,
                  ).copyWith(color: deltaColor, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return FxSparkline(
                    data:
                        values.length >= 2
                            ? values
                            : [values.first, values.first],
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
