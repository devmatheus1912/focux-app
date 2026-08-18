part of 'treinos_list_screen.dart';

String _ptLabel(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return value;
  final normalized = value
      .toUpperCase()
      .replaceAll('Á', 'A')
      .replaceAll('Ã', 'A')
      .replaceAll('Â', 'A')
      .replaceAll('É', 'E')
      .replaceAll('Í', 'I')
      .replaceAll('Ó', 'O')
      .replaceAll('Õ', 'O')
      .replaceAll('Ú', 'U')
      .replaceAll('Ç', 'C');
  const labels = {
    'FORCA': 'Força',
    'HIPERTROFIA': 'Hipertrofia',
    'EMAGRECIMENTO': 'Emagrecimento',
    'CONDICIONAMENTO': 'Condicionamento',
    'MOBILIDADE': 'Mobilidade',
    'INICIANTE': 'Iniciante',
    'INTERMEDIARIO': 'Intermediário',
    'AVANCADO': 'Avançado',
  };
  return labels[normalized] ??
      value[0].toUpperCase() + value.substring(1).toLowerCase();
}

class _TreinoCard extends StatelessWidget {
  final Treino treino;
  final int index;
  final bool isDark;
  final Color primary;
  final int? alunoId;
  final String? alunoNome;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onToggleSelection;
  final VoidCallback onStartSelection;
  final VoidCallback onActions;

  const _TreinoCard({
    required this.treino,
    required this.index,
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

  IconData get _nivelIcon {
    switch (treino.nivel?.toUpperCase()) {
      case 'AVANCADO':
        return Icons.local_fire_department_rounded;
      case 'INTERMEDIARIO':
        return Icons.speed_rounded;
      default:
        return Icons.eco_rounded;
    }
  }

  Color get _nivelColor => primary;

  String get _nivelLabel {
    final nivel = treino.nivel?.trim();
    if (nivel == null || nivel.isEmpty) {
      return 'Iniciante';
    }
    return _ptLabel(nivel);
  }

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final hasExercises = treino.pronto;
    final series = treino.seriesTotal;
    final estimatedMinutes =
        hasExercises ? (treino.exerciciosCount * 5).clamp(12, 90) : 0;
    final displayName = displayWorkoutName(treino.nome);
    final cardSemantics =
        selectionMode
            ? selected
                ? 'Desmarcar $displayName'
                : 'Selecionar $displayName'
            : '$displayName, ${treino.exerciciosCount} exercícios, '
                'toque para abrir, segure para selecionar';

    return Semantics(
      label: cardSemantics,
      button: true,
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
          padding: const EdgeInsets.all(15),
          decoration: fxListCardDecoration(
            context,
            accent: primary,
            selected: selected,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: BrandPalette.soft(primary, dark: isDark),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Icon(
                      hasExercises
                          ? Icons.fitness_center_rounded
                          : Icons.build_circle_outlined,
                      color: primary,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: TokensStrip.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.5,
                                  color: ink,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                            if (treino.isTemplate) ...[
                              SizedBox(width: TokensStrip.s2),
                              _TinyBadge(
                                label: 'base',
                                color: primary,
                                isDark: isDark,
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: TokensStrip.s1),
                        Text(
                          treino.objetivo?.trim().isNotEmpty == true
                              ? _ptLabel(treino.objetivo!.trim())
                              : hasExercises
                              ? 'Plano pronto para atribuir'
                              : 'Estrutura aguardando exercícios',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.inter(
                            color: mute,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: TokensStrip.s3),
                  if (selectionMode)
                    Semantics(
                      label: selected ? 'Desmarcar treino' : 'Marcar treino',
                      child: Checkbox(
                        value: selected,
                        onChanged: (_) => onToggleSelection(),
                        activeColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                  else
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
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          color: mute,
                          size: 22,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: TokensStrip.s3),
              Row(
                children: [
                  Expanded(
                    child: _PlanPill(
                      icon: Icons.list_alt_rounded,
                      value:
                          '${treino.exerciciosCount} exerc${treino.exerciciosCount == 1 ? '.' : 's.'}',
                      isDark: isDark,
                      color: primary,
                    ),
                  ),
                  SizedBox(width: TokensStrip.s2),
                  Expanded(
                    child: _PlanPill(
                      icon: Icons.repeat_rounded,
                      value: hasExercises ? '$series séries' : 'em montagem',
                      isDark: isDark,
                      color: primary,
                    ),
                  ),
                  SizedBox(width: TokensStrip.s2),
                  Expanded(
                    child: _PlanPill(
                      icon: _nivelIcon,
                      value: _nivelLabel,
                      isDark: isDark,
                      color: _nivelColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: TokensStrip.s3),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: hasExercises ? 4 : 6,
                        value: hasExercises ? 1 : 0.28,
                        backgroundColor:
                            isDark
                                ? EagleTokens.darkLine
                                : TokensStrip.borderDefault,
                        valueColor: AlwaysStoppedAnimation(
                          hasExercises
                              ? primary.withValues(alpha: isDark ? 0.7 : 0.85)
                              : primary.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: TokensStrip.s3),
                  if (hasExercises)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: primary.withValues(
                            alpha: isDark ? 0.7 : 0.55,
                          ),
                        ),
                        SizedBox(width: TokensStrip.s1),
                        Text(
                          '~${estimatedMinutes}min',
                          style: AppTypography.mono(
                            color: mute,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'finalizar',
                      style: AppTypography.inter(
                        color: primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
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

class _PlanPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isDark;
  final Color color;

  const _PlanPill({
    required this.icon,
    required this.value,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final isMetric = RegExp(r'^\d').hasMatch(value) || value.startsWith('~');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: BrandPalette.soft(color, dark: isDark),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 13),
          SizedBox(width: TokensStrip.s1),
          Expanded(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style:
                    isMetric
                        ? AppTypography.mono(
                          color: ink,
                          fontSize: 10.2,
                          fontWeight: FontWeight.w800,
                        )
                        : AppTypography.inter(
                          color: ink,
                          fontSize: 10.2,
                          fontWeight: FontWeight.w800,
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _TinyBadge({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: BrandPalette.soft(color, dark: isDark),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
