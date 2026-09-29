part of 'alunos_list_screen.dart';

extension AlunosListScreenFilters on _AlunosListScreenState {
  void _setQueryText(String value) {
    _query = value;
    _searchController.text = value;
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final query = AlunosHomeQuery(
        q: _query,
        filtro: _filtro,
        ordenacao: _ordenacao,
      );
      final cached = AlunosHomeClientCache.getIfFresh(query);
      setState(() {
        _listRefreshing = cached == null;
        if (cached != null) _displayHome = cached;
      });
      _syncHomeQuery();
      AnalyticsService.instance.track(ProductEvents.alunosSearchUsed);
    });
  }

  void _limparBusca() {
    _searchController.clear();
    _onSearchChanged('');
    final location = GoRouterState.of(context).uri;
    if (location.queryParameters.containsKey('q')) {
      context.go(alunosLocationSemBusca(location));
    }
  }

  Future<void> _showListOptions() async {
    HapticFeedback.selectionClick();
    AnalyticsService.instance.track(ProductEvents.alunosOrganizeOpened);
    await showFxHomeSheet<void>(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final primary = Theme.of(ctx).colorScheme.primary;
        final linkColor = BrandPalette.sectionLink(primary, dark: isDark);
        final brand = BrandPalette.softened(primary);

        return FxHomeSheetScaffold(
          isDark: isDark,
          leading: Icon(Icons.tune_rounded, color: brand, size: 22),
          title: 'Organizar alunos',
          subtitle: 'Como a lista aparece agora.',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxSettingsGroup(
                header: 'Ordenação',
                caption: 'Como a lista é priorizada.',
                edgeToEdgeRows: true,
                accent: primary,
                children: FxInsetPickerOption.list(
                  accent: brand,
                  items: [
                    FxInsetPickerOptionSpec(
                      label: 'Prioridade do dia',
                      subtitle: 'Risco, inadimplência e convites primeiro.',
                      icon: Icons.priority_high_rounded,
                      selected: _ordenacao == AlunoOrdenacao.prioridade,
                      onTap: () {
                        _setOrdenacao(AlunoOrdenacao.prioridade);
                        Navigator.pop(ctx);
                      },
                    ),
                    FxInsetPickerOptionSpec(
                      label: 'Nome A-Z',
                      subtitle: 'Ordem alfabética.',
                      icon: Icons.sort_by_alpha_rounded,
                      selected: _ordenacao == AlunoOrdenacao.nome,
                      onTap: () {
                        _setOrdenacao(AlunoOrdenacao.nome);
                        Navigator.pop(ctx);
                      },
                    ),
                    FxInsetPickerOptionSpec(
                      label: 'Sem foto primeiro',
                      subtitle: 'Perfis genéricos no topo.',
                      icon: Icons.no_photography_outlined,
                      selected: _ordenacao == AlunoOrdenacao.semFoto,
                      onTap: () {
                        _setOrdenacao(AlunoOrdenacao.semFoto);
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FxSettingsLayout.groupGap),
              FxSettingsGroup(
                accent: primary,
                children: [
                  _AlunosCompactToggleRow(
                    value: _listaCompacta,
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      final next = !_listaCompacta;
                      setState(() => _listaCompacta = next);
                      await AlunoListPreferencesStore.saveCompact(next);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
              const SizedBox(height: TokensStrip.s3),
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
                    size: FxHelpChrome.glyphSize,
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
        );
      },
    );
  }
}
