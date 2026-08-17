part of 'alunos_list_screen.dart';

class _FxChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FxChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final action = BrandPalette.sectionAction(primary, dark: isDark);
    final bg =
        isSelected
            ? primary
            : (isDark
                ? Colors.white.withValues(alpha: 0.055)
                : Colors.white.withValues(alpha: 0.78));
    final color =
        isSelected
            ? Colors.white
            : (isDark ? EagleTokens.darkInk : TokensStrip.textPrimary);
    final border =
        isSelected
            ? Border.all(color: action.withValues(alpha: isDark ? 0.45 : 0.28))
            : Border.all(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.09)
                      : TokensStrip.borderDefault,
            );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: border,
          boxShadow: [
            if (isSelected && !isDark)
              BoxShadow(
                color: primary.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: -6,
              ),
            if (isSelected && isDark)
              BoxShadow(
                color: action.withValues(alpha: 0.28),
                blurRadius: 12,
                spreadRadius: -2,
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTypography.inter(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
                height: 1.15,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Colors.white
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : TokensStrip.pageBg),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: AppTypography.inter(
                  color:
                      isSelected
                          ? primary
                          : (isDark
                              ? EagleTokens.darkInkMute
                              : TokensStrip.textSecondary),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetShortcutChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SheetShortcutChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color:
              selected
                  ? primary
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : TokensStrip.cardBg),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                selected
                    ? primary
                    : (isDark
                        ? EagleTokens.darkLine
                        : TokensStrip.borderDefault),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.inter(
            color: selected ? Colors.white : ink,
            fontSize: TokensStrip.fontBodySm,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _EmptyAlunosState extends StatelessWidget {
  final bool hasQuery;
  final bool hasActiveFilter;
  final String filtroLabel;
  final VoidCallback? onClear;
  final VoidCallback? onClearFilter;
  final VoidCallback? onAdd;

  const _EmptyAlunosState({
    required this.hasQuery,
    this.hasActiveFilter = false,
    this.filtroLabel = '',
    this.onClear,
    this.onClearFilter,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final filteredEmpty = hasActiveFilter && !hasQuery;

    final title =
        hasQuery
            ? 'Nenhum aluno encontrado'
            : filteredEmpty
            ? 'Nenhum aluno neste filtro'
            : 'Nenhum aluno cadastrado';
    final subtitle =
        hasQuery
            ? 'Tente buscar por outro nome, objetivo ou e-mail.'
            : filteredEmpty
            ? 'Não há alunos $filtroLabel no momento. Limpe o filtro ou mude a visualização.'
            : 'Adicione o primeiro aluno para montar treinos e acompanhar a evolução.';
    final icon = hasQuery || filteredEmpty ? 'search' : 'users';

    FxEmptyAction? action;
    if (onClearFilter != null) {
      action = FxEmptyAction(label: 'Limpar filtro', onTap: onClearFilter!);
    } else if (onClear != null) {
      action = FxEmptyAction(label: 'Limpar busca', onTap: onClear!);
    } else if (onAdd != null) {
      action = FxEmptyAction(label: 'Adicionar aluno', onTap: onAdd!);
    }

    return FxEmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      action: action,
    );
  }
}
