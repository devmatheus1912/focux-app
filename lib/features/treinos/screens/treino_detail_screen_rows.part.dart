part of 'treino_detail_screen.dart';

class _ExercicioRow extends StatelessWidget {
  final TreinoExercicioItem te;
  final int index;
  final bool isDark;
  final Color primary;
  final bool isLast;
  final VoidCallback onDuplicate;
  final VoidCallback onSubstitute;
  final VoidCallback onRemove;
  final VoidCallback onEditPrescription;

  const _ExercicioRow({
    required this.te,
    required this.index,
    required this.isDark,
    required this.primary,
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
    final isAdvanced = te.tipoSerie != 'NORMAL';
    final trustColor = _trustColor(te.exercicio, primary);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 4, 12),
      decoration: BoxDecoration(
        border:
            isLast ? null : Border(bottom: BorderSide(color: line, width: 0.5)),
      ),
      child: Row(
        children: [
          Semantics(
            label: 'Segure para reordenar ${te.exercicio.nomeDisplay}',
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.drag_indicator_rounded,
                size: 20,
                color: mute.withValues(alpha: 0.72),
              ),
            ),
          ),
          SizedBox(
            width: 22,
            child: Text(
              '$index',
              textAlign: TextAlign.center,
              style: FocuxHubTypography.metric(
                color: mute,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Material(
              color: fxTransparent,
              child: InkWell(
                onTap: onEditPrescription,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        te.exercicio.nomeDisplay,
                        style: FocuxHubTypography.cardTitle(color: ink),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${te.series}×${te.repeticoes} · ${_formatLoadKg(te.cargaKg)} · ${te.descansoSegundos ?? 60}s',
                        style: FocuxHubTypography.metric(
                          color: mute,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isAdvanced ||
                          te.exercicio.showMediaBadgeInWorkoutList ||
                          te.observacoes?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (te.exercicio.showMediaBadgeInWorkoutList)
                              _ExerciseMeta(
                                icon: _trustIcon(te.exercicio),
                                text: te.exercicio.mediaTrustLabel,
                                color: trustColor,
                              ),
                            if (isAdvanced)
                              _ExerciseMeta(
                                icon:
                                    te.tipoSerie == 'SUPERSET'
                                        ? Icons.link_rounded
                                        : Icons.trending_down_rounded,
                                text:
                                    te.tipoSerie == 'SUPERSET'
                                        ? 'superset ${te.grupoSuperset ?? '-'}'
                                        : 'drop set',
                                color:
                                    te.tipoSerie == 'SUPERSET'
                                        ? primary
                                        : EagleTokens.warn,
                              ),
                            if (te.observacoes?.trim().isNotEmpty == true)
                              _ExerciseMeta(
                                icon: Icons.notes_rounded,
                                text: te.observacoes!.trim(),
                                color: mute,
                              ),
                          ],
                        ),
                      ],
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
                  TreinosLayout.touchTarget,
                  TreinosLayout.touchTarget,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(Icons.more_horiz_rounded, color: mute, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

Color _trustColor(Exercicio exercicio, Color primary) {
  return switch (exercicio.mediaTrustLevel) {
    'READY' => exercicio.isPersonalUpload ? primary : EagleTokens.good,
    'NO_VIDEO' => EagleTokens.bad,
    _ => EagleTokens.warn,
  };
}

IconData _trustIcon(Exercicio exercicio) {
  return switch (exercicio.mediaTrustLevel) {
    'READY' =>
      exercicio.isPersonalUpload
          ? Icons.workspace_premium_rounded
          : Icons.verified_rounded,
    'NO_VIDEO' => Icons.videocam_off_outlined,
    _ => Icons.rate_review_outlined,
  };
}

class _ExerciseMeta extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color color;

  const _ExerciseMeta({this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
        ],
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FocuxHubTypography.bodyMuted(
              color: color,
              fontWeight: FontWeight.w700,
            ).copyWith(fontSize: 11.5),
          ),
        ),
      ],
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
