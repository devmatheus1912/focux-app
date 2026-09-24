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
    }
    // Create fica só no sticky — evita dois CTAs iguais no vazio.

    return FxEmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      action: action,
    );
  }
}
