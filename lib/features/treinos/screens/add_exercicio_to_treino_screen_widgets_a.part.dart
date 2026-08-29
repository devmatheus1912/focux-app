part of 'add_exercicio_to_treino_screen.dart';

class _BibliotecaSyncBanner extends StatelessWidget {
  const _BibliotecaSyncBanner({
    required this.message,
    required this.isDark,
    required this.primary,
    this.showProgress = true,
    this.warning = false,
  });

  final String message;
  final bool isDark;
  final Color primary;
  final bool showProgress;
  final bool warning;

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
          color:
              warning
                  ? EagleTokens.warn.withValues(alpha: isDark ? 0.16 : 0.1)
                  : primary.withValues(alpha: isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                warning
                    ? EagleTokens.warn.withValues(alpha: 0.28)
                    : primary.withValues(alpha: 0.2),
          ),
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
              Icon(
                warning ? Icons.info_outline_rounded : Icons.sync_rounded,
                color: warning ? EagleTokens.warn : primary,
                size: 18,
              ),
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

class _InlineWarningBanner extends StatelessWidget {
  const _InlineWarningBanner({
    required this.message,
    required this.isDark,
    required this.primary,
    this.onDismiss,
  });

  final String message;
  final bool isDark;
  final Color primary;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return _BibliotecaSyncBanner(
      message: message,
      isDark: isDark,
      primary: primary,
      showProgress: false,
      warning: true,
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
          ExerciseLibraryRow(
            exercicio: exercicios[i],
            alreadyInTreino: alreadyInTreinoIds.contains(exercicios[i].id),
            showDivider: i < exercicios.length - 1,
            onTap: () => onSelect(exercicios[i]),
            onPreviewThumb:
                canPreviewExerciseMedia(exercicios[i])
                    ? () => onPreview(exercicios[i])
                    : null,
            picker: false,
          ),
      ],
    );
  }
}

class _SelectedExerciseInsetGroup extends StatelessWidget {
  const _SelectedExerciseInsetGroup({
    required this.exercicio,
    required this.primary,
    required this.mediaLoading,
    required this.celebrateVideoSuccess,
    required this.onChange,
    required this.onPreview,
    required this.onUpload,
    required this.onRemove,
    required this.onSimilar,
  });

  final Exercicio exercicio;
  final Color primary;
  final bool mediaLoading;
  final bool celebrateVideoSuccess;
  final VoidCallback onChange;
  final VoidCallback onPreview;
  final VoidCallback onUpload;
  final VoidCallback onRemove;
  final VoidCallback onSimilar;

  @override
  Widget build(BuildContext context) {
    final soft = BrandPalette.softened(primary);
    final hasPersonalVideo = exercicioHasPersonalVideo(exercicio);
    final hasLibraryDemo =
        !kBibliotecaLibraryVideosStandby &&
        exercicio.hasPlayableMedia &&
        !hasPersonalVideo &&
        exercicioHasPublishedLibraryMedia(exercicio);
    final canPreview = hasPersonalVideo || hasLibraryDemo;
    final videoTitle =
        mediaLoading
            ? 'Enviando vídeo...'
            : celebrateVideoSuccess
            ? 'Vídeo enviado'
            : hasPersonalVideo
            ? 'Seu vídeo'
            : hasLibraryDemo
            ? 'Demo da biblioteca'
            : 'Vídeo (opcional)';
    final videoSubtitle =
        mediaLoading
            ? 'Não feche o app'
            : celebrateVideoSuccess
            ? 'Miniatura atualizada'
            : hasPersonalVideo
            ? 'Toque para trocar o arquivo'
            : hasLibraryDemo
            ? 'Assista ou envie a sua gravação'
            : 'Envie sua demonstração · ${ExerciseVideoUploadSpec.sizeLabel}';
    final videoIcon =
        mediaLoading
            ? Icons.hourglass_top_rounded
            : celebrateVideoSuccess || hasPersonalVideo
            ? Icons.play_circle_fill_rounded
            : hasLibraryDemo
            ? Icons.video_library_rounded
            : Icons.videocam_outlined;
    final videoCta =
        mediaLoading
            ? ''
            : hasPersonalVideo || celebrateVideoSuccess
            ? 'Trocar'
            : 'Enviar';
    final meta = exerciseLibraryMeta(exercicio);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FxSettingsGroup(
          accent: primary,
          header: 'Exercício selecionado',
          helpTooltip: 'Como filmar o vídeo',
          onHelpTap: () => ExerciseVideoSpecTips.open(context),
          children: [
            FxSettingsTile(
              icon: Icons.fitness_center_outlined,
              accent: soft,
              label: exercicio.nomeDisplay,
              subtitle: meta.isEmpty ? 'Toque para trocar' : meta,
              value: 'Trocar',
              onTap: onChange,
            ),
            if (!kBibliotecaLibraryVideosStandby || !hasLibraryDemo)
              FxSettingsTile(
                icon: videoIcon,
                accent: soft,
                label: videoTitle,
                subtitle: videoSubtitle,
                value: videoCta,
                highlight: celebrateVideoSuccess,
                onTap: mediaLoading ? () {} : onUpload,
              ),
            if (canPreview && !mediaLoading)
              FxSettingsTile(
                icon: Icons.play_circle_outline_rounded,
                accent: soft,
                label: hasPersonalVideo ? 'Ver seu vídeo' : 'Ver demonstração',
                value: '',
                onTap: onPreview,
              ),
            if (hasPersonalVideo && !mediaLoading)
              FxSettingsTile(
                icon: Icons.delete_outline_rounded,
                accent: EagleTokens.bad,
                label: 'Remover vídeo',
                value: '',
                danger: true,
                onTap: onRemove,
              ),
            FxSettingsTile(
              icon: Icons.swap_horiz_rounded,
              accent: soft,
              label: 'Trocar por similar',
              subtitle: 'Mesmo padrão de movimento',
              value: '',
              showDivider: false,
              onTap: onSimilar,
            ),
          ],
        ),
        if (mediaLoading) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 5,
              backgroundColor: soft.withValues(alpha: 0.12),
              color: soft,
            ),
          ),
        ],
      ],
    );
  }
}

class _AddExerciseBottomDock extends StatelessWidget {
  const _AddExerciseBottomDock({
    required this.showActions,
    required this.error,
    required this.loading,
    required this.isDark,
    required this.primary,
    required this.presetId,
    required this.series,
    required this.repeticoes,
    required this.descanso,
    required this.tipoSerie,
    required this.onEditPrescription,
    required this.onSubmit,
    required this.onContinue,
  });

  final bool showActions;
  final String? error;
  final bool loading;
  final bool isDark;
  final Color primary;
  final String presetId;
  final String series;
  final String repeticoes;
  final String descanso;
  final String tipoSerie;
  final VoidCallback onEditPrescription;
  final VoidCallback onSubmit;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final preset = workoutBuilderPresetById(presetId);
    final summary = formatActivePrescriptionLine(
      presetLabel: preset.label,
      series: series,
      repeticoes: repeticoes,
      descansoSegundos: descanso,
      tipoSerie: tipoSerie,
    );
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final brand = BrandPalette.softened(primary);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.98),
        border: Border(top: BorderSide(color: line.withValues(alpha: 0.7))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            FxSettingsLayout.pageInset,
            8,
            FxSettingsLayout.pageInset,
            8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxSettingsGroup(
                accent: primary,
                children: [
                  FxSettingsTile(
                    icon: Icons.tune_rounded,
                    accent: brand,
                    label: 'Prescrição padrão',
                    subtitle: summary,
                    value: '',
                    showDivider: false,
                    onTap: onEditPrescription,
                  ),
                ],
              ),
              if (showActions) ...[
                const SizedBox(height: 10),
                if (error != null) ...[
                  FxErrorState(
                    chromeOnDark: isDark,
                    primary: primary,
                    message: error!,
                    onRetry: onSubmit,
                  ),
                  const SizedBox(height: 8),
                ],
                OutlinedButton.icon(
                  onPressed: loading ? null : onSubmit,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    foregroundColor: primary,
                    side: BorderSide(color: primary.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
            ],
          ),
        ),
      ),
    );
  }
}
