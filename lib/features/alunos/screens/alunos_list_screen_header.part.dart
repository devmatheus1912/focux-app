part of 'alunos_list_screen.dart';

extension AlunosListScreenHeader on _AlunosListScreenState {
  Widget _buildAlunosListHeader({
    required int totalCount,
    required int contatoCount,
    required int ativosCount,
    required int inadCount,
    required int riscoCount,
    required int novosCount,
    required String? headerOps,
    required bool showHeaderBack,
    required bool headerBackFromDashboard,
    required String? freshnessLabel,
    required ShellPalette chrome,
    required bool isDark,
    required Color primary,
    required Color ink,
    required Color mute,
  }) {
    return FxPremiumEntrance(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (Alunos + Botão Adicionar)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensStrip.s4,
              TokensStrip.s3,
              TokensStrip.s4,
              TokensStrip.s2,
            ),
            child: DecoratedBox(
              decoration: fxStripCardDecoration(
                context,
                accent: primary,
                radius: TokensStrip.rCard,
                glowStrength: _modoSelecao ? 0.02 : 0.04,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (showHeaderBack) ...[
                      Semantics(
                        button: true,
                        label:
                            headerBackFromDashboard
                                ? 'Voltar para Hoje'
                                : 'Limpar filtro',
                        child: InkWell(
                          onTap: _handleHeaderBack,
                          borderRadius: BorderRadius.circular(
                            AlunosLayout.headerChromeSize / 2,
                          ),
                          child: Container(
                            width: AlunosLayout.headerChromeSize,
                            height: AlunosLayout.headerChromeSize,
                            decoration: chrome.headerAction(
                              radius: AlunosLayout.headerChromeSize / 2,
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: ink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AlunosLayout.headerChromeGap),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (headerOps != null && headerOps.isNotEmpty) ...[
                            Text(
                              headerOps,
                              style: FocuxHubTypography.eyebrow(
                                context,
                                color:
                                    _modoSelecao
                                        ? BrandPalette.sectionAction(
                                          primary,
                                          dark: isDark,
                                        )
                                        : mute,
                                fontWeight:
                                    _modoSelecao
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                letterSpacing: _modoSelecao ? 0.08 : 0.04,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            context.alunosL10n.alunosTitle,
                            style: FocuxHubTypography.pageTitle(
                              context,
                              color: ink,
                            ).copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.12,
                            ),
                          ),
                          if (freshnessLabel != null) ...[
                            const SizedBox(height: 3),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                freshnessLabel,
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
                    if (_modoSelecao) ...[
                      InkWell(
                        onTap: _toggleModoSelecao,
                        borderRadius: BorderRadius.circular(
                          AlunosLayout.headerChromeSize / 2,
                        ),
                        child: Container(
                          width: AlunosLayout.headerChromeSize,
                          height: AlunosLayout.headerChromeSize,
                          decoration: chrome.headerAction(
                            radius: AlunosLayout.headerChromeSize / 2,
                          ),
                          child: Icon(Icons.close, size: 20, color: ink),
                        ),
                      ),
                    ] else ...[
                      FxHelpIconButton(
                        tooltip: AlunosMicrocopy.helpA11y,
                        onTap: _openHelp,
                      ),
                      const SizedBox(width: AlunosLayout.headerChromeGap),
                      Semantics(
                        button: true,
                        label: AlunosMicrocopy.selectA11y,
                        child: InkWell(
                          onTap: _toggleModoSelecao,
                          borderRadius: BorderRadius.circular(
                            AlunosLayout.headerChromeSize / 2,
                          ),
                          child: Container(
                            width: AlunosLayout.headerChromeSize,
                            height: AlunosLayout.headerChromeSize,
                            decoration: chrome.headerAction(
                              radius: AlunosLayout.headerChromeSize / 2,
                            ),
                            child: Icon(
                              Icons.checklist_rounded,
                              size: 20,
                              color: ink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AlunosLayout.headerChromeGap),
                      Semantics(
                        button: true,
                        label: AlunosMicrocopy.addA11y,
                        child: Material(
                          color: primary,
                          elevation: isDark ? 3 : 1,
                          shadowColor: primary.withValues(
                            alpha: isDark ? 0.35 : 0.18,
                          ),
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: _adicionarAluno,
                            customBorder: const CircleBorder(),
                            child: SizedBox(
                              width: AlunosLayout.headerChromeSize,
                              height: AlunosLayout.headerChromeSize,
                              child: const Icon(
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
          ),

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
                            return Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color:
                                    focused
                                        ? primary.withValues(alpha: 0.08)
                                        : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: focused ? primary : mute,
                              ),
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
                              style: AppTypography.inter(
                                fontSize: TokensStrip.fontBody,
                                color: ink,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                hintText: context.alunosL10n.alunosSearchHint,
                                hintStyle: AppTypography.inter(
                                  fontSize: TokensStrip.fontBody,
                                  color: mute,
                                  fontWeight: FontWeight.w500,
                                ),
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
                              child: Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: primary.withValues(
                                    alpha: isDark ? 0.14 : 0.07,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 18,
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
                        filtro: AlunoFiltro.todos,
                        label: context.alunosL10n.alunosFilterAll,
                        count: totalCount,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
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
                      const SizedBox(width: 8),
                      _alunosFilterChip(
                        filtro: AlunoFiltro.inadimplentes,
                        label: context.alunosL10n.alunosFilterOverdue,
                        count: inadCount,
                        isDark: isDark,
                      ),
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
        onTap: () => _setFiltro(filtro),
      ),
    );
  }
}
