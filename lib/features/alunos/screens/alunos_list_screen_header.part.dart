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
                              TokensStrip.s5,
                              14,
                              20,
                              14,
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
                                      borderRadius: BorderRadius.circular(22),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: chrome.headerAction(
                                          radius: 20,
                                        ),
                                        child: Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          size: 18,
                                          color: ink,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        headerOps,
                                        style: AppTypography.inter(
                                          fontSize: TokensStrip.fontBodySm,
                                          color:
                                              _modoSelecao
                                                  ? BrandPalette.sectionAction(
                                                    primary,
                                                    dark: isDark,
                                                  )
                                                  : mute,
                                          fontWeight:
                                              _modoSelecao
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                          letterSpacing: _modoSelecao ? 1.2 : 0,
                                          height: 1.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Alunos',
                                        style: AppTypography.inter(
                                          fontSize: TokensStrip.fontH1,
                                          color: ink,
                                          fontWeight: TokensStrip.weightH1,
                                          letterSpacing: TokensStrip.trackingH1,
                                          height: 1.15,
                                        ),
                                      ),
                                      if (freshnessLabel != null) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          freshnessLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.inter(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: mute,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (_modoSelecao) ...[
                                  InkWell(
                                    onTap: _toggleModoSelecao,
                                    borderRadius: BorderRadius.circular(44),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: chrome.headerAction(
                                        radius: 22,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 22,
                                        color: ink,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  const ShellThemeToggle(size: 40),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: _toggleModoSelecao,
                                    borderRadius: BorderRadius.circular(44),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: chrome.headerAction(
                                        radius: 22,
                                      ),
                                      child: Icon(
                                        Icons.checklist_rounded,
                                        size: 22,
                                        color: ink,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  FxGlowSurface(
                                    color: primary,
                                    enabled: true,
                                    intensity: 0.9,
                                    borderRadius: 44,
                                    child: FxSpringButton(
                                      onTap: _adicionarAluno,
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          size: 24,
                                          color: Colors.white,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.fromLTRB(13, 3, 8, 3),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? EagleTokens.darkCard
                                        : Colors.white.withValues(alpha: 0.86),
                                borderRadius: BorderRadius.circular(17),
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
                                        hintText: 'Buscar por nome ou objetivo',
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
                            padding: const EdgeInsets.fromLTRB(
                              TokensStrip.s4,
                              4,
                              16,
                              10,
                            ),
                            child: FxHorizontalScrollPeek(
                              showPeek: true,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _FxChip(
                                      label: 'Todos',
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
                                      label: 'Contato hoje',
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
                                      label: 'Ativos',
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
                                      label: 'Inadimplentes',
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
                                      label: 'Risco alto',
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
                                      label: 'Convites',
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
