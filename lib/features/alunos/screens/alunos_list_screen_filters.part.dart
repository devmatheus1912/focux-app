part of 'alunos_list_screen.dart';

extension AlunosListScreenFilters on _AlunosListScreenState {
  Future<void> _showListOptions() async {
    HapticFeedback.selectionClick();
    AnalyticsService.instance.track(ProductEvents.alunosOrganizeOpened);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
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
                                ? primary.withValues(alpha: isDark ? 0.22 : 0.12)
                                : primary.withValues(alpha: isDark ? 0.14 : 0.08),
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

        final sheetMaxHeight = MediaQuery.sizeOf(ctx).height * 0.72;

        return DecoratedBox(
          decoration: chrome.bottomSheet(),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: sheetMaxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Organizar alunos',
                          style: FocuxHubTypography.pageTitle(
                            ctx,
                            color: ink,
                          ).copyWith(
                            fontSize: TokensStrip.fontH2,
                            fontWeight: TokensStrip.weightH2,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _filtro = AlunoFiltro.todos;
                            _ordenacao = AlunoOrdenacao.prioridade;
                          });
                          _syncHomeQuery();
                          Navigator.pop(ctx);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: linkColor,
                          textStyle: AppTypography.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: TokensStrip.fontBodySm,
                          ),
                        ),
                        child: const Text('Redefinir'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Escolha como a lista deve aparecer agora.',
                    style: FocuxHubTypography.bodyMuted(color: mute),
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
                  option(
                    title: 'Lista compacta',
                    subtitle:
                        'Menos ruído: oculta e-mail na lista e reduz o card.',
                    icon: Icons.density_small_rounded,
                    selected: _listaCompacta,
                    onTap: () async {
                      final next = !_listaCompacta;
                      setState(() => _listaCompacta = next);
                      await AlunoListPreferencesStore.saveCompact(next);
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Atalhos de foco',
                    style: FocuxHubTypography.eyebrow(
                      ctx,
                      color: ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SheetShortcutChip(
                        label: 'Contato hoje',
                        selected: _filtro == AlunoFiltro.contatoHoje,
                        onTap: () {
                          _setFiltro(AlunoFiltro.contatoHoje);
                          Navigator.pop(ctx);
                        },
                      ),
                      _SheetShortcutChip(
                        label: 'Risco alto',
                        selected: _filtro == AlunoFiltro.risco,
                        onTap: () {
                          _setFiltro(AlunoFiltro.risco);
                          Navigator.pop(ctx);
                        },
                      ),
                      _SheetShortcutChip(
                        label: 'Em atraso',
                        selected: _filtro == AlunoFiltro.inadimplentes,
                        onTap: () {
                          _setFiltro(AlunoFiltro.inadimplentes);
                          Navigator.pop(ctx);
                        },
                      ),
                      _SheetShortcutChip(
                        label: 'Convites',
                        selected: _filtro == AlunoFiltro.novos,
                        onTap: () {
                          _setFiltro(AlunoFiltro.novos);
                          Navigator.pop(ctx);
                        },
                      ),
                      _SheetShortcutChip(
                        label: 'Todos',
                        selected: _filtro == AlunoFiltro.todos,
                        onTap: () {
                          _setFiltro(AlunoFiltro.todos);
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
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
                      icon: Icon(
                        Icons.help_outline_rounded,
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
          ),
        );
      },
    );
  }

}
