part of 'alunos_list_screen.dart';

extension AlunosListScreenFilters on _AlunosListScreenState {
  Future<void> _showListOptions() async {
    HapticFeedback.selectionClick();
    AnalyticsService.instance.track(ProductEvents.alunosOrganizeOpened);
    await showFxHomeSheet<void>(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final chrome = ShellChrome.forDark(isDark);
        final ink = chrome.ink;
        final mute = chrome.mute;
        final primary = Theme.of(ctx).colorScheme.primary;
        final linkColor = BrandPalette.sectionLink(primary, dark: isDark);

        Widget option({
          required String title,
          required String subtitle,
          required IconData icon,
          required bool selected,
          required VoidCallback onTap,
        }) {
          return InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
              Navigator.pop(ctx);
            },
            borderRadius: BorderRadius.circular(TokensStrip.rCard),
            child: DecoratedBox(
              decoration: fxStripCardDecoration(
                ctx,
                accent: selected ? primary : null,
                radius: TokensStrip.rCard,
                glowStrength: selected ? 0.06 : 0.03,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color:
                            selected
                                ? primary.withValues(
                                  alpha: isDark ? 0.22 : 0.12,
                                )
                                : primary.withValues(
                                  alpha: isDark ? 0.14 : 0.08,
                                ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        selected ? Icons.check_rounded : icon,
                        color: selected ? primary : linkColor,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: FocuxHubTypography.sectionTitle(
                              ctx,
                              color: ink,
                            ).copyWith(fontSize: TokensStrip.fontBody),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: FocuxHubTypography.bodyMuted(
                              color: mute,
                            ).copyWith(height: 1.25),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return FxHomeSheetSurface(
          isDark: isDark,
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.56,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FxHomeSheetHandle(isDark: isDark),
                SizedBox(height: TokensStrip.s4),
                FxHomeSheetHeader(
                  isDark: isDark,
                  title: 'Organizar alunos',
                  subtitle: 'Escolha como a lista deve aparecer agora.',
                  leading: Icon(Icons.tune_rounded, color: primary, size: 18),
                  trailing: TextButton(
                    onPressed: () {
                      setState(() {
                        _filtro = AlunoFiltro.todos;
                        _ordenacao = AlunoOrdenacao.prioridade;
                        _listaCompacta = true;
                      });
                      AlunoListPreferencesStore.saveCompact(true);
                      _syncHomeQuery();
                      Navigator.pop(ctx);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: linkColor,
                      minimumSize: const Size(
                        FxHomeSheetChrome.touchTarget,
                        FxHomeSheetChrome.touchTarget,
                      ),
                    ),
                    child: const Text('Redefinir'),
                  ),
                ),
                const SizedBox(height: TokensStrip.s4),
                option(
                  title: 'Prioridade do dia',
                  subtitle:
                      'Risco, inadimplência e convites aparecem primeiro.',
                  icon: Icons.priority_high_rounded,
                  selected: _ordenacao == AlunoOrdenacao.prioridade,
                  onTap: () => _setOrdenacao(AlunoOrdenacao.prioridade),
                ),
                const SizedBox(height: 8),
                option(
                  title: 'Nome A-Z',
                  subtitle: 'Lista alfabética para encontrar alunos rápido.',
                  icon: Icons.sort_by_alpha_rounded,
                  selected: _ordenacao == AlunoOrdenacao.nome,
                  onTap: () => _setOrdenacao(AlunoOrdenacao.nome),
                ),
                const SizedBox(height: 8),
                option(
                  title: 'Sem foto primeiro',
                  subtitle:
                      'Ajuda a completar perfis que ainda parecem genéricos.',
                  icon: Icons.no_photography_outlined,
                  selected: _ordenacao == AlunoOrdenacao.semFoto,
                  onTap: () => _setOrdenacao(AlunoOrdenacao.semFoto),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    final next = !_listaCompacta;
                    setState(() => _listaCompacta = next);
                    await AlunoListPreferencesStore.saveCompact(next);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(TokensStrip.rCard),
                  child: DecoratedBox(
                    decoration: fxStripCardDecoration(
                      ctx,
                      accent: _listaCompacta ? primary : null,
                      radius: TokensStrip.rCard,
                      glowStrength: _listaCompacta ? 0.06 : 0.03,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: primary.withValues(
                                alpha: isDark ? 0.22 : 0.12,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.density_small_rounded,
                              color: linkColor,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lista compacta',
                                  style: FocuxHubTypography.sectionTitle(
                                    ctx,
                                    color: ink,
                                  ).copyWith(fontSize: TokensStrip.fontBody),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AlunosMicrocopy.densitySubtitle,
                                  style: FocuxHubTypography.bodyMuted(
                                    color: mute,
                                  ).copyWith(height: 1.25),
                                ),
                              ],
                            ),
                          ),
                          IgnorePointer(
                            child: Switch.adaptive(
                              value: _listaCompacta,
                              onChanged: (_) {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  button: true,
                  label: 'Ajuda da lista de alunos',
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openHelp();
                    },
                    icon: FxIcon(
                      name: FxHelpChrome.iconName,
                      size: 18,
                      color: linkColor,
                    ),
                    label: Text(
                      'Como usar a lista',
                      style: TextStyle(
                        color: linkColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
