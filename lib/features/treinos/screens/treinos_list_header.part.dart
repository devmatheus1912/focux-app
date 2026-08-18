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
    required this.onCreate,
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
  final VoidCallback onCreate;
  final VoidCallback? onSelectAll;
  final VoidCallback onCancelSelection;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final primary = Theme.of(context).colorScheme.primary;
    final showBack = onBack != null;
    final compactChrome = TreinosLayout.isCompactChrome(
      MediaQuery.sizeOf(context).width,
    );
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
                        '$selectedCount selecionado${selectedCount == 1 ? '' : 's'}',
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
                if (!compactChrome && !showBack) ...[
                  const ShellThemeToggle(size: TreinosLayout.headerChromeSize),
                  const SizedBox(width: TreinosLayout.headerChromeGap),
                ],
                ShellHeaderIconButton(
                  icon: 'help',
                  size: TreinosLayout.headerChromeSize,
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
                const SizedBox(width: TreinosLayout.headerChromeGap),
                Semantics(
                  button: true,
                  label: 'Criar treino',
                  child: Material(
                    color: primary,
                    elevation: isDark ? 3 : 1,
                    shadowColor: primary.withValues(
                      alpha: isDark ? 0.35 : 0.18,
                    ),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onCreate,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: TreinosLayout.headerChromeSize,
                        height: TreinosLayout.headerChromeSize,
                        child: Icon(
                          Icons.add_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
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
    required this.selectionMode,
    required this.isDark,
    required this.primary,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onDeleteSelected,
  });

  final TextEditingController controller;
  final String query;
  final bool selectionMode;
  final bool isDark;
  final Color primary;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final VoidCallback? onDeleteSelected;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;

    if (selectionMode) {
      return DecoratedBox(
        decoration: fxStripCardDecoration(
          context,
          accent: primary,
          radius: TokensStrip.rCard,
          glowStrength: 0.03,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Ações em lote',
                  style: FocuxHubTypography.cardTitle(color: ink),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onDeleteSelected,
                icon: const Icon(Icons.delete_outline_rounded, size: 17),
                label: const Text('Excluir'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EagleTokens.bad,
                  side: const BorderSide(color: EagleTokens.bad),
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
            style: FocuxHubTypography.cardTitle(color: ink).copyWith(
              fontSize: 13,
            ),
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
