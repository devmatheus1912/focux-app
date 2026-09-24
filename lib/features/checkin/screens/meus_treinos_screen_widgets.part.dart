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
                  ),
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
    final insight =
        startableCount > 0
            ? 'Plano pronto · comece pelo próximo treino'
            : ativos > 0
            ? 'Treinos ativos no plano'
            : 'Aguardando liberação do personal';
    final volumeLine =
        startableCount > 0
            ? '$startableCount prontos · $total no plano'
            : '$ativos ativos · $total no plano';
    return FxStripCard(
      glowStrength: 0.04,
      padding: const EdgeInsets.all(TokensStrip.s3),
      semanticsLabel: '$insight. $volumeLine.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sua rotina',
            style: FocuxHubTypography.chip(chrome.mute),
          ),
          const SizedBox(height: TokensStrip.s1),
          Text(
            insight,
            style: FocuxHubTypography.cardTitle(color: chrome.ink),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            volumeLine,
            style: FocuxHubTypography.bodyMuted(
              color: primary.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
    final showPrimaryStart =
        !concluido && isTreinoDisponivelParaIniciar(treino);
    final prazoFim = TreinoAtribuicaoPrazo.parseIsoDate(treino.dataFim);
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
                        style: FocuxHubTypography.cardTitle(color: ink),
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
                        style: FocuxHubTypography.bodyMuted(
                          color: mute,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (prazoFim != null) ...[
                        const SizedBox(height: 6),
                        TreinoPrazoBadge(dataFim: prazoFim, isDark: isDark),
                      ],
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
                style: FocuxHubTypography.bodyMuted(
                  color: mute,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: handleAction,
                  child: const Text('Ver status'),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child:
                        showPrimaryStart
                            ? FxLiquidPrimaryButton(
                              label: 'Iniciar',
                              icon: Icons.play_arrow_rounded,
                              onPressed:
                                  starting || confirming ? null : handleAction,
                              loading: starting,
                              loadingLabel: 'Abrindo…',
                            )
                            : TextButton(
                              onPressed:
                                  starting || confirming ? null : handleAction,
                              child: Text(concluido ? 'Rever' : 'Iniciar'),
                            ),
                  ),
                  if (!concluido && canStart && onConfirmPlano != null) ...[
                    const SizedBox(width: TokensStrip.s2),
                    TextButton(
                      onPressed: confirming || starting ? null : onConfirmPlano,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(88, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        tapTargetSize: MaterialTapTargetSize.padded,
                        foregroundColor: primary,
                      ),
                      child: Text(
                        confirming ? '…' : 'Fiz o treino',
                        style: FocuxHubTypography.bodyMuted(
                          color: primary,
                          fontWeight: FontWeight.w700,
                        ),
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
                  style: FocuxHubTypography.bodyMuted(
                    color: ink,
                    fontWeight: FontWeight.w600,
                    height: 1.42,
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
