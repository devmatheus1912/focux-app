part of 'add_exercicio_to_treino_screen.dart';

class _ExercisePickerCard extends StatelessWidget {
  final Exercicio? exercicio;
  final bool isDark;
  final Color primary;
  final ExercisePickerLibraryLines libraryLines;
  final bool showPrescriptionHint;
  final bool showBrowseHint;
  final bool compactMode;
  final VoidCallback onTap;
  final bool mediaLoading;
  final bool videoExpanded;
  final VoidCallback onToggleVideo;
  final VoidCallback onPreviewVideo;
  final VoidCallback onUploadVideo;
  final VoidCallback onRemoveVideo;
  final VoidCallback onCreate;

  const _ExercisePickerCard({
    required this.exercicio,
    required this.isDark,
    required this.primary,
    required this.libraryLines,
    this.showPrescriptionHint = true,
    this.showBrowseHint = true,
    this.compactMode = false,
    required this.onTap,
    required this.mediaLoading,
    required this.videoExpanded,
    required this.onToggleVideo,
    required this.onPreviewVideo,
    required this.onUploadVideo,
    required this.onRemoveVideo,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final selected = exercicio != null;
    final hasMediaIssue = selected && exercicio!.showMediaBadgeInWorkoutList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FxSettingsGroup(
          accent: primary,
          children: [
            FxSettingsTile(
              icon: selected ? Icons.check_rounded : Icons.search_rounded,
              accent: primary,
              label: selected ? exercicio!.nomeDisplay : 'Escolher exercício',
              subtitle:
                  selected
                      ? _exerciseMeta(exercicio!)
                      : [
                        libraryLines.primary,
                        if (libraryLines.secondary != null)
                          libraryLines.secondary!,
                      ].join(' · '),
              value: '',
              highlight: selected,
              showDivider:
                  !compactMode &&
                  (showBrowseHint && (!selected || (showPrescriptionHint && !hasMediaIssue))),
              onTap: onTap,
              accessory: Icon(Icons.expand_more_rounded, color: mute, size: 22),
            ),
            if (!compactMode &&
                showBrowseHint &&
                (!selected || (showPrescriptionHint && !hasMediaIssue)))
              FxSettingsTile(
                icon:
                    selected
                        ? Icons.edit_note_rounded
                        : Icons.auto_awesome_motion_rounded,
                accent: primary,
                label:
                    selected
                        ? 'Revise a prescrição abaixo'
                        : 'Explore por movimento ou grupo',
                subtitle:
                    selected
                        ? 'Confira séries, carga e descanso antes de salvar.'
                        : 'Use a aba Explorar ou busque pelo nome.',
                value: '',
                showDivider: false,
                onTap: onTap,
              ),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: _CreateExerciseButton(
            primary: primary,
            compact: true,
            onPressed: onCreate,
          ),
        ),
        if (selected && !compactMode) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: onToggleVideo,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    videoExpanded ? Icons.expand_less : Icons.videocam_outlined,
                    color: mute,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'VÃ­deo do exercÃ­cio (opcional)',
                      style: FocuxHubTypography.bodyMuted(
                        color: mute,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (videoExpanded) ...[
            const SizedBox(height: 6),
            ExerciseVideoUploadStrip(
              exercicio: exercicio!,
              isDark: isDark,
              primary: primary,
              mediaLoading: mediaLoading,
              quietCta: true,
              onPreview: onPreviewVideo,
              onUpload: onUploadVideo,
              onRemove: onRemoveVideo,
              footer: ExerciseVideoSpecTips(isDark: isDark, embedded: true),
            ),
          ],
        ],
      ],
    );
  }
}

class _RemoveExerciseVideoSheet extends StatelessWidget {
  final Exercicio exercicio;

  const _RemoveExerciseVideoSheet({required this.exercicio});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final bottom = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, bottom + 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: fxListCardDecoration(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.16)
                          : TokensStrip.borderDefault,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: EagleTokens.bad.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.videocam_off_outlined,
                      color: EagleTokens.bad,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remover vÃ­deo?',
                          style: FocuxHubTypography.body(color: ink).copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '"${exercicio.nomeDisplay}" continua na biblioteca. SÃ³ a mÃ­dia de demonstraÃ§Ã£o serÃ¡ removida.',
                          style: FocuxHubTypography.bodyMuted(
                            color: mute,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        backgroundColor: EagleTokens.bad,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('Remover'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
