part of 'treino_detail_screen.dart';

class _TreinoExerciseReorderList extends StatefulWidget {
  final List<TreinoExercicioItem> exercises;
  final int treinoId;
  final int? alunoId;
  final bool isDark;
  final Color primary;
  final Color primarySoft;
  final TreinoRepository repo;
  final WidgetRef ref;
  final Future<void> Function(TreinoExercicioItem item) onEditPrescription;

  const _TreinoExerciseReorderList({
    required this.exercises,
    required this.treinoId,
    required this.alunoId,
    required this.isDark,
    required this.primary,
    required this.primarySoft,
    required this.repo,
    required this.ref,
    required this.onEditPrescription,
  });

  @override
  State<_TreinoExerciseReorderList> createState() =>
      _TreinoExerciseReorderListState();
}

class _TreinoExerciseReorderListState extends State<_TreinoExerciseReorderList> {
  late List<TreinoExercicioItem> _items;

  @override
  void initState() {
    super.initState();
    _items = [...widget.exercises];
  }

  @override
  void didUpdateWidget(covariant _TreinoExerciseReorderList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameOrder(oldWidget.exercises, widget.exercises)) {
      _items = [...widget.exercises];
    }
  }

  bool _sameOrder(List<TreinoExercicioItem> a, List<TreinoExercicioItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  Future<void> _onReorderItem(int oldIndex, int newIndex) async {
    final snapshot = [..._items];
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
    HapticFeedback.mediumImpact();
    final ids = _items.map((item) => item.id).toList();
    try {
      await widget.repo.reordenarExercicios(widget.treinoId, ids);
      widget.ref.invalidate(treinoProvider(widget.treinoId));
    } catch (error) {
      if (!mounted) return;
      setState(() => _items = snapshot);
      FeedbackHelper.showError(context, 'Erro ao reordenar: $error');
    }
  }

  Future<void> _removeExercise(TreinoExercicioItem te) async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder:
          (ctx) => _RemoveExerciseSheet(
            title: te.exercicio.nomeDisplay,
            isDark: widget.isDark,
          ),
    );
    if (confirm != true || !mounted) return;
    try {
      await widget.repo.removerExercicio(widget.treinoId, te.id);
      widget.ref.invalidate(treinoProvider(widget.treinoId));
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, 'Erro ao remover: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverReorderableList(
      itemCount: _items.length,
      onReorderItem: _onReorderItem,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final t = Curves.easeOut.transform(animation.value);
            return Material(
              elevation: 6 * t,
              color: Colors.transparent,
              shadowColor: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
              child: child,
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final te = _items[index];
        final showHeader = _showsExerciseGroupHeader(_items, index);
        final groupLabel = _workoutGroupLabel(te);
        final groupCount = _groupExerciseCount(_items, index);
        final isFirstInGroup = showHeader;
        final isLastInGroup = _isLastInExerciseGroup(_items, index);
        final mute =
            widget.isDark
                ? EagleTokens.darkInkMute
                : TokensStrip.textSecondary;

        final row = _ExercicioRow(
          te: te,
          index: _localIndexInGroup(_items, index),
          isDark: widget.isDark,
          primary: widget.primary,
          primarySoft: widget.primarySoft,
          isLast: isLastInGroup,
          onEditPrescription: () => widget.onEditPrescription(te),
          onDuplicate: () async {
            try {
              await widget.repo.duplicarExercicio(widget.treinoId, te.id);
              widget.ref.invalidate(treinoProvider(widget.treinoId));
            } catch (error) {
              if (mounted) {
                FeedbackHelper.showError(this.context, 'Erro ao duplicar: $error');
              }
            }
          },
          onSubstitute: () async {
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder:
                  (_) => SubstituirExercicioBottomSheet(
                    alvo: te.exercicio,
                    onEscolher: (novo) async {
                      try {
                        await widget.repo.substituirExercicio(
                          widget.treinoId,
                          te,
                          novo.id,
                        );
                        AnalyticsService.instance.track(
                          'substituir_uso',
                          props: {
                            'treinoId': widget.treinoId,
                            'alvoId': te.exercicio.id,
                            'novoId': novo.id,
                          },
                        );
                        widget.ref.invalidate(treinoProvider(widget.treinoId));
                      } catch (error) {
                        if (mounted) {
                          FeedbackHelper.showError(
                            this.context,
                            'Erro ao substituir: $error',
                          );
                        }
                      }
                    },
                    onCriarNovo: () => context.push('/exercicios/novo'),
                  ),
            );
          },
          onRemove: () => _removeExercise(te),
        );

        return ReorderableDelayedDragStartListener(
          key: ValueKey(te.id),
          index: index,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showHeader)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.primary.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          groupLabel,
                          style: AppTypography.inter(
                            color: mute,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$groupCount ex.',
                          style: AppTypography.mono(
                            color: mute,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  margin: EdgeInsets.only(bottom: isLastInGroup ? 14 : 0),
                  decoration: fxListCardDecoration(
                    context,
                    accent: widget.primary,
                  ).copyWith(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(
                        isFirstInGroup ? TokensStrip.rCard : 0,
                      ),
                      bottom: Radius.circular(
                        isLastInGroup ? TokensStrip.rCard : 0,
                      ),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: row,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MenuActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _MenuActionTile({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink =
        color ?? (isDark ? EagleTokens.darkInk : TokensStrip.textPrimary);
    final border =
        isDark
            ? Colors.white.withValues(alpha: 0.06)
            : TokensStrip.borderDefault.withValues(alpha: 0.95);
    final iconFill =
        color == null
            ? (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : EagleTokens.brandSofter)
            : EagleTokens.bad.withValues(alpha: isDark ? 0.16 : 0.10);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.035)
                    : const Color(0xFFFEFEFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
            boxShadow:
                isDark
                    ? null
                    : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.018),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconFill,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: ink, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.inter(
                    color: ink,
                    fontSize: 13.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: ink, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignWorkoutSheet extends StatefulWidget {
  final List<Aluno> alunos;
  final bool isDark;

  const _AssignWorkoutSheet({required this.alunos, required this.isDark});

  @override
  State<_AssignWorkoutSheet> createState() => _AssignWorkoutSheetState();
}

class _AssignWorkoutSheetState extends State<_AssignWorkoutSheet> {
  int? selectedAlunoId;

  @override
  void initState() {
    super.initState();
    selectedAlunoId = widget.alunos.isEmpty ? null : widget.alunos.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = widget.isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute =
        widget.isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final border =
        widget.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : TokensStrip.borderDefault.withValues(alpha: 0.95);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, math.max(10, bottom + 8)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: fxListCardDecoration(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color:
                      widget.isDark
                          ? Colors.white.withValues(alpha: 0.16)
                          : TokensStrip.borderDefault,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: EagleTokens.brandSofter,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Atribuir treino',
                          style: AppTypography.inter(
                            color: ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.alunos.isEmpty
                              ? 'Nenhum aluno cadastrado.'
                              : 'Escolha quem recebe este plano.',
                          style: AppTypography.inter(
                            color: mute,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TokensStrip.s4),
              if (widget.alunos.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        widget.isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : TokensStrip.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    'Cadastre um aluno antes de atribuir este treino.',
                    style: AppTypography.inter(
                      color: mute,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: widget.alunos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final aluno = widget.alunos[index];
                        final selected = selectedAlunoId == aluno.id;
                        final initials =
                            aluno.nome.trim().isEmpty
                                ? '?'
                                : aluno.nome
                                    .trim()
                                    .split(RegExp(r'\s+'))
                                    .take(2)
                                    .map((part) => part[0].toUpperCase())
                                    .join();

                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => selectedAlunoId = aluno.id);
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  selected
                                      ? EagleTokens.brandSofter
                                      : widget.isDark
                                      ? Colors.white.withValues(alpha: 0.03)
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color:
                                    selected
                                        ? primary.withValues(alpha: 0.28)
                                        : border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color:
                                        selected
                                            ? primary
                                            : EagleTokens.brandSofter,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initials,
                                    style: AppTypography.inter(
                                      color: selected ? Colors.white : primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        aluno.nome,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.inter(
                                          color: ink,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        aluno.objetivo?.trim().isNotEmpty ==
                                                true
                                            ? aluno.objetivo!.trim()
                                            : 'Objetivo não definido',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.inter(
                                          color: mute,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  selected
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color:
                                      selected
                                          ? primary
                                          : mute.withValues(alpha: 0.7),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: TokensStrip.s4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        side: BorderSide(color: border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        foregroundColor: ink,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          selectedAlunoId == null
                              ? null
                              : () => Navigator.pop(context, selectedAlunoId),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        backgroundColor: primary,
                        disabledBackgroundColor: primary.withValues(
                          alpha: 0.28,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: const Text('Atribuir'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TreinoHeroActions extends StatelessWidget {
  final Color primary;
  final VoidCallback onAdd;
  final VoidCallback onMenu;

  const _TreinoHeroActions({
    required this.primary,
    required this.onAdd,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? EagleTokens.darkCard : TokensStrip.cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: primary.withValues(alpha: isDark ? 0.22 : 0.14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: isDark ? 0.10 : 0.12),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: primary,
                      size: 19,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Adicionar exercício',
                      style: AppTypography.inter(
                        color: primary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onMenu,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : TokensStrip.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: primary.withValues(alpha: isDark ? 0.18 : 0.12),
                ),
              ),
              child: Icon(
                Icons.more_horiz_rounded,
                color: isDark ? Colors.white : primary,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroMetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.mono(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

