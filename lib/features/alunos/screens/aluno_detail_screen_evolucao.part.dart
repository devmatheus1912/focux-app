part of 'aluno_detail_screen.dart';

class _EvolucaoInteligenteCard extends StatelessWidget {
  final int alunoId;
  final String alunoNome;
  final AsyncValue<EvolucaoInteligente> evolucaoAsync;
  final bool isDark;

  const _EvolucaoInteligenteCard({
    required this.alunoId,
    required this.alunoNome,
    required this.evolucaoAsync,
    required this.isDark,
  });

  static String _sinalLabel(String s) {
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
        return 'Sem dados';
    }
  }

  static Color _sinalColor(String s) {
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

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context),
      child: evolucaoAsync.when(
        loading: () => FxLoading.sectionShimmer(context, height: 160),
        error:
            (e, _) => Text(
              friendlyError(e, fallback: 'Evolução inteligente indisponível.'),
              style: TextStyle(color: mute, fontSize: 12.5),
            ),
        data: (ev) {
          final sigColor = _sinalColor(ev.sinal);
          final isEmptySignal = ev.sinal == 'SEM_DADOS';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: BrandPalette.soft(primary, dark: isDark),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.show_chart_rounded,
                      color: primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evolução inteligente',
                          style: TextStyle(
                            color: ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Sinais a partir de check-ins concluídos e volume.',
                          style: TextStyle(color: mute, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  _MiniAutonomyChip(
                    label: _sinalLabel(ev.sinal),
                    color: sigColor,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (isEmptySignal) ...[
                _Aluno360ActionEmptyPanel(
                  key: const ValueKey('aluno360_evolucao_empty'),
                  icon: Icons.show_chart_rounded,
                  title: 'Sem sinais de evolução ainda',
                  subtitle:
                      'Peça um check-in ao aluno ou revise o treino para começar a formar o histórico.',
                  primaryLabel: 'Pedir check-in',
                  primaryIcon: Icons.message_outlined,
                  onPrimary: () => _openCheckinMessage(context),
                  secondaryActions: [
                    _Aluno360SecondaryAction(
                      label: 'Abrir chat',
                      icon: Icons.chat_bubble_outline,
                      onTap:
                          () => context.push(
                            '/alunos/$alunoId/chat',
                            extra: alunoNome,
                          ),
                    ),
                    _Aluno360SecondaryAction(
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
                style: TextStyle(color: ink, fontSize: 13.2, height: 1.35),
              ),
              const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniAutonomyChip(
                      label:
                          'Vol. semanal ${ev.volumeSemanal.toStringAsFixed(0)}',
                      color: primary,
                    ),
                    _MiniAutonomyChip(
                      label:
                          'Vol. mensal ${ev.volumeMensal.toStringAsFixed(0)}',
                      color: primary,
                    ),
                    if (ev.tendenciaVolumePct != null)
                      _MiniAutonomyChip(
                        label:
                            'Tendência volume ${ev.tendenciaVolumePct! > 0 ? '+' : ''}${ev.tendenciaVolumePct}%',
                        color:
                            ev.tendenciaVolumePct! >= 0
                                ? EagleTokens.good
                                : EagleTokens.bad,
                      ),
                    if (ev.ultimoPrExercicio != null &&
                        ev.ultimoPrExercicio!.isNotEmpty)
                      _MiniAutonomyChip(
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
                style: TextStyle(
                  color: mute,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ev.proximaAcao,
                style: TextStyle(color: ink, fontSize: 13, height: 1.3),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed:
                      () => context.push(
                        '/alunos/$alunoId/treinos-list',
                        extra: alunoNome,
                      ),
                  icon: const Icon(Icons.fitness_center_rounded, size: 16),
                  label: const Text('Ajustar treino'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary.withValues(alpha: 0.32)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),
              if (ev.sugerirCopiloto) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Copiloto pode ajudar a transformar isso em mensagem ou tarefa.',
                        style: TextStyle(color: mute, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
              ],
            ],
          );
        },
      ),
    );
  }
}
