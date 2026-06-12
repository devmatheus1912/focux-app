part of 'alunos_list_screen.dart';

class _FxChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FxChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final action = BrandPalette.sectionAction(primary, dark: isDark);
    final bg =
        isSelected
            ? primary
            : (isDark
                ? Colors.white.withValues(alpha: 0.055)
                : Colors.white.withValues(alpha: 0.78));
    final color =
        isSelected
            ? Colors.white
            : (isDark ? EagleTokens.darkInk : TokensStrip.textPrimary);
    final border =
        isSelected
            ? Border.all(color: action.withValues(alpha: isDark ? 0.45 : 0.28))
            : Border.all(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.09)
                      : TokensStrip.borderDefault,
            );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: border,
          boxShadow: [
            if (isSelected && !isDark)
              BoxShadow(
                color: primary.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: -6,
              ),
            if (isSelected && isDark)
              BoxShadow(
                color: action.withValues(alpha: 0.28),
                blurRadius: 12,
                spreadRadius: -2,
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTypography.inter(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
                height: 1.15,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Colors.white
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : TokensStrip.pageBg),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: AppTypography.inter(
                  color:
                      isSelected
                          ? primary
                          : (isDark
                              ? EagleTokens.darkInkMute
                              : TokensStrip.textSecondary),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetShortcutChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SheetShortcutChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color:
              selected
                  ? primary
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : TokensStrip.cardBg),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                selected
                    ? primary
                    : (isDark
                        ? EagleTokens.darkLine
                        : TokensStrip.borderDefault),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.inter(
            color: selected ? Colors.white : ink,
            fontSize: TokensStrip.fontBodySm,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _EmptyAlunosState extends StatelessWidget {
  final bool hasQuery;
  final bool hasActiveFilter;
  final String filtroLabel;
  final bool isDark;
  final VoidCallback? onClear;
  final VoidCallback? onClearFilter;
  final VoidCallback? onAdd;

  const _EmptyAlunosState({
    required this.hasQuery,
    this.hasActiveFilter = false,
    this.filtroLabel = '',
    required this.isDark,
    this.onClear,
    this.onClearFilter,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final primary = Theme.of(context).colorScheme.primary;
    final filteredEmpty = hasActiveFilter && !hasQuery;

    final title =
        hasQuery
            ? 'Nenhum aluno encontrado'
            : filteredEmpty
            ? 'Nenhum aluno neste filtro'
            : 'Nenhum aluno cadastrado';
    final subtitle =
        hasQuery
            ? 'Tente buscar por outro nome, objetivo ou e-mail.'
            : filteredEmpty
            ? 'Não há alunos $filtroLabel no momento. Limpe o filtro ou mude a visualização.'
            : 'Adicione o primeiro aluno para montar treinos e acompanhar a evolução.';
    final icon =
        hasQuery
            ? Icons.search_off_rounded
            : filteredEmpty
            ? Icons.filter_alt_off_rounded
            : Icons.group_add_rounded;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: isDark ? 0.18 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primary, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                color: ink,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: mute, fontSize: 13, height: 1.35),
            ),
            if (onClearFilter != null) ...[
              const SizedBox(height: TokensStrip.s4),
              OutlinedButton(
                onPressed: onClearFilter,
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('Limpar filtro'),
              ),
            ] else if (onClear != null) ...[
              const SizedBox(height: TokensStrip.s4),
              OutlinedButton(
                onPressed: onClear,
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('Limpar busca'),
              ),
            ] else if (onAdd != null) ...[
              const SizedBox(height: 20),
              FxLiquidPrimaryButton(
                label: 'Adicionar aluno',
                icon: Icons.person_add_rounded,
                onPressed: onAdd,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlunoCardFX extends ConsumerStatefulWidget {
  final Aluno aluno;
  final bool modoSelecao;
  final bool isSelected;
  final VoidCallback? onToggle;
  final VoidCallback? onLongPress;

  /// Active filter — used to suppress redundant status badges.
  final AlunoFiltro activeFiltro;
  final bool triageContextActive;
  final int diasSemTreinoLimite;
  final bool compact;

  const _AlunoCardFX({
    required this.aluno,
    this.modoSelecao = false,
    this.isSelected = false,
    this.onToggle,
    this.onLongPress,
    this.activeFiltro = AlunoFiltro.todos,
    this.triageContextActive = false,
    this.diasSemTreinoLimite = AlunoFollowUpStore.diasSemTreinoLimite,
    this.compact = false,
  });

  @override
  ConsumerState<_AlunoCardFX> createState() => _AlunoCardFXState();
}

class _AlunoCardFXState extends ConsumerState<_AlunoCardFX> {
  List<AderenciaWeekPoint>? _aderenciaPoints;

  @override
  void initState() {
    super.initState();
    if (widget.aluno.aderenciaPercent == null) {
      _loadSparkline();
    }
  }

  Future<void> _loadSparkline() async {
    try {
      final repo = AlunoRepository(ref.read(apiClientProvider));
      final bundle = await repo.aderenciaSemanalBundle(widget.aluno.id);
      if (!mounted) return;
      setState(
        () => _aderenciaPoints = parseAderenciaSemanal(bundle.dias),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forDark(isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final secondaryInk = alunoListSecondaryInk(isDark);
    final line = chrome.line;
    final cardPadding = widget.compact ? 10.0 : 14.0;

    final aluno = widget.aluno;
    final displayName = fxTitleCaseName(aluno.nome);
    final objetivo = prettyAlunoObjective(aluno.objetivo);

    // FxStatus pill colors
    Color statusBg, statusColor;
    String statusText;

    if (aluno.statusFinanceiro == 'INADIMPLENTE' || aluno.inadimplente) {
      statusBg = EagleTokens.badSoft;
      statusColor = EagleTokens.bad;
      statusText = 'Inadimplente';
    } else if (aluno.status == 'INATIVO') {
      statusBg = EagleTokens.warnSoft;
      statusColor = EagleTokens.warn;
      statusText = 'Inativo';
    } else if (aluno.emRisco) {
      final riscoColors = alunoRiscoAltoBadgeColors(isDark);
      statusBg = riscoColors.$2;
      statusColor = riscoColors.$1;
      statusText = 'Risco alto';
    } else {
      statusBg = EagleTokens.goodSoft;
      statusColor = EagleTokens.good;
      statusText = 'Ativo';
    }

    final avatarColor = alunoAvatarFallbackColor(displayName, isDark);

    final sparkline = alunosListSparklineMetrics(
      points: _aderenciaPoints ?? const [],
      cachedAderenciaPercent: widget.aluno.aderenciaPercent,
    );
    final sparkValues = sparkline.sparkValues;
    final weeklyCheckins = sparkline.weeklyCheckins;
    final aderenciaPercent = sparkline.aderenciaPercent;
    final aderColor = EagleTokens.aderenciaColor(
      (aderenciaPercent ?? 0).toDouble(),
      isDark: isDark,
    );
    final adherenceLabel = adherenceActivityLabel(
      aluno: aluno,
      weeklyCheckins: weeklyCheckins,
    );
    final hasTreinoRecente =
        (aluno.diasSemTreino ?? 1) == 0 ||
        weeklyCheckins > 0 ||
        (aderenciaPercent ?? 0) > 0;
    final isSelected = widget.isSelected;
    final modoSelecao = widget.modoSelecao;
    final needsOutreach =
        !modoSelecao &&
        alunoPrecisaContatoHoje(
          aluno,
          diasSemTreinoLimite: widget.diasSemTreinoLimite,
        );
    final whatsappNumber = (aluno.whatsapp ?? '').replaceAll(RegExp(r'\D'), '');
    final hasWhatsapp = whatsappNumber.isNotEmpty;

    return InkWell(
      onTap:
          modoSelecao
              ? widget.onToggle
              : () => context.push('/alunos/${aluno.id}'),
      onLongPress: widget.onLongPress,
      borderRadius: BorderRadius.circular(TokensStrip.rCard),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.all(cardPadding),
        decoration: ShellChrome.forDark(isDark).listCard(
          selected: isSelected,
          primary: primary,
          radius: TokensStrip.rCard,
        ),
        child: Row(
          children: [
            // Checkbox em modo seleção
            if (modoSelecao) ...[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  key: ValueKey(isSelected),
                  color:
                      isSelected
                          ? primary
                          : (isDark
                              ? EagleTokens.darkInkMute
                              : TokensStrip.textSecondary),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
            ],
            // FxAvatar
            AlunoAvatar(
              name: displayName,
              photoUrl: aluno.fotoUrl,
              fallbackColor: avatarColor,
            ),
            const SizedBox(width: 12),

            // Middle Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: AppTypography.inter(
                            fontSize: TokensStrip.fontBody,
                            fontWeight: FontWeight.w700,
                            color: ink,
                            letterSpacing: -0.15,
                            height: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Only show badge when it adds information
                      // (suppress when the active filter already implies the status)
                      if (shouldShowAlunoListBadge(
                        statusText,
                        widget.activeFiltro,
                        triageContextActive: widget.triageContextActive,
                      )) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                statusText,
                                style: AppTypography.inter(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.15,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!widget.compact) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$objetivo · ${maskEmailForList(aluno.email)}',
                      style: AppTypography.inter(
                        fontSize: TokensStrip.fontBodySm,
                        color: secondaryInk,
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    const SizedBox(height: 2),
                    Text(
                      objetivo,
                      style: AppTypography.inter(
                        fontSize: TokensStrip.fontBodySm,
                        color: secondaryInk,
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  SizedBox(height: widget.compact ? 6 : 8),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: aderColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        aderenciaPercent == null ? '—' : '$aderenciaPercent%',
                        style: AppTypography.mono(
                          fontSize: 12.5,
                          fontWeight:
                              hasTreinoRecente
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                          color: hasTreinoRecente ? aderColor : secondaryInk,
                          height: 1.1,
                        ),
                      ),
                      if (!widget.compact && adherenceLabel.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '·',
                            style: AppTypography.inter(
                              fontSize: 11,
                              color: secondaryInk.withValues(alpha: 0.85),
                              height: 1.1,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            adherenceLabel,
                            style: AppTypography.inter(
                              fontSize: 11,
                              color: secondaryInk,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Rail (só fora da fila de contato) ou ações rápidas compactas
            if (needsOutreach)
              _AlunoOutreachActions(
                alunoId: aluno.id,
                displayName: displayName,
                whatsappNumber: whatsappNumber,
                hasWhatsapp: hasWhatsapp,
                emRisco: aluno.emRisco,
                primary: primary,
                isDark: isDark,
                mute: mute,
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _AdherenceRail(
                    value: (aderenciaPercent ?? 0).toDouble(),
                    color: aderColor,
                    line: line,
                    isEmpty: !hasTreinoRecente,
                  ),
                  const SizedBox(height: 6),
                  Semantics(
                    label: 'Abrir ficha de $displayName',
                    button: true,
                    child: Tooltip(
                      message: 'Ver detalhes',
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: secondaryInk.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AdherenceRail extends StatelessWidget {
  final double value;
  final Color color;
  final Color line;
  final bool isEmpty;

  const _AdherenceRail({
    required this.value,
    required this.color,
    required this.line,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / 100).clamp(0.0, 1.0);

    return SizedBox(
      width: 58,
      height: 22,
      child: Align(
        alignment: Alignment.centerRight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              Container(
                width: 54,
                height: 3,
                color: isEmpty ? line.withValues(alpha: 0.55) : line,
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 54 * progress,
                height: 3,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
