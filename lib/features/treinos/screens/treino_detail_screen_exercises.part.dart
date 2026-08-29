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
    final soft = BrandPalette.softened(primary);
    final mute = fxScreenMute(context);

    return TreinoHomeSheetSurface(
      isDark: isDark,
      maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          FxHomeSheetHeader(
            isDark: isDark,
            title: 'Atribuir treino',
            subtitle:
                widget.alunos.isEmpty
                    ? 'Cadastre um aluno antes.'
                    : 'Escolha quem recebe este plano.',
            leading: Icon(
              Icons.person_add_alt_1_rounded,
              color: soft,
              size: FxSettingsLayout.iconSize,
            ),
          ),
          const SizedBox(height: FxSettingsLayout.headerToGroup),
          if (widget.alunos.isEmpty)
            FxSettingsGroup(
              accent: primary,
              caption: 'Cadastre um aluno antes de atribuir este treino.',
              children: [
                FxSettingsTile(
                  icon: Icons.person_outline_rounded,
                  accent: soft,
                  label: 'Nenhum aluno cadastrado',
                  value: '',
                  showDivider: false,
                  locked: true,
                  onTap: () {},
                ),
              ],
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: FxSettingsGroup(
                  accent: primary,
                  edgeToEdgeRows: true,
                  children: FxInsetPickerOption.list(
                    accent: soft,
                    items: [
                      for (var i = 0; i < widget.alunos.length; i++)
                        FxInsetPickerOptionSpec(
                          label: widget.alunos[i].nome,
                          subtitle:
                              widget.alunos[i].objetivo?.trim().isNotEmpty ==
                                      true
                                  ? widget.alunos[i].objetivo!.trim()
                                  : 'Objetivo não definido',
                          icon: Icons.person_outline_rounded,
                          selected: selectedAlunoId == widget.alunos[i].id,
                          onTap: () {
                            setState(
                              () => selectedAlunoId = widget.alunos[i].id,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: FxSettingsLayout.groupGap),
          FxSettingsGroup(
            accent: primary,
            children: [
              FxSettingsTile(
                icon: Icons.check_rounded,
                accent: soft,
                label: 'Atribuir',
                value: '',
                highlight: true,
                locked: selectedAlunoId == null,
                showDivider: false,
                onTap: () {
                  if (selectedAlunoId == null) return;
                  Navigator.pop(context, selectedAlunoId);
                },
              ),
            ],
          ),
          const SizedBox(height: FxSettingsLayout.footerAfterGroup),
          Center(
            child: Semantics(
              button: true,
              label: 'Cancelar',
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: mute,
                  minimumSize: const Size(
                    TreinosLayout.touchTarget,
                    TreinosLayout.touchTarget,
                  ),
                  textStyle: FxSettingsLayout.footer(color: mute),
                ),
                child: const Text('Cancelar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
