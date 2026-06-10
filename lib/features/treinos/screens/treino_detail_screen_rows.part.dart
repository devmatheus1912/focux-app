part of 'treino_detail_screen.dart';

class _ExercicioRow extends StatelessWidget {
  final TreinoExercicioItem te;
  final int index;
  final bool isDark;
  final Color primary;
  final Color primarySoft;
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
    required this.primarySoft,
    required this.isLast,
    required this.onDuplicate,
    required this.onSubstitute,
    required this.onRemove,
    required this.onEditPrescription,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final isAdvanced = te.tipoSerie != 'NORMAL';
    final trustColor = _trustColor(te.exercicio, primary);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        border:
            isLast ? null : Border(bottom: BorderSide(color: line, width: 0.5)),
      ),
      child: Row(
        children: [
          Semantics(
            label: 'Segure para reordenar ${te.exercicio.nomeDisplay}',
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                Icons.drag_indicator_rounded,
                size: 20,
                color: mute.withValues(alpha: 0.72),
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: primary.withValues(alpha: 0.10)),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: AppTypography.mono(
                color: primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Material(
              color: Colors.transparent,
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
                  style: AppTypography.inter(
                    color: ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${te.series}×${te.repeticoes}',
                      style: AppTypography.mono(
                        color: ink,
                        fontSize: 12.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: mute,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatLoadKg(te.cargaKg),
                      style: AppTypography.mono(
                        color: ink,
                        fontSize: 12.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: mute,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.timer_outlined, size: 11, color: mute),
                    const SizedBox(width: 3),
                    Text(
                      '${te.descansoSegundos ?? 60}s',
                      style: AppTypography.mono(
                        color: mute,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
          InkWell(
            onTap: () async {
              HapticFeedback.selectionClick();
              final action = await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                barrierColor: Colors.black.withValues(alpha: 0.34),
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
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : TokensStrip.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : TokensStrip.borderDefault,
                ),
              ),
              child: Icon(Icons.more_vert_rounded, color: mute, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid texture painter — white lines 6% opacity, 26×26px cells.
/// Matches auth_shell.dart _AuthGridPainter; reused on hero surfaces.
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
            style: AppTypography.inter(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseActionsSheet extends StatelessWidget {
  final String title;
  final bool isDark;

  const _ExerciseActionsSheet({
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final border =
        isDark
            ? Colors.white.withValues(alpha: 0.08)
            : TokensStrip.borderDefault.withValues(alpha: 0.9);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: fxListCardDecoration(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : EagleTokens.brandSofter,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ações do exercício',
                          style: AppTypography.inter(
                            color: ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.inter(
                            color: mute,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TokensStrip.s4),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ExerciseActionTile(
                        icon: Icons.edit_note_rounded,
                        label: 'Editar prescrição',
                        onTap: () => Navigator.pop(context, 'edit'),
                      ),
                      _ExerciseActionTile(
                        icon: Icons.copy_rounded,
                        label: 'Duplicar item',
                        onTap: () => Navigator.pop(context, 'duplicate'),
                      ),
                      _ExerciseActionTile(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Substituir exercício',
                        onTap: () => Navigator.pop(context, 'substitute'),
                      ),
                      _ExerciseActionTile(
                        icon: Icons.remove_circle_outline_rounded,
                        label: 'Remover do treino',
                        color: EagleTokens.bad,
                        onTap: () => Navigator.pop(context, 'remove'),
                      ),
                    ],
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

class _ExerciseActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ExerciseActionTile({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink =
        color ?? (isDark ? EagleTokens.darkInk : TokensStrip.textPrimary);
    final border =
        isDark
            ? Colors.white.withValues(alpha: 0.06)
            : TokensStrip.borderDefault.withValues(alpha: 0.95);
    final iconFill =
        color == null
            ? (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : EagleTokens.brandSofter)
            : EagleTokens.bad.withValues(alpha: isDark ? 0.16 : 0.10);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.035)
                    : TokensStrip.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconFill,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: ink, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.inter(
                    color: ink,
                    fontSize: 13.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: ink, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

