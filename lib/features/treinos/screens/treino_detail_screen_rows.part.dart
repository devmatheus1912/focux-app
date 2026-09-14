part of 'treino_detail_screen.dart';

class _ExercicioRow extends StatelessWidget {
  final TreinoExercicioItem te;
  final int index;
  final bool isDark;
  final bool isLast;
  final VoidCallback onDuplicate;
  final VoidCallback onSubstitute;
  final VoidCallback onRemove;
  final VoidCallback onEditPrescription;

  const _ExercicioRow({
    required this.te,
    required this.index,
    required this.isDark,
    required this.isLast,
    required this.onDuplicate,
    required this.onSubstitute,
    required this.onRemove,
    required this.onEditPrescription,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forBrightness(context, isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final line = chrome.line;
    final note = te.observacoes?.trim();
    final hasNote = note != null && note.isNotEmpty;
    final prescription = treinoDetailExerciseLine(te);

    return Container(
      decoration: BoxDecoration(
        border:
            isLast ? null : Border(bottom: BorderSide(color: line, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: fxTransparent,
              child: InkWell(
                onTap: onEditPrescription,
                child: Semantics(
                  button: true,
                  label:
                      '${te.exercicio.nomeDisplay}. $prescription'
                      '${hasNote ? '. $note' : ''}. Editar prescrição.',
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TreinosLayout.exerciseRowPadH,
                      TreinosLayout.exerciseRowPadV,
                      TokensStrip.s2,
                      TreinosLayout.exerciseRowPadV,
                    ),
                    child: Row(
                      children: [
                        Semantics(
                          label:
                              'Segure para reordenar ${te.exercicio.nomeDisplay}',
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            size: 18,
                            color: mute.withValues(alpha: 0.72),
                          ),
                        ),
                        SizedBox(
                          width: 18,
                          child: Text(
                            '$index',
                            textAlign: TextAlign.center,
                            style: FocuxHubTypography.metric(
                              color: mute,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: TokensStrip.s2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                te.exercicio.nomeDisplay,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: FocuxHubTypography.cardTitle(color: ink),
                              ),
                              if (hasNote) ...[
                                const SizedBox(height: 1),
                                Text(
                                  note,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: FocuxHubTypography.bodyMuted(
                                    color: mute,
                                    fontWeight: FontWeight.w600,
                                  ).copyWith(fontSize: 11),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: TokensStrip.s2),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 148),
                          child: Text(
                            prescription,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: FocuxHubTypography.metric(
                              color: mute,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Ações de ${te.exercicio.nomeDisplay}',
            child: IconButton(
              tooltip: 'Ações de ${te.exercicio.nomeDisplay}',
              onPressed: () async {
                HapticFeedback.selectionClick();
                AnalyticsService.instance.track(
                  ProductEvents.treinoExerciseMenuOpened,
                  props: {'id': te.id},
                );
                final action = await _showTreinoSheet<String>(
                  context: context,
                  builder:
                      (_) => _ExerciseActionsSheet(
                        title: te.exercicio.nomeDisplay,
                        isDark: isDark,
                      ),
                );
                if (action == 'edit') onEditPrescription();
                if (action == 'duplicate') onDuplicate();
                if (action == 'substitute') onSubstitute();
                if (action == 'remove') onRemove();
              },
              style: IconButton.styleFrom(
                minimumSize: const Size(
                  TreinosLayout.headerChromeSize,
                  TreinosLayout.touchTarget,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              icon: Icon(Icons.more_horiz_rounded, color: mute, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseActionsSheet extends StatelessWidget {
  final String title;
  final bool isDark;

  const _ExerciseActionsSheet({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;
    return TreinoInsetActionSheet(
      isDark: isDark,
      maxHeight: maxHeight,
      headerIcon: Icons.fitness_center_rounded,
      title: 'Ações do exercício',
      subtitle: title,
      actions: [
        TreinoInsetActionSpec(
          icon: Icons.edit_note_rounded,
          label: 'Editar prescrição',
          onTap: () => Navigator.pop(context, 'edit'),
        ),
        TreinoInsetActionSpec(
          icon: Icons.copy_rounded,
          label: 'Duplicar',
          onTap: () => Navigator.pop(context, 'duplicate'),
        ),
        TreinoInsetActionSpec(
          icon: Icons.swap_horiz_rounded,
          label: 'Substituir',
          onTap: () => Navigator.pop(context, 'substitute'),
        ),
        TreinoInsetActionSpec(
          icon: Icons.remove_circle_outline_rounded,
          label: 'Remover do treino',
          danger: true,
          onTap: () => Navigator.pop(context, 'remove'),
        ),
      ],
    );
  }
}
