part of 'alunos_list_screen.dart';

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
