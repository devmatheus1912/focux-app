part of 'alunos_list_screen.dart';

extension AlunosListScreenHeader on _AlunosListScreenState {
  Widget _buildAlunosListHeader({
    required List<Aluno> alunos,
    required int contatoCount,
    required int ativosCount,
    required int inadCount,
    required int riscoCount,
    required int novosCount,
    required String headerOps,
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
                                          radius:
                                              AlunosLayout.headerChromeSize / 2,
                                        ),
                                        child: Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          size: 16,
                                          color: ink,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: AlunosLayout.headerChromeGap,
                                  ),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
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
                                          letterSpacing:
                                              _modoSelecao ? 0.08 : 0.04,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
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
                                        Text(
                                          freshnessLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: FocuxHubTypography.bodyMuted(
                                            color: mute,
                                            fontWeight: FontWeight.w600,
                                          ).copyWith(fontSize: 11),
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
                                        radius:
                                            AlunosLayout.headerChromeSize / 2,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 20,
                                        color: ink,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  const ShellThemeToggle(
                                    size: AlunosLayout.headerChromeSize,
                                  ),
                                  const SizedBox(
                                    width: AlunosLayout.headerChromeGap,
                                  ),
                                  Semantics(
                                    button: true,
                                    label: 'Selecionar alunos',
                                    child: InkWell(
                                      onTap: _toggleModoSelecao,
                                      borderRadius: BorderRadius.circular(
                                        AlunosLayout.headerChromeSize / 2,
                                      ),
                                      child: Container(
                                        width: AlunosLayout.headerChromeSize,
                                        height: AlunosLayout.headerChromeSize,
                                        decoration: chrome.headerAction(
                                          radius:
                                              AlunosLayout.headerChromeSize / 2,
                                        ),
                                        child: Icon(
                                          Icons.checklist_rounded,
                                          size: 20,
                                          color: ink,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: AlunosLayout.headerChromeGap,
                                  ),
                                  Semantics(
                                    button: true,
                                    label: 'Adicionar aluno',
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

                          // Search Bar
                          Padding(
                            padding: AlunosLayout.searchBarOuterPadding,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              padding: AlunosLayout.searchBarPadding,
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
                                      _searchFocusNode.hasFocus
                                          ? primary.withValues(alpha: 0.32)
                                          : (isDark
                                              ? EagleTokens.darkLine
                                              : TokensStrip.borderDefault),
                                  width: _searchFocusNode.hasFocus ? 1.2 : 1,
                                ),
                                boxShadow: [
                                  if (_searchFocusNode.hasFocus && !isDark)
                                    BoxShadow(
                                      color: primary.withValues(alpha: 0.08),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                      spreadRadius: -12,
                                    ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color:
                                          _searchFocusNode.hasFocus
                                              ? primary.withValues(alpha: 0.08)
                                              : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.search_rounded,
                                      size: 18,
                                      color:
                                          _searchFocusNode.hasFocus
                                              ? primary
                                              : mute,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Semantics(
                                      label: context.alunosL10n.alunosSearchA11y,
                                      textField: true,
                                      child: TextField(
                                        controller: _searchController,
                                        focusNode: _searchFocusNode,
                                        onChanged: (value) {
                                          setState(() => _query = value);
                                        },
                                        textInputAction: TextInputAction.search,
                                        cursorColor: primary,
                                        style: AppTypography.inter(
                                          fontSize: TokensStrip.fontBody,
                                          color: ink,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
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
                                        setState(() => _query = '');
                                      },
                                      borderRadius: BorderRadius.circular(999),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(
                                          Icons.close,
                                          size: 18,
                                          color: mute,
                                        ),
                                      ),
                                    )
                                  else
                                    Tooltip(
                                      message: 'Organizar lista',
                                      child: InkWell(
                                        onTap: _showListOptions,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
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
                                                      AlunoOrdenacao
                                                          .prioridade ||
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
                                                                ? EagleTokens
                                                                    .darkCard
                                                                : TokensStrip
                                                                    .cardBg,
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
                          ),

                          // Filter Chips
                          Padding(
                            padding: AlunosLayout.filterRowPadding,
                            child: FxHorizontalScrollPeek(
                              showPeek: true,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _FxChip(
                                      label: context.alunosL10n.alunosFilterAll,
                                      count: alunos.length,
                                      isSelected: _filtro == AlunoFiltro.todos,
                                      isDark: isDark,
                                      onTap:
                                          () => setState(
                                            () => _filtro = AlunoFiltro.todos,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    _FxChip(
                                      label: context.alunosL10n.alunosFilterContactToday,
                                      count: contatoCount,
                                      isSelected:
                                          _filtro == AlunoFiltro.contatoHoje,
                                      isDark: isDark,
                                      onTap:
                                          () => setState(
                                            () =>
                                                _filtro =
                                                    AlunoFiltro.contatoHoje,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    _FxChip(
                                      label: context.alunosL10n.alunosFilterActive,
                                      count: ativosCount,
                                      isSelected: _filtro == AlunoFiltro.ativos,
                                      isDark: isDark,
                                      onTap:
                                          () => setState(
                                            () => _filtro = AlunoFiltro.ativos,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    _FxChip(
                                      label: context.alunosL10n.alunosFilterOverdue,
                                      count: inadCount,
                                      isSelected:
                                          _filtro == AlunoFiltro.inadimplentes,
                                      isDark: isDark,
                                      onTap:
                                          () => setState(
                                            () =>
                                                _filtro =
                                                    AlunoFiltro.inadimplentes,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    _FxChip(
                                      label: context.alunosL10n.alunosFilterHighRisk,
                                      count: riscoCount,
                                      isSelected: _filtro == AlunoFiltro.risco,
                                      isDark: isDark,
                                      onTap:
                                          () => setState(
                                            () => _filtro = AlunoFiltro.risco,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    _FxChip(
                                      label: context.alunosL10n.alunosFilterInvites,
                                      count: novosCount,
                                      isSelected: _filtro == AlunoFiltro.novos,
                                      isDark: isDark,
                                      onTap:
                                          () => setState(
                                            () => _filtro = AlunoFiltro.novos,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
  }
}
