part of 'meus_treinos_screen.dart';

/// Loading placeholder que espelha hero + cards do plano.
class _TrainingSkeleton extends StatelessWidget {
  const _TrainingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(TokensStrip.s5, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonLoader(height: 132, borderRadius: 24),
          SizedBox(height: 18),
          SkeletonLoader(height: 150, borderRadius: TokensStrip.rCard),
          SizedBox(height: 12),
          SkeletonLoader(height: 150, borderRadius: TokensStrip.rCard),
        ],
      ),
    );
  }
}

class _TrainingHero extends StatelessWidget {
  final int ativos;
  final int total;
  final int totalExercicios;
  final int totalConcluidos;
  final bool isDark;

  const _TrainingHero({
    required this.ativos,
    required this.total,
    required this.totalExercicios,
    required this.totalConcluidos,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forDark(isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final progresso =
        totalExercicios == 0 ? 0.0 : totalConcluidos / totalExercicios;
    final hasExercises = totalExercicios > 0;
    final headline =
        hasExercises
            ? '$ativos treino${ativos == 1 ? '' : 's'} ativo${ativos == 1 ? '' : 's'}'
            : 'Plano em montagem';
    final subtitle =
        hasExercises
            ? '$total no plano atual · $totalConcluidos/$totalExercicios exercícios'
            : '$total treino${total == 1 ? '' : 's'} no plano atual';

    return FxStripCard(
      emphasize: true,
      accent: primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: FocuxHubTypography.sectionTitle(context, color: ink).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: FocuxHubTypography.bodyMuted(
              color: mute,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (hasExercises)
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progresso,
                minHeight: 7,
                backgroundColor:
                    isDark ? EagleTokens.darkLine : TokensStrip.borderDefault,
                valueColor: AlwaysStoppedAnimation(primary),
              ),
            )
          else
            Text(
              'A sessão já está no radar. Os exercícios aparecem quando forem liberados.',
              style: FocuxHubTypography.bodyMuted(
                color: mute,
                fontWeight: FontWeight.w600,
              ).copyWith(fontSize: 12.5, height: 1.35),
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
  final VoidCallback onStart;

  const _TrainingPlanCard({
    required this.treino,
    required this.isDark,
    required this.onStart,
    this.starting = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forDark(isDark);
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
      if (starting) return;
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
        padding: const EdgeInsets.all(TokensStrip.s4),
        decoration: chrome.listCard(
          primary: concluido ? EagleTokens.good : primary,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color:
                        concluido
                            ? EagleTokens.good.withValues(alpha: 0.12)
                            : BrandPalette.soft(primary, dark: isDark),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    concluido
                        ? Icons.check_rounded
                        : Icons.fitness_center_rounded,
                    color: concluido ? EagleTokens.good : primary,
                  ),
                ),
                const SizedBox(width: 12),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _PlanMeta(
                            icon: Icons.list_alt_rounded,
                            text:
                                hasExercises
                                    ? '${treino.exercicios.length} exercícios'
                                    : 'em preparação',
                            color: mute,
                          ),
                          if (mediaCount > 0)
                            _PlanMeta(
                              icon: Icons.play_circle_outline_rounded,
                              text: '$mediaCount videos',
                              color: mute,
                            ),
                          _PlanMeta(
                            icon: Icons.timer_outlined,
                            text:
                                '~${(treino.exercicios.length * 4).clamp(8, 90)}min',
                            color: mute,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: mute),
              ],
            ),
            const SizedBox(height: 14),
            if (hasExercises)
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor:
                      isDark ? EagleTokens.darkLine : TokensStrip.borderDefault,
                  valueColor: AlwaysStoppedAnimation(
                    concluido ? EagleTokens.good : primary,
                  ),
                ),
              )
            else
              Container(
                height: 7,
                decoration: BoxDecoration(
                  color:
                      isDark ? EagleTokens.darkLine : TokensStrip.borderDefault,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            const SizedBox(height: 10),
            if (aguardando) ...[
              Text(
                'Treino reservado. A ficha abre assim que o personal liberar os exercícios.',
                style: TextStyle(
                  color: mute,
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FxLiquidPrimaryButton(
                  label: 'Ver status do treino',
                  icon: Icons.info_outline_rounded,
                  onPressed: handleAction,
                ),
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      concluido
                          ? 'Treino finalizado. Historico salvo.'
                          : done == 0
                          ? 'Pronto para iniciar com registro de séries.'
                          : '$done de ${treino.exercicios.length} exercicios ja marcados.',
                      style: TextStyle(
                        color: mute,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FxLiquidPrimaryButton(
                    label: concluido ? 'Rever' : 'Iniciar',
                    icon:
                        concluido
                            ? Icons.replay_rounded
                            : Icons.play_arrow_rounded,
                    onPressed: starting ? null : handleAction,
                    loading: starting,
                    loadingLabel: 'Abrindo…',
                    expand: false,
                  ),
                ],
              ),
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
  final chrome = ShellChrome.forDark(isDark);
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

class _TrainingReadinessSection extends StatelessWidget {
  final int totalExercicios;
  final int totalConcluidos;
  final int ativos;
  final bool isDark;

  const _TrainingReadinessSection({
    required this.totalExercicios,
    required this.totalConcluidos,
    required this.ativos,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forDark(isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final hasExercises = totalExercicios > 0;

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: chrome.listCard(primary: primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasExercises ? 'Antes de treinar' : 'Próxima liberação',
            style: TextStyle(
              color: ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasExercises
                ? 'Entre com foco, registre as séries e finalize com feedback.'
                : 'O que falta para a sessão guiada aparecer.',
            style: TextStyle(color: mute, fontSize: 12.3, height: 1.28),
          ),
          const SizedBox(height: 14),
          if (hasExercises)
            Row(
              children: [
                Expanded(
                  child: _ReadinessPill(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Registro',
                    value: '$totalConcluidos/$totalExercicios',
                    color: primary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ReadinessPill(
                    icon: Icons.local_fire_department_outlined,
                    title: 'Rotina',
                    value: '$ativos ativo${ativos == 1 ? '' : 's'}',
                    color: primary,
                    isDark: isDark,
                  ),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _ReadinessMarker(
                    icon: Icons.bookmark_added_outlined,
                    title: 'Reservado',
                    state: '$ativos ativo${ativos == 1 ? '' : 's'}',
                    color: EagleTokens.good,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReadinessMarker(
                    icon: Icons.tune_rounded,
                    title: 'Ficha',
                    state: 'pendente',
                    color: primary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReadinessMarker(
                    icon: Icons.play_circle_outline_rounded,
                    title: 'Sessão',
                    state: 'proximo',
                    color: primary,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadinessMarker extends StatelessWidget {
  final IconData icon;
  final String title;
  final String state;
  final Color color;
  final bool isDark;

  const _ReadinessMarker({
    required this.icon,
    required this.title,
    required this.state,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: chrome.listCard(primary: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: BrandPalette.soft(color, dark: isDark),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            state,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: mute,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessPill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool isDark;

  const _ReadinessPill({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BrandPalette.soft(color, dark: isDark),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mute,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _PlanMeta({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
