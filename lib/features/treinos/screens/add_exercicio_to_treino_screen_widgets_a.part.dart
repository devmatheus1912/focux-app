part of 'add_exercicio_to_treino_screen.dart';

class _BibliotecaSyncBanner extends StatelessWidget {
  const _BibliotecaSyncBanner({
    required this.message,
    required this.isDark,
    required this.primary,
    this.showProgress = true,
  });

  final String message;
  final bool isDark;
  final Color primary;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showProgress)
              SizedBox(
                width: 16,
                height: 16,
                child: FxLoading(size: 16, strokeWidth: 2, color: primary),
              )
            else
              Icon(Icons.sync_rounded, color: primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTypography.inter(
                  color: isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepeatPrescriptionBanner extends StatelessWidget {
  const _RepeatPrescriptionBanner({
    required this.memory,
    required this.isDark,
    required this.primary,
    required this.onApply,
  });

  final ExercisePrescriptionMemory memory;
  final bool isDark;
  final Color primary;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Repetir última prescrição (${memory.summary})',
              style: AppTypography.inter(
                color: mute,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onApply,
            child: Text(
              'Aplicar',
              style: AppTypography.inter(
                color: primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlunoEquipmentFilterBanner extends StatelessWidget {
  const _AlunoEquipmentFilterBanner({
    required this.alunoNome,
    required this.equipamentos,
    required this.isDark,
    required this.primary,
    required this.onClear,
  });

  final String alunoNome;
  final Set<Equipamento> equipamentos;
  final bool isDark;
  final Color primary;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final labels = equipamentos
        .map((e) => TaxonomyLabels.equipamento[e] ?? e.name)
        .take(3)
        .join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: fxListCardDecoration(context, accent: primary),
        child: Row(
          children: [
            Icon(Icons.person_outline_rounded, color: primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Equipamento de $alunoNome: $labels',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: mute,
                ),
              ),
            ),
            TextButton(
              onPressed: onClear,
              child: Text(
                'Limpar',
                style: AppTypography.inter(
                  color: primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({
    required this.exercicios,
    required this.query,
    required this.isDark,
    required this.primary,
    required this.alreadyInTreinoIds,
    required this.onSelect,
    required this.onPreview,
  });

  final List<Exercicio> exercicios;
  final String query;
  final bool isDark;
  final Color primary;
  final Set<int> alreadyInTreinoIds;
  final ValueChanged<Exercicio> onSelect;
  final ValueChanged<Exercicio> onPreview;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 560;
        if (!wide) {
          return Column(
            children: [
              for (final exercicio in exercicios)
                _QuickSearchResultTile(
                  exercicio: exercicio,
                  highlightQuery: query,
                  alreadyInTreino: alreadyInTreinoIds.contains(exercicio.id),
                  primary: primary,
                  isDark: isDark,
                  onTap: () => onSelect(exercicio),
                  onPreviewThumb:
                      canPreviewExerciseMedia(exercicio)
                          ? () => onPreview(exercicio)
                          : null,
                ),
            ],
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 0,
          children: [
            for (final exercicio in exercicios)
              SizedBox(
                width: (constraints.maxWidth - 8) / 2,
                child: _QuickSearchResultTile(
                  exercicio: exercicio,
                  highlightQuery: query,
                  alreadyInTreino: alreadyInTreinoIds.contains(exercicio.id),
                  primary: primary,
                  isDark: isDark,
                  onTap: () => onSelect(exercicio),
                  onPreviewThumb:
                      canPreviewExerciseMedia(exercicio)
                          ? () => onPreview(exercicio)
                          : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CompactSelectedExerciseBar extends StatelessWidget {
  const _CompactSelectedExerciseBar({
    required this.exercicio,
    required this.isDark,
    required this.primary,
    required this.onChange,
    this.onPreview,
    this.celebrateVideoSuccess = false,
  });

  final Exercicio exercicio;
  final bool isDark;
  final Color primary;
  final VoidCallback onChange;
  final VoidCallback? onPreview;
  final bool celebrateVideoSuccess;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: fxListCardDecoration(
        context,
        accent: primary,
        selected: true,
      ),
      child: Row(
        children: [
          if (onPreview != null)
            GestureDetector(
              onTap: onPreview,
              child: ExerciseMediaThumb.fromExercicio(
                exercicio,
                size: 44,
                celebrateSuccess: celebrateVideoSuccess,
                key: ValueKey(
                  'thumb-${exercicio.id}-${exercicio.videoUrl}-${exercicio.thumbnailUrl}',
                ),
              ),
            )
          else
            ExerciseMediaThumb.fromExercicio(
              exercicio,
              size: 44,
              celebrateSuccess: celebrateVideoSuccess,
              key: ValueKey(
                'thumb-${exercicio.id}-${exercicio.videoUrl}-${exercicio.thumbnailUrl}',
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercicio.nomeDisplay,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  _exerciseMeta(exercicio),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    color: _metaTextColor(isDark),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: Text(
              'Trocar',
              style: AppTypography.inter(
                color: primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickSearchResultTile extends StatelessWidget {
  const _QuickSearchResultTile({
    required this.exercicio,
    required this.alreadyInTreino,
    required this.primary,
    required this.isDark,
    required this.onTap,
    this.highlightQuery = '',
    this.onPreviewThumb,
  });

  final Exercicio exercicio;
  final bool alreadyInTreino;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;
  final String highlightQuery;
  final VoidCallback? onPreviewThumb;

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        button: true,
        label: exercicio.nomeDisplay,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: fxListCardDecoration(context, accent: primary),
            child: Row(
              children: [
                if (onPreviewThumb != null)
                  GestureDetector(
                    onTap: onPreviewThumb,
                    child: ExerciseMediaThumb.fromExercicio(
                      exercicio,
                      size: 40,
                    ),
                  )
                else
                  ExerciseMediaThumb.fromExercicio(exercicio, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      highlightedExerciseName(
                        name: exercicio.nomeDisplay,
                        query: highlightQuery,
                        baseStyle: AppTypography.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                        highlightColor: primary,
                      ),
                      if (alreadyInTreino)
                        Text(
                          'Já está neste treino',
                          style: AppTypography.inter(
                            color: mute,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: mute, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MontarComModeloCard extends StatelessWidget {
  const _MontarComModeloCard({
    required this.onTap,
    required this.isDark,
    required this.primary,
    required this.templateCount,
  });

  final VoidCallback onTap;
  final bool isDark;
  final Color primary;
  final int templateCount;

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: fxListCardDecoration(context, accent: primary),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.view_agenda_rounded, color: primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Montar com modelo',
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Full body, PPL, bro split e mais — $templateCount modelos.',
                      style: AppTypography.inter(
                        color: mute,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: mute, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddExerciseErrorBanner extends StatelessWidget {
  const _AddExerciseErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: EagleTokens.bad.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EagleTokens.bad.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: EagleTokens.bad, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.inter(
                color: EagleTokens.bad,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivePrescriptionStrip extends StatelessWidget {
  const _ActivePrescriptionStrip({
    required this.presetId,
    required this.series,
    required this.repeticoes,
    required this.descanso,
    required this.tipoSerie,
    required this.isDark,
    required this.primary,
    required this.onEdit,
  });

  final String presetId;
  final String series;
  final String repeticoes;
  final String descanso;
  final String tipoSerie;
  final bool isDark;
  final Color primary;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final preset = workoutBuilderPresetById(presetId);
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final tipoLabel = switch (tipoSerie) {
      'SUPERSET' => ' · Superset',
      'DROPSET' => ' · Drop set',
      _ => '',
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.paddingOf(context).bottom > 0 ? 8 : 14,
          ),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.94),
            border: Border(top: BorderSide(color: line.withValues(alpha: 0.8))),
          ),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, color: primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prescrição ativa: ${preset.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$series×$repeticoes · ${descanso}s descanso$tipoLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        color: mute,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Editar',
                style: AppTypography.inter(
                  color: primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickyAddExerciseBar extends StatelessWidget {
  const _StickyAddExerciseBar({
    required this.error,
    required this.loading,
    required this.isDark,
    required this.onSubmit,
    required this.onContinue,
  });

  final String? error;
  final bool loading;
  final bool isDark;
  final VoidCallback onSubmit;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: line.withValues(alpha: 0.8))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            _AddExerciseErrorBanner(message: error!),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: loading ? null : onSubmit,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              foregroundColor: primary,
              side: BorderSide(color: primary.withValues(alpha: 0.45)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Icon(Icons.check_rounded, color: primary, size: 20),
            label: Text(
              'Concluir e voltar ao treino',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(
                context,
              ).colorScheme.copyWith(onPrimary: Colors.white),
            ),
            child: FxLiquidPrimaryButton(
              label: 'Adicionar e continuar',
              icon: Icons.playlist_add_rounded,
              onPressed: loading ? null : onContinue,
              loading: loading,
            ),
          ),
        ],
      ),
    );
  }
}
