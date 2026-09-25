part of 'treinos_list_screen.dart';

class _LibraryControls extends StatelessWidget {
  const _LibraryControls({
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.isDark,
    required this.primary,
    required this.onQueryChanged,
    required this.onClearQuery,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final bool isDark;
  final Color primary;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forBrightness(context, isDark);
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
            focusNode: focusNode,
            onSubmitted: (_) => focusNode.unfocus(),
            onTapOutside: (_) => focusNode.unfocus(),
            textInputAction: TextInputAction.search,
            style: FocuxHubTypography.cardTitle(
              color: ink,
            ).copyWith(fontSize: 13),
            decoration: InputDecoration(
              filled: false,
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
    final chrome = ShellChrome.forBrightness(context, isDark);
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
