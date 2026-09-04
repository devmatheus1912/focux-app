part of 'treinos_list_screen.dart';

class _TreinosHeader extends StatelessWidget {
  const _TreinosHeader({
    required this.alunoId,
    required this.alunoNome,
    required this.isDark,
    required this.freshnessLabel,
    required this.selectionMode,
    required this.selectedCount,
    required this.onBack,
    required this.onHelp,
    required this.onSelectAll,
    required this.onCancelSelection,
  });

  final int? alunoId;
  final String? alunoNome;
  final bool isDark;
  final String? freshnessLabel;
  final bool selectionMode;
  final int selectedCount;
  final VoidCallback? onBack;
  final VoidCallback onHelp;
  final VoidCallback? onSelectAll;
  final VoidCallback onCancelSelection;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final primary = Theme.of(context).colorScheme.primary;
    final showBack = onBack != null;
    final title =
        alunoId == null
            ? 'Treinos'
            : (alunoNome == null || alunoNome!.trim().isEmpty)
            ? 'Treinos do aluno'
            : 'Treinos de ${alunoNome!.trim()}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TreinosLayout.screenPadding,
        TokensStrip.s3,
        TreinosLayout.screenPadding,
        TokensStrip.s2,
      ),
      child: DecoratedBox(
        decoration: fxStripCardDecoration(
          context,
          accent: primary,
          radius: TokensStrip.rCard,
          glowStrength: selectionMode ? 0.02 : 0.04,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showBack) ...[
                IconButton(
                  onPressed: onBack,
                  tooltip: 'Voltar',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(
                      TreinosLayout.headerChromeSize,
                      TreinosLayout.headerChromeSize,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
                  icon: Container(
                    width: TreinosLayout.headerChromeSize,
                    height: TreinosLayout.headerChromeSize,
                    decoration: chrome.headerAction(
                      radius: TreinosLayout.headerChromeSize / 2,
                    ),
                    child: Center(
                      child: FxIcon(name: 'arrow-left', size: 18, color: ink),
                    ),
                  ),
                ),
                const SizedBox(width: TreinosLayout.headerChromeGap),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectionMode) ...[
                      Text(
                        TreinosListLabels.selectionCount(selectedCount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FocuxHubTypography.eyebrow(
                          context,
                          color: BrandPalette.sectionAction(
                            primary,
                            dark: isDark,
                          ),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.08,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FocuxHubTypography.pageTitle(
                        context,
                        color: ink,
                      ).copyWith(fontWeight: FontWeight.w800, height: 1.12),
                    ),
                    if (freshnessLabel != null &&
                        freshnessLabel!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          freshnessLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FocuxHubTypography.bodyMuted(
                            color: mute,
                            fontWeight: FontWeight.w600,
                          ).copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: TreinosLayout.headerChromeGap),
              if (selectionMode)
                InkWell(
                  onTap: onCancelSelection,
                  borderRadius: BorderRadius.circular(
                    TreinosLayout.headerChromeSize / 2,
                  ),
                  child: Container(
                    width: TreinosLayout.headerChromeSize,
                    height: TreinosLayout.headerChromeSize,
                    decoration: chrome.headerAction(
                      radius: TreinosLayout.headerChromeSize / 2,
                    ),
                    child: Icon(Icons.close, size: 20, color: ink),
                  ),
                )
              else ...[
                FxHelpIconButton(
                  tooltip: 'Como usar a biblioteca',
                  onTap: onHelp,
                ),
                const SizedBox(width: TreinosLayout.headerChromeGap),
                Semantics(
                  button: true,
                  label: 'Selecionar treinos',
                  child: InkWell(
                    onTap: onSelectAll,
                    borderRadius: BorderRadius.circular(
                      TreinosLayout.headerChromeSize / 2,
                    ),
                    child: Container(
                      width: TreinosLayout.headerChromeSize,
                      height: TreinosLayout.headerChromeSize,
                      decoration: chrome.headerAction(
                        radius: TreinosLayout.headerChromeSize / 2,
                      ),
                      child: Icon(
                        Icons.checklist_rounded,
                        size: 20,
                        color: onSelectAll == null ? mute : ink,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryControls extends StatelessWidget {
  const _LibraryControls({
    required this.controller,
    required this.query,
    required this.isDark,
    required this.primary,
    required this.onQueryChanged,
    required this.onClearQuery,
  });

  final TextEditingController controller;
  final String query;
  final bool isDark;
  final Color primary;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;

    return DecoratedBox(
      decoration: fxStripCardDecoration(
        context,
        accent: primary,
        radius: TokensStrip.rCard,
        glowStrength: 0.03,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
        child: Semantics(
          label: 'Buscar treino por nome, objetivo ou nível',
          child: TextField(
            onChanged: onQueryChanged,
            controller: controller,
            textInputAction: TextInputAction.search,
            style: FocuxHubTypography.cardTitle(
              color: ink,
            ).copyWith(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Buscar treino, objetivo ou nível',
              hintStyle: FocuxHubTypography.bodyMuted(color: mute),
              prefixIcon: Icon(Icons.search_rounded, color: primary, size: 20),
              suffixIcon:
                  query.trim().isEmpty
                      ? null
                      : IconButton(
                        onPressed: onClearQuery,
                        tooltip: 'Limpar busca',
                        icon: Icon(Icons.close_rounded, color: mute, size: 18),
                      ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.isDark,
  });

  final String title;
  final String action;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: FocuxHubTypography.sectionTitle(context, color: ink),
          ),
        ),
        Text(
          action,
          style: FocuxHubTypography.bodyMuted(
            color: mute,
            fontWeight: FontWeight.w700,
          ).copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

class _TreinosBulkBar extends StatelessWidget {
  const _TreinosBulkBar({
    required this.allSelected,
    required this.isDark,
    required this.onToggleAll,
    required this.onDelete,
  });

  final bool allSelected;
  final bool isDark;
  final VoidCallback onToggleAll;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final reduceMotion = TokensStrip.prefersReducedMotion(context);

    return AnimatedPadding(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
      padding: EdgeInsets.fromLTRB(
        TreinosLayout.screenPadding,
        8,
        TreinosLayout.screenPadding,
        TreinosLayout.bulkBarPaddingBottom +
            MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: allSelected ? 'Desmarcar todos' : 'Selecionar todos',
              child: OutlinedButton.icon(
                onPressed: onToggleAll,
                icon: Icon(
                  allSelected ? Icons.deselect_rounded : Icons.done_all_rounded,
                  size: 18,
                ),
                label: Text(
                  allSelected ? 'Desmarcar todos' : 'Selecionar todos',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(
                    TreinosLayout.touchTarget,
                    TreinosLayout.touchTarget,
                  ),
                  side: BorderSide(
                    color:
                        isDark
                            ? EagleTokens.darkLine
                            : primary.withValues(alpha: 0.18),
                  ),
                  foregroundColor: chrome.ink,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              button: true,
              label: 'Excluir treinos selecionados',
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text(
                  'Excluir',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(
                    TreinosLayout.touchTarget,
                    TreinosLayout.touchTarget,
                  ),
                  foregroundColor: EagleTokens.bad,
                  side: BorderSide(
                    color: EagleTokens.bad.withValues(alpha: 0.45),
                  ),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
