import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import 'aluno360_help_sheets.dart';

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
    this.suppressRadarHint = false,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color ink;
  final bool hasRadarP0;
  final bool suppressRadarHint;

  void _openComparativo(BuildContext context) {
    context.push('/alunos/$alunoId/evolucao-comparativo', extra: aluno.nome);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pesoHistoricoAsync = ref.watch(alunoPesoHistoricoProvider(alunoId));
    final primary = Theme.of(context).colorScheme.primary;
    final showRadarHint = hasRadarP0 && !suppressRadarHint && aluno.peso == null;

    return Semantics(
      container: true,
      label: 'Peso e tendência corporal',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(
            title: 'Peso · tendência',
            actionLabel: 'Ajuda',
            onAction: () => showAluno360PesoHelpSheet(context),
          ),
          const SizedBox(height: TokensStrip.s3),
          InkWell(
            onTap: () => _openComparativo(context),
            borderRadius: BorderRadius.circular(12),
            child: OperationalMetricTile(
              label: 'Peso atual',
              value:
                  aluno.peso == null
                      ? '—'
                      : '${aluno.peso!.toStringAsFixed(1)} kg',
              hint:
                  showRadarHint
                      ? 'Mapa corporal pendente no radar'
                      : 'Toque para abrir o comparativo',
              color: primary,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
          pesoHistoricoAsync.when(
            loading:
                () => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: FxLoading.sectionShimmer(
                    context,
                    height: 72,
                    showHeader: false,
                  ),
                ),
            error:
                (_, __) => Align(
                  alignment: Alignment.centerLeft,
                  child: DashboardHomeActionChip(
                    label: 'Tentar histórico',
                    accent: primary,
                    isDark: isDark,
                    onPressed: () => _openComparativo(context),
                  ),
                ),
            data: (series) {
              final weightSeries = resolveWeightSeriesForAluno(
                series,
                aluno.peso,
              );
              if (weightSeries.isEmpty) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: DashboardHomeActionChip(
                    label: 'Registrar primeira medida',
                    accent: primary,
                    isDark: isDark,
                    onPressed: () => _openComparativo(context),
                  ),
                );
              }
              final delta =
                  weightSeries.length >= 2
                      ? weightSeries.last - weightSeries.first
                      : 0.0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    button: true,
                    label: 'Abrir histórico de medições corporais',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _openComparativo(context),
                      child:               Aluno360WeightTrendSparkline(
                        values: weightSeries,
                        deltaKg: delta,
                        color: primary,
                        ink: ink,
                        trackColor: primary.withValues(
                          alpha: isDark ? 0.18 : 0.12,
                        ),
                        isDark: isDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  Wrap(
                    spacing: TokensStrip.s2,
                    runSpacing: TokensStrip.s2,
                    children: [
                      DashboardHomeActionChip(
                        label: 'Registrar medida',
                        accent: primary,
                        isDark: isDark,
                        onPressed: () => _openComparativo(context),
                      ),
                      if (showRadarHint)
                        DashboardHomeActionChip(
                          label: 'Radar corporal',
                          accent: EagleTokens.warn,
                          isDark: isDark,
                          onPressed: () => _openComparativo(context),
                        ),
                    ],
                  ),
                ],
              );
            },
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
    required this.ink,
    required this.trackColor,
    required this.isDark,
  });

  final List<double> values;
  final double deltaKg;
  final Color color;
  final Color ink;
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
                    ).copyWith(color: ink.withValues(alpha: 0.72), fontWeight: FontWeight.w600),
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
            SizedBox(
              height: 36,
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
