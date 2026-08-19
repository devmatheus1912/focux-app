part of 'treino_detail_screen.dart';

class _TreinoExerciseReorderList extends StatefulWidget {
  final List<TreinoExercicioItem> exercises;
  final int treinoId;
  final int? alunoId;
  final bool isDark;
  final Color primary;
  final TreinoRepository repo;
  final WidgetRef ref;
  final Future<void> Function(TreinoExercicioItem item) onEditPrescription;

  const _TreinoExerciseReorderList({
    required this.exercises,
    required this.treinoId,
    required this.alunoId,
    required this.isDark,
    required this.primary,
    required this.repo,
    required this.ref,
    required this.onEditPrescription,
  });

  @override
  State<_TreinoExerciseReorderList> createState() =>
      _TreinoExerciseReorderListState();
}

class _TreinoExerciseReorderListState
    extends State<_TreinoExerciseReorderList> {
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
      FeedbackHelper.showError(
        context,
        friendlyError(error, fallback: 'Erro ao reordenar exercícios.'),
      );
    }
  }

  Future<void> _removeExercise(TreinoExercicioItem te) async {
    final confirm = await _showTreinoSheet<bool>(
      context: context,
      builder:
          (ctx) => _RemoveExerciseSheet(
            title: te.exercicio.nomeDisplay,
            isDark: widget.isDark,
          ),
    );
    if (confirm != true || !mounted) return;
    HapticFeedback.mediumImpact();
    try {
      await widget.repo.removerExercicio(widget.treinoId, te.id);
      widget.ref.invalidate(treinoProvider(widget.treinoId));
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: 'Erro ao remover exercício.'),
        );
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
            final reduce = TokensStrip.prefersReducedMotion(context);
            final t = reduce ? 0.0 : Curves.easeOut.transform(animation.value);
            return Material(
              elevation: 6 * t,
              color: fxTransparent,
              shadowColor: heroScrim(0.18),
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
            widget.isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

        final row = _ExercicioRow(
          te: te,
          index: _localIndexInGroup(_items, index),
          isDark: widget.isDark,
          isLast: isLastInGroup,
          onEditPrescription: () => widget.onEditPrescription(te),
          onDuplicate: () async {
            try {
              await widget.repo.duplicarExercicio(widget.treinoId, te.id);
              widget.ref.invalidate(treinoProvider(widget.treinoId));
            } catch (error) {
              if (mounted) {
                FeedbackHelper.showError(
                  this.context,
                  friendlyError(error, fallback: 'Erro ao duplicar exercício.'),
                );
              }
            }
          },
          onSubstitute: () async {
            await _showTreinoSheet<void>(
              context: context,
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
                            friendlyError(
                              error,
                              fallback: 'Erro ao substituir exercício.',
                            ),
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
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
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
                          style: FocuxHubTypography.eyebrow(
                            context,
                            color: mute,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.3,
                          ).copyWith(fontSize: 11),
                        ),
                        const Spacer(),
                        Text(
                          '$groupCount ex.',
                          style: FocuxHubTypography.metric(
                            color: mute,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  margin: EdgeInsets.only(
                    bottom: isLastInGroup ? TreinosLayout.exerciseGroupGap : 0,
                  ),
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

class _DetailActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final bool showChevron;
  final VoidCallback onTap;

  const _DetailActionTile({
    required this.icon,
    required this.label,
    this.color,
    this.showChevron = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final tint = color ?? primary;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: TreinosLayout.touchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: BrandPalette.soft(tint, dark: isDark),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: tint, size: 18),
                ),
                SizedBox(width: TokensStrip.s3),
                Expanded(
                  child: Text(
                    label,
                    style: FocuxHubTypography.cardTitle(
                      color: color ?? chrome.ink,
                    ),
                  ),
                ),
                if (showChevron)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: chrome.mute,
                    size: 18,
                  ),
              ],
            ),
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
    final isDark = widget.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forDark(isDark);

    return TreinoHomeSheetSurface(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: chrome.mute.withValues(alpha: 0.26),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          SizedBox(height: TokensStrip.s4),
          TreinoSheetChromeHeader(
            icon: Icons.person_add_alt_1_rounded,
            title: 'Atribuir treino',
            subtitle:
                widget.alunos.isEmpty
                    ? 'Cadastre um aluno antes.'
                    : 'Escolha quem recebe este plano.',
            isDark: isDark,
          ),
          const SizedBox(height: TokensStrip.s4),
          if (widget.alunos.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? heroTealSurface(0.04) : TokensStrip.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: chrome.line),
              ),
              child: Text(
                'Cadastre um aluno antes de atribuir este treino.',
                style: FocuxHubTypography.bodyMuted(
                  color: chrome.mute,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.alunos.length,
                separatorBuilder: (_, __) => SizedBox(height: TokensStrip.s2),
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
                                ? BrandPalette.soft(primary, dark: isDark)
                                : isDark
                                ? heroTealSurface(0.03)
                                : heroTealInk(),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color:
                              selected
                                  ? primary.withValues(alpha: 0.30)
                                  : chrome.line,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? primary : chrome.line,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              initials,
                              style: FocuxHubTypography.cardTitle(
                                color: selected ? heroTealInk() : chrome.ink,
                              ),
                            ),
                          ),
                          SizedBox(width: TokensStrip.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  aluno.nome,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FocuxHubTypography.cardTitle(
                                    color: chrome.ink,
                                  ),
                                ),
                                SizedBox(height: TokensStrip.s1),
                                Text(
                                  aluno.objetivo?.trim().isNotEmpty == true
                                      ? aluno.objetivo!.trim()
                                      : 'Objetivo não definido',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FocuxHubTypography.bodyMuted(
                                    color: chrome.mute,
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
                                    : chrome.mute.withValues(alpha: 0.7),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: TokensStrip.s4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: chrome.ink,
                    side: BorderSide(color: chrome.line),
                    minimumSize: const Size(0, TreinosLayout.touchTarget),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              SizedBox(width: TokensStrip.s3),
              Expanded(
                child: FilledButton(
                  onPressed:
                      selectedAlunoId == null
                          ? null
                          : () => Navigator.pop(context, selectedAlunoId),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: heroTealInk(),
                    minimumSize: const Size(0, TreinosLayout.touchTarget),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Atribuir',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TreinoHeroActions extends StatelessWidget {
  final VoidCallback onAdd;

  const _TreinoHeroActions({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Adicionar exercício',
      child: FilledButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Adicionar exercício'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(TreinosLayout.touchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
