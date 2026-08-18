part of 'treinos_list_screen.dart';

class _TreinoCard extends StatelessWidget {
  const _TreinoCard({
    required this.treino,
    required this.isDark,
    required this.primary,
    required this.alunoId,
    required this.alunoNome,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelection,
    required this.onStartSelection,
    required this.onActions,
  });

  final Treino treino;
  final bool isDark;
  final Color primary;
  final int? alunoId;
  final String? alunoNome;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onToggleSelection;
  final VoidCallback onStartSelection;
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final hasExercises = treino.pronto;
    final displayName = displayWorkoutName(treino.nome);
    final objetivo =
        treino.objetivo?.trim().isNotEmpty == true
            ? TreinosListLabels.prettyField(treino.objetivo!.trim())
            : hasExercises
            ? 'Plano pronto para atribuir'
            : 'Sem exercícios ainda';
    final meta = TreinosListLabels.cardMeta(
      pronto: hasExercises,
      exercises: treino.exerciciosCount,
      series: treino.seriesTotal,
      nivel: treino.nivel,
    );
    final cardSemantics =
        selectionMode
            ? selected
                ? 'Desmarcar $displayName'
                : 'Selecionar $displayName'
            : '$displayName, $meta, toque para abrir, segure para selecionar';

    return Semantics(
      label: cardSemantics,
      button: true,
      selected: selectionMode && selected,
      child: InkWell(
        onTap:
            selectionMode
                ? onToggleSelection
                : () => context.push(
                  '/treinos/${treino.id}',
                  extra:
                      alunoId == null
                          ? null
                          : {'alunoId': alunoId, 'alunoNome': alunoNome},
                ),
        onLongPress: onStartSelection,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
          decoration: fxListCardDecoration(
            context,
            accent: primary,
            selected: selected,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (selectionMode) ...[
                AnimatedSwitcher(
                  duration:
                      TokensStrip.prefersReducedMotion(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 150),
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    key: ValueKey(selected),
                    color: selected ? primary : mute,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: BrandPalette.soft(primary, dark: isDark),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  hasExercises
                      ? Icons.fitness_center_rounded
                      : Icons.build_circle_outlined,
                  color: primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FocuxHubTypography.cardTitle(color: ink),
                          ),
                        ),
                        if (treino.isTemplate) ...[
                          const SizedBox(width: 6),
                          _TinyBadge(
                            label: 'base',
                            color: primary,
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      objetivo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FocuxHubTypography.bodyMuted(
                        color: mute,
                      ).copyWith(fontSize: TokensStrip.fontBodySm),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: hasExercises ? primary : mute,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FocuxHubTypography.bodyMuted(
                              color: mute,
                              fontWeight: FontWeight.w700,
                            ).copyWith(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!selectionMode)
                Semantics(
                  button: true,
                  label: 'Ações do treino',
                  child: IconButton(
                    onPressed: onActions,
                    tooltip: 'Ações do treino',
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
        ),
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({
    required this.label,
    required this.color,
    required this.isDark,
  });

  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: BrandPalette.soft(color, dark: isDark),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: FocuxHubTypography.chip(color).copyWith(fontSize: 10),
      ),
    );
  }
}
