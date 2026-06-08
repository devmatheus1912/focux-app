import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
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
  });

  final int alunoId;
  final String alunoNome;
  final AsyncValue<EvolucaoInteligente> evolucaoAsync;
  final bool isDark;
  final VoidCallback? onOpenCopilot;

  static String sinalLabel(String s) {
    switch (s) {
      case 'SUBINDO':
        return 'Em alta';
      case 'ESTÁVEL':
        return 'Estável';
      case 'PLATÔ':
        return 'Platô';
      case 'QUEDA':
        return 'Atenção';
      case 'SEM_DADOS':
      default:
        return 'Aguardando check-ins';
    }
  }

  static Color sinalColor(String s) {
    switch (s) {
      case 'SUBINDO':
        return EagleTokens.good;
      case 'QUEDA':
        return EagleTokens.bad;
      case 'PLATÔ':
        return EagleTokens.warn;
      default:
        return TokensStrip.textSecondary;
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

    return Semantics(
      container: true,
      label: 'Evolução inteligente, sinais de volume e tendência',
      child: Container(
      padding: const EdgeInsets.all(Aluno360Layout.cardPadding),
      decoration: Aluno360Layout.operacaoInsetSectionDecoration(
        context,
        primary: primary,
        isDark: isDark,
      ),
      child: evolucaoAsync.when(
        loading: () => FxLoading.sectionShimmer(context, height: 160),
        error:
            (e, _) => Text(
              friendlyError(e, fallback: 'Evolução inteligente indisponível.'),
              style: TextStyle(color: mute, fontSize: 12.5),
            ),
        data: (ev) {
          final sigColor = sinalColor(ev.sinal);
          final isEmptySignal = ev.sinal == 'SEM_DADOS';
          final sparklineData =
              ev.volumePorSemana.where((v) => v > 0).length >= 2
                  ? ev.volumePorSemana
                  : const <double>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Aluno360SectionHeader(
                icon: Icons.show_chart_rounded,
                title: 'Evolução inteligente',
                subtitle: 'Sinais a partir de check-ins concluídos e volume.',
                isDark: isDark,
                trailing: Aluno360MiniAutonomyChip(
                  label: sinalLabel(ev.sinal),
                  color: sigColor,
                ),
              ),
              const SizedBox(height: 14),
              if (isEmptySignal) ...[
                Aluno360ActionEmptyPanel(
                  key: const ValueKey('aluno360_evolucao_empty'),
                  icon: Icons.show_chart_rounded,
                  title: 'Sem sinais de evolução ainda',
                  subtitle:
                      'Peça um check-in ao aluno ou revise o treino para começar a formar o histórico.',
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
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Volume semanal',
                              style: Aluno360Layout.metaStyle(context).copyWith(
                                color: mute,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          Semantics(
                            label:
                                'Tendência de volume nas últimas semanas, '
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
                          'Vol. semanal ${ev.volumeSemanal.toStringAsFixed(0)}',
                      color: primary,
                    ),
                    Aluno360MiniAutonomyChip(
                      label:
                          'Vol. mensal ${ev.volumeMensal.toStringAsFixed(0)}',
                      color: primary,
                    ),
                    if (ev.tendenciaVolumePct != null)
                      Aluno360MiniAutonomyChip(
                        label:
                            'Tendência volume ${ev.tendenciaVolumePct! > 0 ? '+' : ''}${ev.tendenciaVolumePct}%',
                        color:
                            ev.tendenciaVolumePct! >= 0
                                ? EagleTokens.good
                                : EagleTokens.bad,
                      ),
                    if (ev.ultimoPrExercicio != null &&
                        ev.ultimoPrExercicio!.isNotEmpty)
                      Aluno360MiniAutonomyChip(
                        label:
                            ev.ultimoPrLabel != null &&
                                    ev.ultimoPrLabel!.isNotEmpty
                                ? '${ev.ultimoPrLabel} · ${ev.ultimoPrExercicio}'
                                : 'PR · ${ev.ultimoPrExercicio}',
                        color: EagleTokens.good,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Próxima ação',
                  style: Aluno360Layout.metaStyle(context).copyWith(
                    color: mute,
                    fontWeight: FontWeight.w800,
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
                    'Copiloto pode ajudar a transformar isso em mensagem ou tarefa.',
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
          );
        },
      ),
    ),
    );
  }
}
