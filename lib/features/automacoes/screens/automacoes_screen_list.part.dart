part of 'automacoes_screen.dart';

extension on _AutomacoesScreenState {
  Widget _buildList(
    List<AutomacaoTemplate> templates,
    List<AutomacaoFluxo> fluxos,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    final showMore = _hasMore && _chip != AutomacaoChip.templates;
    if (templates.isEmpty && fluxos.isEmpty) {
      final filtered =
          _query.trim().isNotEmpty || _chip != AutomacaoChip.todos;
      return RefreshIndicator(
        color: primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            FxEmptyState(
              icon: filtered ? 'search' : 'zap',
              title: filtered
                  ? 'Nenhuma automação encontrada'
                  : 'Nenhuma automação ainda',
              subtitle: filtered
                  ? 'Ajuste a busca ou o filtro.'
                  : 'Templates aparecem aqui para você ativar o primeiro fluxo.',
              action: filtered
                  ? FxEmptyAction(label: 'Limpar filtros', onTap: _clearQuery)
                  : null,
            ),
          ],
        ),
      );
    }

    final rows = <Object>[
      if (templates.isNotEmpty) ...['Templates', ...templates],
      if (fluxos.isNotEmpty) ...['Fluxos ativos', ...fluxos],
    ];

    return RefreshIndicator(
      color: primary,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          FxSettingsLayout.pageInset,
          TokensStrip.s6 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        itemCount: rows.length + (showMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (showMore && i == rows.length) {
            return FxSatelliteListTile(
              title: _carregandoMais ? 'Carregando…' : 'Carregar mais',
              onTap: _carregandoMais ? null : _carregarMais,
            );
          }
          final row = rows[i];
          if (row is String) {
            return Padding(
              padding: EdgeInsets.only(
                top: i == 0 ? 0 : TokensStrip.s3,
                bottom: TokensStrip.s2,
              ),
              child: Text(
                row,
                style: FocuxHubTypography.cardTitle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }
          if (row is AutomacaoTemplate) {
            return FxSatelliteListTile(
              title: row.nome,
              titleCase: false,
              subtitle: Text(
                row.descricao.trim().isEmpty
                    ? automacaoTriggerLabel(row.triggerTipo)
                    : row.descricao,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              leading: Icon(Icons.bolt_outlined, color: primary),
              trailing: Text(
                'Ativar',
                style: FocuxHubTypography.bodyMuted(
                  color: primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => _ativar(row),
            );
          }
          final fluxo = row as AutomacaoFluxo;
          return FxSatelliteListTile(
            title: fluxo.nome,
            titleCase: false,
            subtitle: Text(automacaoTriggerLabel(fluxo.triggerTipo)),
            leading: Icon(
              fluxo.ativo
                  ? Icons.play_circle_rounded
                  : Icons.pause_circle_rounded,
              color: primary,
            ),
            trailing: Text(
              automacaoFluxoStatusLabel(ativo: fluxo.ativo),
              style: FocuxHubTypography.bodyMuted(
                color: fxScreenMute(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => _openLogs(fluxo),
          );
        },
      ),
    );
  }
}
