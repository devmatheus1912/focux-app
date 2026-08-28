import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_evolucao_inteligente_logic.dart';
import 'aluno360_action_empty_panel.dart';
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

  void _openTreinos(BuildContext context) {
    context.push('/alunos/$alunoId/treinos-list', extra: alunoNome);
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
            child: FxSettingsGroup(
              header: 'Evolução inteligente',
              helpTooltip: 'Ajuda sobre evolução inteligente',
              onHelpTap: () => showAluno360EvolucaoInteligenteHelpSheet(context),
              accent: primary,
              children: [
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
            child: FxSettingsGroup(
              header: 'Evolução inteligente',
              caption: friendlyError(
                e,
                fallback: 'Evolução inteligente indisponível.',
              ),
              helpTooltip: 'Ajuda sobre evolução inteligente',
              onHelpTap: () => showAluno360EvolucaoInteligenteHelpSheet(context),
              accent: primary,
              children: const [SizedBox.shrink()],
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

        return Semantics(
          container: true,
          label: 'Evolução inteligente, sinal ${sinalLabel(ev.sinal)}',
          child: FxSettingsGroup(
            header: 'Evolução inteligente',
            helpTooltip: 'Ajuda sobre evolução inteligente',
            onHelpTap: () => showAluno360EvolucaoInteligenteHelpSheet(context),
            accent: primary,
            children: [
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Aluno360ActionEmptyPanel(
                                  key: const ValueKey(
                                    'aluno360_evolucao_empty',
                                  ),
                                  compact: true,
                                  icon: Icons.hourglass_empty_rounded,
                                  title: 'Sem sinais de evolução ainda',
                                  subtitle:
                                      timelineHasSignals
                                          ? '$firstName já tem interações na linha do tempo abaixo. '
                                              'Peça um check-in para liberar o gráfico de volume.'
                                          : 'Peça um check-in a $firstName ou revise o treino '
                                              'para começar a formar o histórico.',
                                  primaryLabel: 'Pedir check-in',
                                  primaryIcon: Icons.message_outlined,
                                  onPrimary: () => _openCheckinMessage(context),
                                  secondaryActions: [
                                    Aluno360SecondaryAction(
                                      label: 'Abrir chat',
                                      icon: Icons.chat_bubble_outline,
                                      onTap:
                                          () => context.push(
                                            '/alunos/$alunoId/chat',
                                            extra: alunoNome,
                                          ),
                                    ),
                                    if (!timelineHasSignals)
                                      Aluno360SecondaryAction(
                                        label: 'Ver treinos',
                                        icon: Icons.fitness_center_rounded,
                                        onTap: () => _openTreinos(context),
                                      ),
                                  ],
                                ),
                              ),
                              if (hasRadarP0 && !timelineHasSignals)
                                FxSettingsTile(
                                  icon: Icons.radar_outlined,
                                  accent: EagleTokens.warn,
                                  label: 'Radar pede mapa corporal',
                                  subtitle: 'Prioridade P0 na evolução corporal',
                                  value: 'P0',
                                  showDivider: false,
                                  onTap:
                                      () => context.push(
                                        '/alunos/$alunoId/evolucao',
                                        extra: alunoNome,
                                      ),
                                ),
                            ],
                          ),
                        )
                        : KeyedSubtree(
                          key: ValueKey('evolucao_${ev.sinal}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FxSettingsTile(
                                icon: Icons.insights_outlined,
                                accent: sigColor,
                                label: 'Sinal de evolução',
                                subtitle: ev.resumo,
                                value: sinalLabel(ev.sinal),
                                onTap: () => _openTreinos(context),
                              ),
                              if (sparklineData.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    4,
                                    0,
                                    8,
                                  ),
                                  child: _VolumeSparklineRow(
                                    data: sparklineData,
                                    color: sigColor,
                                    singleWeek: singleWeek,
                                    mute: mute,
                                  ),
                                ),
                              ],
                              FxSettingsTile(
                                icon: Icons.bar_chart_rounded,
                                label: 'Volume semanal',
                                value: ev.volumeSemanal.toStringAsFixed(0),
                                numeric: true,
                                onTap: () => _openTreinos(context),
                              ),
                              FxSettingsTile(
                                icon: Icons.calendar_month_outlined,
                                label: 'Volume mensal',
                                value: ev.volumeMensal.toStringAsFixed(0),
                                numeric: true,
                                onTap: () => _openTreinos(context),
                              ),
                              if (ev.tendenciaVolumePct != null)
                                FxSettingsTile(
                                  icon: Icons.trending_up_rounded,
                                  accent:
                                      ev.tendenciaVolumePct! >= 0
                                          ? EagleTokens.good
                                          : EagleTokens.bad,
                                  label: 'Tendência de volume',
                                  value:
                                      '${ev.tendenciaVolumePct! > 0 ? '+' : ''}${ev.tendenciaVolumePct}%',
                                  numeric: true,
                                  onTap: () => _openTreinos(context),
                                ),
                              if (ev.ultimoPrExercicio != null &&
                                  ev.ultimoPrExercicio!.isNotEmpty)
                                FxSettingsTile(
                                  icon: Icons.emoji_events_outlined,
                                  accent: EagleTokens.good,
                                  label:
                                      ev.ultimoPrLabel != null &&
                                              ev.ultimoPrLabel!.isNotEmpty
                                          ? 'Recorde · ${ev.ultimoPrLabel}'
                                          : 'Recorde recente',
                                  subtitle: ev.ultimoPrExercicio,
                                  value: '',
                                  onTap: () => _openTreinos(context),
                                ),
                              FxSettingsTile(
                                icon: Icons.flag_outlined,
                                label: 'Próxima ação',
                                subtitle: ev.proximaAcao,
                                value: '',
                                onTap: () => _openTreinos(context),
                              ),
                              FxSettingsTile(
                                icon: Icons.fitness_center_rounded,
                                label: 'Ajustar treino',
                                subtitle: 'Revisar carga e exercícios',
                                value: '',
                                onTap: () => _openTreinos(context),
                              ),
                              if (ev.sugerirCopiloto && onOpenCopilot != null)
                                FxSettingsTile(
                                  icon: Icons.auto_awesome,
                                  label: 'Abrir Copiloto',
                                  subtitle:
                                      'Transforme a próxima ação em mensagem',
                                  value: '',
                                  showDivider: false,
                                  onTap: onOpenCopilot!,
                                ),
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

class _VolumeSparklineRow extends StatelessWidget {
  const _VolumeSparklineRow({
    required this.data,
    required this.color,
    required this.singleWeek,
    required this.mute,
  });

  final List<double> data;
  final Color color;
  final bool singleWeek;
  final Color mute;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Volume semanal',
                  style: Aluno360Layout.metaStyle(context).copyWith(
                    color: mute,
                    letterSpacing: 0.4,
                  ),
                ),
                if (singleWeek) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Primeira semana com volume',
                    style: Aluno360Layout.captionStyle(context).copyWith(
                      color: mute,
                    ),
                  ),
                ],
              ],
            ),
          ),
          FxSparkline(
            data: data,
            color: color,
            width: 88,
            height: 28,
          ),
        ],
      ),
    );
  }
}
