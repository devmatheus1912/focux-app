import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';

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

  void _openEvolucao(BuildContext context) {
    context.push('/alunos/$alunoId/evolucao', extra: aluno.nome);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pesoHistoricoAsync = ref.watch(alunoPesoHistoricoProvider(alunoId));
    final primary = Theme.of(context).colorScheme.primary;
    final trendColor = primary;
    final caption =
        aluno.peso == null
            ? 'Nenhuma avaliação ainda'
            : 'Última medida registrada';

    return Semantics(
      container: true,
      label: 'Peso e tendência corporal',
      child: FxSettingsGroup(
        header: 'Peso · tendência',
        caption: caption,
        accent: primary,
        children: [
          FxSettingsTile(
            icon: Icons.monitor_weight_outlined,
            label: 'Peso atual',
            subtitle:
                hasRadarP0 && aluno.peso == null
                    ? 'Radar pede mapa corporal (P0)'
                    : null,
            value:
                aluno.peso == null
                    ? '—'
                    : '${aluno.peso!.toStringAsFixed(1)} kg',
            numeric: aluno.peso != null,
            onTap: () => _openEvolucao(context),
          ),
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
                (_, __) => FxSettingsTile(
                  icon: Icons.history_rounded,
                  label: 'Histórico de medições',
                  subtitle: 'Não foi possível carregar agora',
                  value: '',
                  onTap: () => _openEvolucao(context),
                ),
            data: (series) {
              final weightSeries = resolveWeightSeriesForAluno(
                series,
                aluno.peso,
              );
              if (weightSeries.isEmpty) {
                return FxSettingsTile(
                  icon: Icons.add_chart_outlined,
                  label: 'Registrar primeira medida',
                  subtitle:
                      hasRadarP0
                          ? 'Mapa corporal (P0) pendente no radar'
                          : 'Abrir evolução corporal',
                  value: '',
                  showDivider: false,
                  onTap: () => _openEvolucao(context),
                );
              }
              final delta =
                  weightSeries.length >= 2
                      ? weightSeries.last - weightSeries.first
                      : 0.0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                    child: Semantics(
                      button: true,
                      label: 'Abrir histórico de medições corporais',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _openEvolucao(context),
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
                  ),
                  FxSettingsTile(
                    icon: Icons.straighten_outlined,
                    label: 'Ver radar e medidas',
                    subtitle: 'Evolução corporal completa',
                    value: '',
                    showDivider: false,
                    onTap: () => _openEvolucao(context),
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
