import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../../dashboard/utils/aluno_volume_format.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_evolucao_inteligente_logic.dart';
import 'aluno360_help_sheets.dart';
import 'aluno_outreach_message_sheet.dart';

class Aluno360EvolucaoInteligenteCard extends StatelessWidget {
  const Aluno360EvolucaoInteligenteCard({
    super.key,
    required this.alunoId,
    required this.alunoNome,
    required this.evolucaoAsync,
    required this.isDark,
    this.onOpenCopilot,
    this.timelineHasSignals = false,
    this.hasRadarP0 = false,
  });

  final int alunoId;
  final String alunoNome;
  final AsyncValue<EvolucaoInteligente> evolucaoAsync;
  final bool isDark;
  final VoidCallback? onOpenCopilot;
  final bool timelineHasSignals;
  final bool hasRadarP0;

  static String sinalLabel(String s) {
    switch (s) {
      case 'SUBINDO':
        return 'Em alta';
      case 'ESTÁVEL':
        return 'Estável';
      case 'PLATÔ':
        return 'Platô';
      case 'QUEDA':
        return 'Volume em queda';
      case 'SEM_DADOS':
      default:
        return 'Sem histórico ainda';
    }
  }

  static Color sinalColor(
    String s, {
    required bool isDark,
    required Color ink,
  }) {
    switch (s) {
      case 'SUBINDO':
        return EagleTokens.good;
      case 'QUEDA':
        return EagleTokens.bad;
      case 'PLATÔ':
        return EagleTokens.warn;
      case 'ESTÁVEL':
        return isDark ? EagleTokens.darkInkMute : EagleTokens.inkGray;
      default:
        return isDark ? EagleTokens.darkInkMute : EagleTokens.inkGray;
    }
  }

  void _openCheckinMessage(BuildContext context) {
    showAlunoCheckinMessageSheet(
      context,
      alunoId: alunoId,
      alunoNome: alunoNome,
    );
  }

  static String? _ultimoPrValue(EvolucaoInteligente ev) {
    final label = ev.ultimoPrLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    final carga = ev.ultimoPrCargaKg;
    if (carga == null || carga <= 0) return null;
    final formatted =
        carga == carga.roundToDouble()
            ? carga.toStringAsFixed(0)
            : carga.toStringAsFixed(1).replaceAll('.', ',');
    return '$formatted kg';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final mute = fxScreenMute(context);
    final firstName = alunoNome.split(' ').first;
    final refreshing = evolucaoAsync.isRefreshing && evolucaoAsync.hasValue;

    return evolucaoAsync.when(
      loading:
          () => Semantics(
            container: true,
            label: 'Evolução inteligente, carregando',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardSectionHeader(
                  title: 'Evolução inteligente',
                  actionLabel: 'Ajuda',
                  onAction:
                      () => showAluno360EvolucaoInteligenteHelpSheet(context),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: FxLoading.sectionShimmer(context, height: 160),
                ),
              ],
            ),
          ),
      error:
          (e, _) => Semantics(
            container: true,
            label: 'Evolução inteligente indisponível',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardSectionHeader(
                  title: 'Evolução inteligente',
                  actionLabel: 'Ajuda',
                  onAction:
                      () => showAluno360EvolucaoInteligenteHelpSheet(context),
                ),
                const SizedBox(height: 4),
                Text(
                  friendlyError(
                    e,
                    fallback: 'Evolução inteligente indisponível.',
                  ),
                  style: Aluno360Layout.metaStyle(context).copyWith(color: mute),
                ),
              ],
            ),
          ),
      data: (ev) {
        final sigColor = sinalColor(ev.sinal, isDark: isDark, ink: fxScreenInk(context));
        final isEmptySignal = ev.sinal == 'SEM_DADOS';
        final sparklineData =
            Aluno360EvolucaoInteligenteLogic.resolveVolumeSparklineData(
              ev.volumePorSemana,
            );
        final singleWeek = Aluno360EvolucaoInteligenteLogic.isSingleWeekVolume(
          ev.volumePorSemana,
        );
        final hideMonthlyVolume =
            Aluno360EvolucaoInteligenteLogic.isRedundantWeeklyMonthlyVolume(
              volumeSemanal: ev.volumeSemanal,
              volumeMensal: ev.volumeMensal,
              singleWeek: singleWeek,
            );

        return Semantics(
          container: true,
          label: 'Evolução inteligente, sinal ${sinalLabel(ev.sinal)}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardSectionHeader(
                title: 'Evolução inteligente',
                actionLabel: 'Ajuda',
                onAction:
                    () => showAluno360EvolucaoInteligenteHelpSheet(context),
              ),
              if (isEmptySignal) ...[
                const SizedBox(height: 4),
                Text(
                  timelineHasSignals
                      ? '$firstName já aparece na linha do tempo. '
                          'Peça um check-in para liberar volume e tendência.'
                      : 'Peça um check-in a $firstName para começar '
                          'a montar volume, tendência e próximos passos.',
                  style: Aluno360Layout.metaStyle(context).copyWith(color: mute),
                ),
              ],
              const SizedBox(height: TokensStrip.s3),
              if (refreshing) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: primary.withValues(alpha: 0.12),
                      color: primary,
                    ),
                  ),
                ),
              ],
              AnimatedSwitcher(
                duration: Duration(milliseconds: fxMotionDurationMs(context)),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child:
                    isEmptySignal
                        ? KeyedSubtree(
                          key: const ValueKey('evolucao_empty'),
                          child: Column(
                            key: const ValueKey('aluno360_evolucao_empty'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                spacing: TokensStrip.s2,
                                runSpacing: TokensStrip.s2,
                                children: [
                                  FxActionChip(
                                    label:
                                        hasRadarP0 && !timelineHasSignals
                                            ? 'Radar corporal'
                                            : 'Pedir check-in',
                                    accent:
                                        hasRadarP0 && !timelineHasSignals
                                            ? EagleTokens.warn
                                            : primary,
                                    isDark: isDark,
                                    onPressed:
                                        () =>
                                            hasRadarP0 && !timelineHasSignals
                                                ? context.push(
                                                  '/alunos/$alunoId/evolucao-comparativo',
                                                  extra: alunoNome,
                                                )
                                                : _openCheckinMessage(context),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                        : KeyedSubtree(
                          key: ValueKey('evolucao_${ev.sinal}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                spacing: TokensStrip.s2,
                                runSpacing: TokensStrip.s2,
                                children: [
                                  _EvolucaoMetricChip(
                                    label: sinalLabel(ev.sinal),
                                    color: sigColor,
                                  ),
                                  _EvolucaoMetricChip(
                                    label:
                                        hideMonthlyVolume
                                            ? formatAlunoVolumeKg(
                                              ev.volumeSemanal,
                                            )
                                            : '${formatAlunoVolumeKg(ev.volumeSemanal)} sem.',
                                    color: primary,
                                  ),
                                  if (_ultimoPrValue(ev) != null)
                                    _EvolucaoMetricChip(
                                      label: 'PR ${_ultimoPrValue(ev)!}',
                                      color: primary,
                                    ),
                                ],
                              ),
                              if (Aluno360EvolucaoInteligenteLogic.composeSinalHint(
                                    resumo: ev.resumo,
                                    tendenciaPct: ev.tendenciaVolumePct,
                                  )
                                  case final hint?) ...[
                                const SizedBox(height: TokensStrip.s2),
                                Text(
                                  hint,
                                  style: Aluno360Layout.metaStyle(context)
                                      .copyWith(color: mute),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ] else if (ev.resumo.trim().isNotEmpty) ...[
                                const SizedBox(height: TokensStrip.s2),
                                Text(
                                  ev.resumo,
                                  style: Aluno360Layout.metaStyle(context)
                                      .copyWith(color: mute),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (sparklineData.isNotEmpty) ...[
                                const SizedBox(height: TokensStrip.s2),
                                _VolumeSparklineRow(
                                  data: sparklineData,
                                  color: sigColor,
                                  singleWeek: singleWeek,
                                  mute: mute,
                                  volumeLabel: formatAlunoVolumeKg(
                                    ev.volumeSemanal,
                                  ),
                                ),
                              ],
                              if (ev.proximaAcao.trim().isNotEmpty) ...[
                                const SizedBox(height: TokensStrip.s3),
                                Text(
                                  ev.proximaAcao,
                                  style: Aluno360Layout.metaStyle(context)
                                      .copyWith(color: mute),
                                ),
                              ],
                              if (ev.sugerirCopiloto &&
                                  onOpenCopilot != null) ...[
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: onOpenCopilot,
                                    style: Aluno360Layout.secondaryTextLinkStyle(
                                      context,
                                    ),
                                    child: const Text('Abrir Copiloto'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EvolucaoMetricChip extends StatelessWidget {
  const _EvolucaoMetricChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TokensStrip.s3,
        vertical: TokensStrip.s2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TokensStrip.rPill),
      ),
      child: Text(label, style: FocuxHubTypography.chip(color)),
    );
  }
}

class _VolumeSparklineRow extends StatelessWidget {
  const _VolumeSparklineRow({
    required this.data,
    required this.color,
    required this.singleWeek,
    required this.mute,
    this.volumeLabel,
  });

  final List<double> data;
  final Color color;
  final bool singleWeek;
  final Color mute;
  final String? volumeLabel;

  @override
  Widget build(BuildContext context) {
    final minVol = data.reduce((a, b) => a < b ? a : b);
    final maxVol = data.reduce((a, b) => a > b ? a : b);
    return Semantics(
      label:
          singleWeek
              ? 'Primeira semana com volume registrado'
              : 'Tendência de volume nas últimas semanas, '
                  'de ${minVol.toStringAsFixed(0)} a ${maxVol.toStringAsFixed(0)}',
      child: Row(
        children: [
          Expanded(
            child: Text(
              singleWeek
                  ? '${volumeLabel ?? 'Volume'} · 1ª semana'
                  : 'Volume · semanas',
              style: Aluno360Layout.metaStyle(context).copyWith(
                color: mute,
                letterSpacing: 0.2,
                fontSize: 11.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Um ponto só vira barra órfã — caption basta na 1ª semana.
          if (!singleWeek && data.length >= 2)
            FxSparkline(
              data: data,
              color: color,
              width: 72,
              height: 24,
            ),
        ],
      ),
    );
  }
}
