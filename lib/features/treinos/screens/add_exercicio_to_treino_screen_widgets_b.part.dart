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
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final selected = exercicio != null;
    final hasMediaIssue = selected && exercicio!.showMediaBadgeInWorkoutList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(TokensStrip.rCard),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(14),
                  decoration: fxListCardDecoration(
                    context,
                    accent: selected ? primary : null,
                    selected: selected,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color:
                              selected
                                  ? primary
                                  : primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          selected ? Icons.check_rounded : Icons.search_rounded,
                          color: selected ? Colors.white : primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    selected
                                        ? exercicio!.nomeDisplay
                                        : 'Escolher exercÃ­cio',
                                    maxLines: selected ? 2 : 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: FocuxHubTypography.body(color: ink)
                                        .copyWith(
                                      height: 1.12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (selected)
                              Text(
                                _exerciseMeta(exercicio!),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: FocuxHubTypography.bodyMuted(
                                  color: _metaTextColor(isDark),
                                  height: 1.18,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    libraryLines.primary,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: FocuxHubTypography.bodyMuted(
                                      color: _metaTextColor(isDark),
                                      height: 1.18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (libraryLines.secondary != null)
                                    Text(
                                      libraryLines.secondary!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: FocuxHubTypography.bodyMuted(
                                        color: _metaTextColor(isDark),
                                        height: 1.15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.expand_more_rounded, color: mute, size: 22),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _CreateExerciseButton(
              primary: primary,
              compact: true,
              onPressed: onCreate,
            ),
          ],
        ),
        if (!compactMode &&
            showBrowseHint &&
            (!selected || (showPrescriptionHint && !hasMediaIssue))) ...[
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: fxListCardDecoration(context, accent: primary),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.edit_note_rounded
                        : Icons.auto_awesome_motion_rounded,
                    color: primary,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selected
                          ? 'Revise a prescriÃ§Ã£o abaixo antes de adicionar.'
                          : 'Busque acima ou explore por movimento/grupo.',
                      style: FocuxHubTypography.bodyMuted(
                        color: mute,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
