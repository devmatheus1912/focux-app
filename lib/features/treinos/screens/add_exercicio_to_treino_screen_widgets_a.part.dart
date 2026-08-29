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
    final mute = ShellChrome.of(context).mute;
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
                  exerciseLibraryMeta(exercicio),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FxSettingsLayout.subhead(color: mute),
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
    final tipoLabel = switch (tipoSerie) {
      'SUPERSET' => ' · Superset',
      'DROPSET' => ' · Drop set',
      _ => '',
    };
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final fg = dashboardPrioritiesChipForeground(primary, isDark: isDark);
    final bg = dashboardPrioritiesChipBackground(primary, isDark: isDark);
    final summary =
        '${preset.label} · $series×$repeticoes · ${descanso}s$tipoLabel';

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
            FxSettingsLayout.groupPadH,
            8,
            FxSettingsLayout.groupPadH,
            8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                button: true,
                label:
                    'Prescrição ativa ${preset.label}. $series séries de $repeticoes, $descanso segundos. Toque para editar.',
                child: Material(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onEditPrescription();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.tune_rounded, color: fg, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Prescrição padrão',
                                  style: FxSettingsLayout.subhead(
                                    color: mute,
                                  ).copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  summary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FocuxHubTypography.body(
                                    color: fg,
                                  ).copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: mute,
                            size: FxSettingsLayout.chevronSize,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
