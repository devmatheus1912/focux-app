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
      padding: EdgeInsets.fromLTRB(
        FxSettingsLayout.groupPadH,
        8,
        FxSettingsLayout.groupPadH,
        0,
      ),
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
                style: FocuxHubTypography.bodyMuted(
                  color: isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
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
              style: FocuxHubTypography.bodyMuted(
                color: mute,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onApply,
            child: Text(
              'Aplicar',
              style: FocuxHubTypography.body(color: primary).copyWith(
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
                style: FocuxHubTypography.bodyMuted(
                  color: mute,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: onClear,
              child: Text(
                'Limpar',
                style: FocuxHubTypography.bodyMuted(
                  color: primary,
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
    return FxSettingsGroup(
      accent: primary,
      children: [
        for (var i = 0; i < exercicios.length; i++)
          _QuickSearchResultTile(
            exercicio: exercicios[i],
            highlightQuery: query,
            alreadyInTreino: alreadyInTreinoIds.contains(exercicios[i].id),
            primary: primary,
            isDark: isDark,
            showDivider: i < exercicios.length - 1,
            onTap: () => onSelect(exercicios[i]),
            onPreviewThumb:
                canPreviewExerciseMedia(exercicios[i])
                    ? () => onPreview(exercicios[i])
                    : null,
          ),
      ],
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
                  style: FocuxHubTypography.cardTitle(
                    color: isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
                  ).copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  _exerciseMeta(exercicio),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FocuxHubTypography.bodyMuted(
                    color: _metaTextColor(isDark),
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
              style: FocuxHubTypography.body(color: primary).copyWith(
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
    this.showDivider = true,
  });

  final Exercicio exercicio;
  final bool alreadyInTreino;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;
  final String highlightQuery;
  final VoidCallback? onPreviewThumb;
  final bool showDivider;

  String get _subtitle {
    final meta = [
      if (exercicio.musculoAlvo?.trim().isNotEmpty == true)
        exercicio.musculoAlvo!.trim(),
      if (exercicio.equipamento?.trim().isNotEmpty == true)
        exercicio.equipamento!.trim(),
    ].join(' · ');
    if (alreadyInTreino) {
      return meta.isEmpty ? 'Já está neste treino' : '$meta · Já no plano';
    }
    return meta;
  }

  @override
  Widget build(BuildContext context) {
    return FxSettingsTile(
      icon: Icons.fitness_center_rounded,
      accent: primary,
      label: exercicio.nomeDisplay,
      subtitle: _subtitle.isEmpty ? null : _subtitle,
      value: '',
      showDivider: showDivider,
      onTap: onTap,
      accessory:
          onPreviewThumb != null
              ? GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onPreviewThumb!();
                },
                child: ExerciseMediaThumb.fromExercicio(exercicio, size: 36),
              )
              : null,
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
    final tipoLabel = switch (tipoSerie) {
      'SUPERSET' => ' · Superset',
      'DROPSET' => ' · Drop set',
      _ => '',
    };
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        FxSettingsLayout.groupPadH,
        8,
        FxSettingsLayout.groupPadH,
        bottom > 0 ? 6 : 12,
      ),
      child: FxSettingsGroup(
        accent: primary,
        caption: 'Prescrição ativa',
        children: [
          FxSettingsTile(
            icon: Icons.tune_rounded,
            accent: primary,
            label: preset.label,
            subtitle: '$series×$repeticoes · ${descanso}s descanso$tipoLabel',
            value: 'Editar',
            highlight: true,
            showDivider: false,
            semanticsLabel:
                'Prescrição ativa ${preset.label}. $series séries de $repeticoes repetições, $descanso segundos de descanso. Toque para editar.',
            onTap: onEdit,
          ),
        ],
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
      padding: EdgeInsets.fromLTRB(
        FxSettingsLayout.groupPadH,
        12,
        FxSettingsLayout.groupPadH,
        bottom + 12,
      ),
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
            FxErrorState(
              chromeOnDark: isDark,
              primary: primary,
              message: error!,
              onRetry: onSubmit,
            ),
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
              style: FocuxHubTypography.body(
                color: primary,
              ).copyWith(fontWeight: FontWeight.w800),
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
