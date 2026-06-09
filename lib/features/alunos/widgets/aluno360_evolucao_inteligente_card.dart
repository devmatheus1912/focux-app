import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_evolucao_inteligente_logic.dart';
import 'aluno360_action_empty_panel.dart';
import 'aluno360_mini_autonomy_chip.dart';
import 'aluno360_section_header.dart';
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

  static Color sinalColor(String s, {required bool isDark, required Color ink}) {
    switch (s) {
      case 'SUBINDO':
        return EagleTokens.good;
      case 'QUEDA':
        return EagleTokens.bad;
      case 'PLATÔ':
        return EagleTokens.warn;
      case 'ESTÁVEL':
        return isDark ? EagleTokens.darkInkMute : const Color(0xFF4B5563);
      default:
        return isDark ? EagleTokens.darkInkMute : const Color(0xFF4B5563);
    }
  }

  void _openCheckinMessage(BuildContext context) {
    showAlunoCheckinMessageSheet(
      context,
      alunoId: alunoId,
      alunoNome: alunoNome,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final firstName = alunoNome.split(' ').first;

    final refreshing = evolucaoAsync.isRefreshing && evolucaoAsync.hasValue;

    return evolucaoAsync.when(
      loading:
          () => Semantics(
            container: true,
            label: 'Evolução inteligente, carregando',
            child: _cardShell(
              context,
              primary: primary,
              child: FxLoading.sectionShimmer(context, height: 160),
            ),
          ),
      error:
          (e, _) => Semantics(
            container: true,
            label: 'Evolução inteligente indisponível',
            child: _cardShell(
              context,
              primary: primary,
              child: Text(
                friendlyError(
                  e,
                  fallback: 'Evolução inteligente indisponível.',
                ),
                style: Aluno360Layout.captionStyle(context).copyWith(
                  color: mute,
                ),
              ),
            ),
          ),
      data: (ev) {
        final sigColor = sinalColor(ev.sinal, isDark: isDark, ink: ink);
        final isEmptySignal = ev.sinal == 'SEM_DADOS';
        final sparklineData =
            Aluno360EvolucaoInteligenteLogic.resolveVolumeSparklineData(
              ev.volumePorSemana,
            );
        final singleWeek =
            Aluno360EvolucaoInteligenteLogic.isSingleWeekVolume(
              ev.volumePorSemana,
            );

        return Semantics(
          container: true,
          label:
              'Evolução inteligente, sinal ${sinalLabel(ev.sinal)}',
          child: _cardShell(
            context,
            primary: primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (refreshing) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: primary.withValues(alpha: 0.12),
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Aluno360SectionHeader(
                  icon: Icons.insights_outlined,
                  title: 'Evolução inteligente',
                  subtitle: 'Sinais a partir de check-ins concluídos e volume.',
                  isDark: isDark,
                  trailingSemanticsLabel: sinalLabel(ev.sinal),
                  trailing: Aluno360MiniAutonomyChip(
                    label: sinalLabel(ev.sinal),
                    color: sigColor,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 14),
                if (isEmptySignal) ...[
                  Aluno360ActionEmptyPanel(
                    key: const ValueKey('aluno360_evolucao_empty'),
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
                          onTap:
                              () => context.push(
                                '/alunos/$alunoId/treinos-list',
                                extra: alunoNome,
                              ),
                        ),
                    ],
                  ),
                  if (hasRadarP0 && !timelineHasSignals) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            () => context.push(
                              '/alunos/$alunoId/evolucao',
                              extra: alunoNome,
                            ),
                        icon: const Icon(Icons.radar_outlined, size: 16),
                        label: const Text('Radar pede mapa corporal (P0)'),
                        style: Aluno360Layout.operacaoOutlinedButtonStyle(
                          context,
                          EagleTokens.warn,
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  Text(
                    ev.resumo,
                    style: Aluno360Layout.captionStyle(context).copyWith(
                      color: ink,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (sparklineData.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final minVol = sparklineData.reduce(
                          (a, b) => a < b ? a : b,
                        );
                        final maxVol = sparklineData.reduce(
                          (a, b) => a > b ? a : b,
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Volume semanal',
                                    style: Aluno360Layout.metaStyle(context)
                                        .copyWith(
                                          color: mute,
                                          letterSpacing: 0.4,
                                        ),
                                  ),
                                ),
                                Semantics(
                                  label:
                                      singleWeek
                                          ? 'Primeira semana com volume registrado'
                                          : 'Tendência de volume nas últimas semanas, '
                                              'de ${minVol.toStringAsFixed(0)} a '
                                              '${maxVol.toStringAsFixed(0)}',
                                  child: FxSparkline(
                                    data: sparklineData,
                                    color: sigColor,
                                    width: 88,
                                    height: 28,
                                  ),
                                ),
                              ],
                            ),
                            if (singleWeek) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Primeira semana com volume',
                                style: Aluno360Layout.captionStyle(context)
                                    .copyWith(color: mute),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Aluno360MiniAutonomyChip(
                        label:
                            'Volume semanal ${ev.volumeSemanal.toStringAsFixed(0)}',
                        color: primary,
                        isDark: isDark,
                      ),
                      Aluno360MiniAutonomyChip(
                        label:
                            'Volume mensal ${ev.volumeMensal.toStringAsFixed(0)}',
                        color: primary,
                        isDark: isDark,
                      ),
                      if (ev.tendenciaVolumePct != null)
                        Aluno360MiniAutonomyChip(
                          label:
                              'Tendência volume ${ev.tendenciaVolumePct! > 0 ? '+' : ''}${ev.tendenciaVolumePct}%',
                          color:
                              ev.tendenciaVolumePct! >= 0
                                  ? EagleTokens.good
                                  : EagleTokens.bad,
                          isDark: isDark,
                        ),
                      if (ev.ultimoPrExercicio != null &&
                          ev.ultimoPrExercicio!.isNotEmpty)
                        Aluno360MiniAutonomyChip(
                          label:
                              ev.ultimoPrLabel != null &&
                                      ev.ultimoPrLabel!.isNotEmpty
                                  ? 'Recorde · ${ev.ultimoPrLabel} · ${ev.ultimoPrExercicio}'
                                  : 'Recorde · ${ev.ultimoPrExercicio}',
                          color: EagleTokens.good,
                          isDark: isDark,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Próxima ação',
                    style: Aluno360Layout.metaStyle(context).copyWith(
                      color: mute,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ev.proximaAcao,
                    style: Aluno360Layout.captionStyle(context).copyWith(
                      color: ink,
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          () => context.push(
                            '/alunos/$alunoId/treinos-list',
                            extra: alunoNome,
                          ),
                      icon: const Icon(Icons.fitness_center_rounded, size: 16),
                      label: const Text('Ajustar treino'),
                      style: Aluno360Layout.operacaoOutlinedButtonStyle(
                        context,
                        primary,
                      ),
                    ),
                  ),
                  if (ev.sugerirCopiloto) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Transforme isso em mensagem no Copiloto.',
                      style: Aluno360Layout.captionStyle(context).copyWith(
                        color: mute,
                        height: 1.35,
                      ),
                    ),
                    if (onOpenCopilot != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: onOpenCopilot,
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('Abrir Copiloto'),
                          style: Aluno360Layout.operacaoOutlinedButtonStyle(
                            context,
                            primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cardShell(
    BuildContext context, {
    required Color primary,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(Aluno360Layout.cardPadding),
      decoration: Aluno360Layout.operacaoInsetSectionDecoration(
        context,
        primary: primary,
        isDark: isDark,
      ),
      child: child,
    );
  }
}
