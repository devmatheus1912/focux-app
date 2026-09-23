part of 'meus_treinos_screen.dart';

/// Loading placeholder que espelha hero + cards do plano.
class _TrainingSkeleton extends StatelessWidget {
  const _TrainingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(TokensStrip.s5, 6, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonLoader(height: 96, borderRadius: 24),
          SizedBox(height: 12),
          SkeletonLoader(height: 120, borderRadius: TokensStrip.rCard),
          SizedBox(height: 8),
          SkeletonLoader(height: 120, borderRadius: TokensStrip.rCard),
        ],
      ),
    );
  }
}

class _RetomarTreinoBanner extends StatelessWidget {
  final ExecucaoTreino treino;
  final bool isDark;
  final VoidCallback onRetomar;

  const _RetomarTreinoBanner({
    required this.treino,
    required this.isDark,
    required this.onRetomar,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return FxStripCard(
      emphasize: true,
      accent: primary,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Retomar treino',
                  style: FocuxHubTypography.sectionTitle(
                    context,
                    color: Theme.of(context).colorScheme.onSurface,
                  ).copyWith(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  treino.treinoNome,
                  style: FocuxHubTypography.bodyMuted(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onRetomar,
            child: const Text('Retomar'),
          ),
        ],
      ),
    );
  }
}

class _WeekProgressStrip extends StatelessWidget {
  final int ativos;
  final int startableCount;
  final int total;
  final bool isDark;

  const _WeekProgressStrip({
    required this.ativos,
    required this.startableCount,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forBrightness(context, isDark);
    final line =
        startableCount > 0
            ? '$startableCount prontos · $total no plano'
            : '$ativos ativos · $total no plano';
    return FxStripCard(
      glowStrength: 0.04,
      padding: const EdgeInsets.symmetric(
        horizontal: TokensStrip.s3,
        vertical: TokensStrip.s2,
      ),
      child: Text(
        line,
        style: FocuxHubTypography.bodyMuted(
          color: chrome.mute,
          fontWeight: FontWeight.w700,
        ).copyWith(color: primary.withValues(alpha: 0.9)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _TrainingPlanCard extends StatelessWidget {
  final ExecucaoTreino treino;
  final bool isDark;
  final bool starting;
  final bool confirming;
  final VoidCallback onStart;
  final VoidCallback? onConfirmPlano;

  const _TrainingPlanCard({
    required this.treino,
    required this.isDark,
    required this.onStart,
    this.onConfirmPlano,
    this.starting = false,
    this.confirming = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forBrightness(context, isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final done = treino.exercicios.where((e) => e.concluido).length;
    final progress =
        treino.exercicios.isEmpty ? 0.0 : done / treino.exercicios.length;
    final aguardando = isTreinoAguardandoLiberacao(treino);
    final hasExercises = !aguardando && treino.exercicios.isNotEmpty;
    final mediaCount =
        treino.exercicios.where((e) => e.gifUrl?.isNotEmpty == true).length;
    final status = normalizeTreinoStatus(treino.status);
    final concluido = status == treinoStatusConcluido;
    final canStart = isTreinoDisponivelParaIniciar(treino) || concluido;
    void handleAction() {
      if (starting || confirming) return;
      if (aguardando) {
        _showTrainingPendingSheet(
          context: context,
          treinoNome: treino.treinoNome,
          isDark: isDark,
        );
        return;
      }
      if (canStart) {
        onStart();
      }
    }

    return InkWell(
      onTap: handleAction,
      borderRadius: BorderRadius.circular(TokensStrip.rCard),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          TokensStrip.s3,
          TokensStrip.s3,
          TokensStrip.s3,
          TokensStrip.s2,
        ),
        decoration: chrome.listCard(
          primary: concluido ? EagleTokens.good : primary,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:
                        concluido
                            ? EagleTokens.good.withValues(alpha: 0.12)
                            : BrandPalette.soft(primary, dark: isDark),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    concluido
                        ? Icons.check_rounded
                        : Icons.fitness_center_rounded,
                    color: concluido ? EagleTokens.good : primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        treino.treinoNome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (aguardando)
                            'em preparação'
                          else if (hasExercises)
                            '${treino.exercicios.length} exercícios'
                          else
                            'Pronto para treinar',
                          if (mediaCount > 0) '$mediaCount vídeos',
                          if (hasExercises)
                            '~${(treino.exercicios.length * 4).clamp(8, 90)}min',
                          if (hasExercises && done > 0 && !concluido)
                            '$done feitos',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: mute,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (hasExercises && (done > 0 || concluido)) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor:
                      isDark ? EagleTokens.darkLine : TokensStrip.borderDefault,
                  valueColor: AlwaysStoppedAnimation(
                    concluido ? EagleTokens.good : primary,
                  ),
                ),
              ),
            ],
            if (aguardando) ...[
              const SizedBox(height: 8),
              Text(
                'Ficha abre quando o personal liberar os exercícios.',
                style: TextStyle(
                  color: mute,
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FxLiquidPrimaryButton(
                  label: 'Ver status',
                  icon: Icons.info_outline_rounded,
                  onPressed: handleAction,
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FxLiquidPrimaryButton(
                      label: concluido ? 'Rever' : 'Iniciar',
                      icon:
                          concluido
                              ? Icons.replay_rounded
                              : Icons.play_arrow_rounded,
                      onPressed: starting || confirming ? null : handleAction,
                      loading: starting,
                      loadingLabel: 'Abrindo…',
                    ),
                  ),
                  if (!concluido && canStart && onConfirmPlano != null) ...[
                    const SizedBox(width: TokensStrip.s2),
                    TextButton(
                      onPressed: confirming || starting ? null : onConfirmPlano,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        confirming ? '…' : 'Fiz o treino',
                        style: FocuxHubTypography.chip(primary),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void _showTrainingPendingSheet({
  required BuildContext context,
  required String treinoNome,
  required bool isDark,
}) {
  final primary = Theme.of(context).colorScheme.primary;
  final chrome = ShellChrome.forBrightness(context, isDark);
  final ink = chrome.ink;

  showFxHomeSheet<void>(
    context,
    builder:
        (sheetContext) => FxHomeSheetSurface(
          isDark: isDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: isDark),
              SizedBox(height: TokensStrip.s4),
              FxHomeSheetHeader(
                isDark: isDark,
                title: treinoNome,
                subtitle: 'Em preparacao',
                leading: Icon(
                  Icons.pending_actions_rounded,
                  color: primary,
                  size: 18,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(TokensStrip.s4),
                decoration: chrome.panel(accent: primary),
                child: Text(
                  'Seu personal ja reservou este treino. Assim que os exercicios forem liberados, o botao Iniciar aparece com registro de series, videos e feedback.',
                  style: TextStyle(
                    color: ink,
                    fontSize: 13,
                    height: 1.42,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: TokensStrip.s4),
              FxLiquidPrimaryButton(
                label: 'Entendi',
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
  );
}
