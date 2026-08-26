part of 'alunos_list_screen.dart';

extension AlunosListScreenFilters on _AlunosListScreenState {
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
                children: [
                  _AlunosSheetCheckRow(
                    icon: Icons.priority_high_rounded,
                    label: 'Prioridade do dia',
                    subtitle:
                        'Risco, inadimplência e convites aparecem primeiro.',
                    selected: _ordenacao == AlunoOrdenacao.prioridade,
                    onTap: () {
                      _setOrdenacao(AlunoOrdenacao.prioridade);
                      Navigator.pop(ctx);
                    },
                  ),
                  _AlunosSheetCheckRow(
                    icon: Icons.sort_by_alpha_rounded,
                    label: 'Nome A-Z',
                    subtitle: 'Lista alfabética para encontrar alunos rápido.',
                    selected: _ordenacao == AlunoOrdenacao.nome,
                    onTap: () {
                      _setOrdenacao(AlunoOrdenacao.nome);
                      Navigator.pop(ctx);
                    },
                  ),
                  _AlunosSheetCheckRow(
                    icon: Icons.no_photography_outlined,
                    label: 'Sem foto primeiro',
                    subtitle:
                        'Ajuda a completar perfis que ainda parecem genéricos.',
                    selected: _ordenacao == AlunoOrdenacao.semFoto,
                    onTap: () {
                      _setOrdenacao(AlunoOrdenacao.semFoto);
                      Navigator.pop(ctx);
                    },
                  ),
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
