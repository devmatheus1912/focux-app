part of 'alunos_list_screen.dart';

class _AlunosListRefreshing extends StatelessWidget {
  const _AlunosListRefreshing({
    required this.isDark,
    required this.compact,
  });

  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final itemHeight = compact ? 56.0 : 88.0;
    final gap =
        compact ? AlunosLayout.listItemGapCompact : AlunosLayout.listItemGap;

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        left: AlunosLayout.screenPadding,
        right: AlunosLayout.screenPadding,
        top: 8,
        bottom: 8,
      ),
      itemCount: 4,
      separatorBuilder: (_, __) => SizedBox(height: gap),
      itemBuilder:
          (_, __) => FxLoading.sectionShimmer(
            context,
            height: itemHeight,
            showHeader: false,
          ),
    );
  }
}

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
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label, $count alunos',
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(TokensStrip.rPill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Colors.transparent
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.72)),
          borderRadius: BorderRadius.circular(TokensStrip.rPill),
          border: Border.all(
            color:
                isSelected
                    ? primary.withValues(alpha: isDark ? 0.55 : 0.42)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : primary.withValues(alpha: 0.10)),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              softWrap: false,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: dashboardChipLabelStyle(
                isSelected ? primary : ink,
              ).copyWith(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 6),
            Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? primary.withValues(alpha: isDark ? 0.14 : 0.10)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(TokensStrip.rPill),
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: dashboardChipLabelStyle(
                  isSelected ? primary : mute,
                ).copyWith(fontSize: 10.5, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _AlunosSheetCheckRow extends StatelessWidget {
  const _AlunosSheetCheckRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final brand = BrandPalette.softened(Theme.of(context).colorScheme.primary);
    final detail = subtitle?.trim();
    final hasSubtitle = detail != null && detail.isNotEmpty;

    return Semantics(
      button: true,
      selected: selected,
      label: hasSubtitle ? '$label. $detail' : label,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: FxSettingsLayout.rowMinHeight,
          ),
          child: Row(
            children: [
              Icon(icon, size: FxSettingsLayout.iconSize, color: brand),
              const SizedBox(width: FxSettingsLayout.iconGap),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border:
                        showDivider
                            ? Border(
                              bottom: BorderSide(
                                color: chrome.line,
                                width: FxSettingsLayout.dividerThickness,
                              ),
                            )
                            : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: TokensStrip.s3,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                maxLines: hasSubtitle ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: FxSettingsLayout.rowLabel(
                                  color: chrome.ink,
                                ),
                              ),
                              if (hasSubtitle) ...[
                                const SizedBox(
                                  height: FxSettingsLayout.captionAfterHeader,
                                ),
                                Text(
                                  detail,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: FxSettingsLayout.subhead(
                                    color: chrome.mute,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (selected)
                          Icon(
                            Icons.check,
                            color: brand,
                            size: FxSettingsLayout.iconSize,
                          ),
                      ],
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

class _AlunosCompactToggleRow extends StatelessWidget {
  const _AlunosCompactToggleRow({required this.value, required this.onTap});

  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final brand = BrandPalette.softened(Theme.of(context).colorScheme.primary);

    return Semantics(
      button: true,
      toggled: value,
      label: AlunosMicrocopy.densityTitle,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: FxSettingsLayout.rowMinHeight,
          ),
          child: Row(
            children: [
              Icon(
                Icons.density_small_rounded,
                size: FxSettingsLayout.iconSize,
                color: brand,
              ),
              const SizedBox(width: FxSettingsLayout.iconGap),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: TokensStrip.s3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AlunosMicrocopy.densityTitle,
                        style: FxSettingsLayout.rowLabel(color: chrome.ink),
                      ),
                      const SizedBox(
                        height: FxSettingsLayout.captionAfterHeader,
                      ),
                      Text(
                        AlunosMicrocopy.densitySubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: FxSettingsLayout.subhead(color: chrome.mute),
                      ),
                    ],
                  ),
                ),
              ),
              IgnorePointer(
                child: Switch.adaptive(value: value, onChanged: (_) {}),
              ),
            ],
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
            ? context.alunosL10n.alunosEmptySearch
            : filteredEmpty
            ? 'Nenhum aluno neste filtro'
            : context.alunosL10n.alunosEmptyNone;
    final subtitle =
        hasQuery
            ? context.alunosL10n.alunosEmptySearchSubtitle
            : filteredEmpty
            ? 'Não há alunos $filtroLabel no momento. Limpe o filtro ou mude a visualização.'
            : context.alunosL10n.alunosEmptyNoneSubtitle;
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
