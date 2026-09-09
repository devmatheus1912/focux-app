part of 'alunos_list_screen.dart';

extension AlunosListScreenHeader on _AlunosListScreenState {
  Widget _buildAlunosListHeader({
    required int contatoCount,
    required int ativosCount,
    required int inadCount,
    required int riscoCount,
    required int novosCount,
    required bool isDark,
    required Color primary,
    required Color ink,
    required Color mute,
  }) {
    return FxPremiumEntrance(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_modoSelecao) ...[
            Padding(
              padding: AlunosLayout.searchBarOuterPadding,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ListenableBuilder(
                      listenable: _searchFocusNode,
                      builder: (context, _) {
                        final focused = _searchFocusNode.hasFocus;
                        return AnimatedContainer(
                          duration:
                              TokensStrip.prefersReducedMotion(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? EagleTokens.darkCard
                                    : Colors.white.withValues(alpha: 0.86),
                            borderRadius: BorderRadius.circular(
                              AlunosLayout.searchBarRadius,
                            ),
                            border: Border.all(
                              color:
                                  focused
                                      ? primary.withValues(alpha: 0.32)
                                      : (isDark
                                          ? EagleTokens.darkLine
                                          : TokensStrip.borderDefault),
                              width: focused ? 1.2 : 1,
                            ),
                            boxShadow: [
                              if (focused && !isDark)
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.08),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                  spreadRadius: -12,
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: AlunosLayout.searchBarPadding,
                    child: Row(
                      children: [
                        ListenableBuilder(
                          listenable: _searchFocusNode,
                          builder: (context, _) {
                            final focused = _searchFocusNode.hasFocus;
                            return Icon(
                              Icons.search_rounded,
                              size: 18,
                              color: focused ? primary : mute,
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Semantics(
                            label: context.alunosL10n.alunosSearchA11y,
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onChanged: _onSearchChanged,
                              onSubmitted: (_) => _searchFocusNode.unfocus(),
                              onTapOutside: (_) => _searchFocusNode.unfocus(),
                              textInputAction: TextInputAction.search,
                              cursorColor: primary,
                              style: FocuxHubTypography.body(color: ink).copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                hintText: context.alunosL10n.alunosSearchHint,
                                hintStyle: FocuxHubTypography.body(
                                  color: mute,
                                ).copyWith(fontWeight: FontWeight.w500),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          InkWell(
                            onTap: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            borderRadius: BorderRadius.circular(999),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(Icons.close, size: 18, color: mute),
                            ),
                          )
                        else
                          Tooltip(
                            message: AlunosMicrocopy.organizeTooltip,
                            child: InkWell(
                              onTap: _showListOptions,
                              borderRadius: BorderRadius.circular(999),
                              child: SizedBox(
                                width: 34,
                                height: 34,
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: FxSettingsLayout.iconSize,
                                      color: primary,
                                    ),
                                    if (_ordenacao !=
                                            AlunoOrdenacao.prioridade ||
                                        _filtro != AlunoFiltro.todos)
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  isDark
                                                      ? EagleTokens.darkCard
                                                      : TokensStrip.cardBg,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: AlunosLayout.filterRowPadding,
              child: FxHorizontalScrollPeek(
                showPeek: true,
                showStartPeek: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.hardEdge,
                  child: Row(
                    children: [
                      _alunosFilterChip(
                        filtro: AlunoFiltro.contatoHoje,
                        label: context.alunosL10n.alunosFilterContactToday,
                        count: contatoCount,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _alunosFilterChip(
                        filtro: AlunoFiltro.ativos,
                        label: context.alunosL10n.alunosFilterActive,
                        count: ativosCount,
                        isDark: isDark,
                      ),
                      if (_temFinanceiro) ...[
                        const SizedBox(width: 8),
                        _alunosFilterChip(
                          filtro: AlunoFiltro.inadimplentes,
                          label: context.alunosL10n.alunosFilterOverdue,
                          count: inadCount,
                          isDark: isDark,
                        ),
                      ],
                      const SizedBox(width: 8),
                      _alunosFilterChip(
                        filtro: AlunoFiltro.risco,
                        label: context.alunosL10n.alunosFilterHighRisk,
                        count: riscoCount,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _alunosFilterChip(
                        filtro: AlunoFiltro.novos,
                        label: context.alunosL10n.alunosFilterInvites,
                        count: novosCount,
                        isDark: isDark,
                      ),
                      const SizedBox(width: AlunosLayout.filterRowEndInset),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _alunosFilterChip({
    required AlunoFiltro filtro,
    required String label,
    required int count,
    required bool isDark,
  }) {
    return KeyedSubtree(
      key: _chipKeys[filtro],
      child: _FxChip(
        label: label,
        count: count,
        isSelected: _filtro == filtro,
        isDark: isDark,
        onTap:
            () => _setFiltro(
              _filtro == filtro ? AlunoFiltro.todos : filtro,
            ),
      ),
    );
  }
}
