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
    final chrome = ShellChrome.forDark(isDark);
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: FocuxHubTypography.cardTitle(color: ink),
                            ),
                            if (hasNote) ...[
                              const SizedBox(height: 1),
                              Text(
                                note,
                                maxLines: 1,
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
          Semantics(
            button: true,
            label: 'Ações do exercício',
            child: IconButton(
              tooltip: 'Ações do exercício',
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
    final chrome = ShellChrome.forDark(isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final bottom = MediaQuery.of(context).padding.bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    final actions = <_DetailActionTile>[
      _DetailActionTile(
        icon: Icons.edit_note_rounded,
        label: 'Editar prescrição',
        showChevron: true,
        onTap: () => Navigator.pop(context, 'edit'),
      ),
      _DetailActionTile(
        icon: Icons.copy_rounded,
        label: 'Duplicar item',
        onTap: () => Navigator.pop(context, 'duplicate'),
      ),
      _DetailActionTile(
        icon: Icons.swap_horiz_rounded,
        label: 'Substituir exercício',
        showChevron: true,
        onTap: () => Navigator.pop(context, 'substitute'),
      ),
      _DetailActionTile(
        icon: Icons.remove_circle_outline_rounded,
        label: 'Remover do treino',
        color: EagleTokens.bad,
        onTap: () => Navigator.pop(context, 'remove'),
      ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, 12 + bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: chrome.bottomSheet(radius: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: chrome.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              SizedBox(height: TokensStrip.s4),
              _TreinoSheetChromeHeader(
                icon: Icons.fitness_center_rounded,
                title: title,
                subtitle: 'Escolha uma ação.',
                isDark: isDark,
              ),
              const SizedBox(height: TokensStrip.s4),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: DecoratedBox(
                    decoration: fxListCardDecoration(context, accent: primary),
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < actions.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: chrome.line.withValues(alpha: 0.7),
                              ),
                            actions[i],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
