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
    final chipBg = dashboardPrioritiesChipBackground(primary, isDark: isDark);
    final chipFg = dashboardPrioritiesChipForeground(primary, isDark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TokensStrip.rPill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? chipBg
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : BrandPalette.soft(primary, dark: false)),
          borderRadius: BorderRadius.circular(TokensStrip.rPill),
          border:
              isSelected
                  ? null
                  : Border.all(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : primary.withValues(alpha: 0.08),
                  ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: dashboardChipLabelStyle(
                isSelected ? chipFg : ink,
              ).copyWith(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 6),
            Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? chipFg.withValues(alpha: isDark ? 0.14 : 0.18)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.72)),
                borderRadius: BorderRadius.circular(TokensStrip.rPill),
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: dashboardChipLabelStyle(
                  isSelected ? chipFg : mute,
                ).copyWith(fontSize: 10.5, fontWeight: FontWeight.w900),
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
    final chipBg = dashboardPrioritiesChipBackground(primary, isDark: isDark);
    final chipFg = dashboardPrioritiesChipForeground(primary, isDark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TokensStrip.rPill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color:
              selected
                  ? chipBg
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : BrandPalette.soft(primary, dark: false)),
          borderRadius: BorderRadius.circular(TokensStrip.rPill),
          border:
              selected
                  ? null
                  : Border.all(color: line.withValues(alpha: 0.75)),
        ),
        child: Text(
          label,
          style: dashboardChipLabelStyle(
            selected ? chipFg : ink,
          ).copyWith(fontSize: TokensStrip.fontBodySm, fontWeight: FontWeight.w800),
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
