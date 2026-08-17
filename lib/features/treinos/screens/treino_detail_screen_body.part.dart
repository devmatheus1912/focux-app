part of 'treino_detail_screen.dart';

class _TreinoDetailBackButton extends StatelessWidget {
  final int? alunoId;

  const _TreinoDetailBackButton({required this.alunoId});

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);

    return IconButton(
      onPressed: () => _popTreinoDetail(context, alunoId: alunoId),
      icon: Container(
        width: 38,
        height: 38,
        decoration: chrome.headerAction(radius: 12),
        child: Center(
          child: FxIcon(name: 'arrow-left', size: 18, color: chrome.ink),
        ),
      ),
    );
  }
}

class _TreinoDetailBody extends StatelessWidget {
  final Treino treino;
  final int treinoId;
  final int? alunoId;
  final String? alunoNome;
  final bool isDark;
  final WidgetRef ref;
  const _TreinoDetailBody({
    required this.treino,
    required this.treinoId,
    required this.alunoId,
    required this.alunoNome,
    required this.isDark,
    required this.ref,
  });

  Future<void> _openMenu(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: fxTransparent,
      barrierColor: heroScrim(0.34),
      isScrollControlled: true,
      builder: (sheetContext) {
        final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
        final mute =
            isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.82;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              decoration: fxListCardDecoration(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: mute.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? heroTealSurface(0.06)
                                  : EagleTokens.brandSofter,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Opções do treino',
                              style: AppTypography.inter(
                                color: ink,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Atribua, duplique ou salve como modelo.',
                              style: AppTypography.inter(
                                color: mute,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MenuActionTile(
                            icon: Icons.add_circle_outline,
                            label: 'Adicionar exercício',
                            onTap: () => Navigator.pop(sheetContext, 'add'),
                          ),
                          _MenuActionTile(
                            icon: Icons.person_add_alt_1_outlined,
                            label: 'Atribuir a aluno',
                            onTap: () => Navigator.pop(sheetContext, 'assign'),
                          ),
                          _MenuActionTile(
                            icon: Icons.content_copy_rounded,
                            label: 'Copiar para aluno',
                            onTap: () => Navigator.pop(sheetContext, 'clone'),
                          ),
                          _MenuActionTile(
                            icon: Icons.copy_outlined,
                            label: 'Duplicar treino',
                            onTap:
                                () => Navigator.pop(sheetContext, 'duplicate'),
                          ),
                          _MenuActionTile(
                            icon: Icons.bookmark_border,
                            label: 'Salvar como template',
                            onTap:
                                () => Navigator.pop(sheetContext, 'template'),
                          ),
                          _MenuActionTile(
                            icon: Icons.delete_outline,
                            label: 'Excluir treino',
                            color: EagleTokens.bad,
                            onTap: () => Navigator.pop(sheetContext, 'delete'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!context.mounted || action == null) {
      return;
    }

    final repo = ref.read(treinoRepositoryProvider);

    switch (action) {
      case 'add':
        final added = await context.push<bool>(
          '/treinos/$treinoId/exercicios/add',
          extra: alunoId == null ? null : {'alunoId': alunoId},
        );
        if (added == true) {
          ref.invalidate(treinoProvider(treinoId));
        }
        break;
      case 'assign':
        try {
          final alunos = await ref.read(alunosProvider.future);
          if (!context.mounted) return;
          final selected = await showModalBottomSheet<int>(
            context: context,
            backgroundColor: fxTransparent,
            barrierColor: heroScrim(0.34),
            isScrollControlled: true,
            builder:
                (dialogContext) =>
                    _AssignWorkoutSheet(alunos: alunos, isDark: isDark),
          );
          if (selected == null) return;
          await repo.atribuirAluno(treinoId, selected);
          ref.invalidate(treinoProvider(treinoId));
          invalidateTreinosCaches(ref);
          ref.invalidate(treinosDoAlunoProvider(selected));
          if (context.mounted) {
            FeedbackHelper.showSuccess(context, 'Treino atribuído ao aluno.');
          }
        } catch (e) {
          if (context.mounted) {
            FeedbackHelper.showError(context, friendlyError(e));
          }
        }
        break;
      case 'clone':
        try {
          final alunos = await ref.read(alunosProvider.future);
          if (!context.mounted) return;
          final selected = await showModalBottomSheet<int>(
            context: context,
            backgroundColor: fxTransparent,
            barrierColor: heroScrim(0.34),
            isScrollControlled: true,
            builder:
                (dialogContext) =>
                    _AssignWorkoutSheet(alunos: alunos, isDark: isDark),
          );
          if (selected == null) return;
          await repo.clonarParaAluno(treinoId, selected);
          invalidateTreinosCaches(ref);
          ref.invalidate(treinosDoAlunoProvider(selected));
          if (context.mounted) {
            FeedbackHelper.showSuccess(
              context,
              'Cópia dedicada criada para o aluno.',
            );
          }
        } catch (e) {
          if (context.mounted) {
            FeedbackHelper.showError(context, friendlyError(e));
          }
        }
        break;
      case 'duplicate':
        try {
          await repo.duplicar(treinoId);
          invalidateTreinosCaches(ref);
          if (context.mounted) {
            FeedbackHelper.showSuccess(
              context,
              'Treino duplicado com sucesso.',
            );
          }
        } catch (e) {
          if (context.mounted) {
            FeedbackHelper.showError(context, friendlyError(e));
          }
        }
        break;
      case 'template':
        try {
          await repo.salvarComoTemplate(treinoId);
          if (context.mounted) {
            FeedbackHelper.showSuccess(context, 'Treino salvo como template.');
          }
        } catch (e) {
          if (context.mounted) {
            FeedbackHelper.showError(context, friendlyError(e));
          }
        }
        break;
      case 'delete':
        final confirm = await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: fxTransparent,
          barrierColor: heroScrim(0.34),
          builder:
              (dialogContext) =>
                  _DeleteTrainingSheet(title: treino.nome, isDark: isDark),
        );
        if (confirm != true) break;
        HapticFeedback.mediumImpact();
        try {
          await repo.excluirTreino(treinoId);
          invalidateTreinosCaches(ref);
          if (context.mounted) {
            FeedbackHelper.showSuccess(context, 'Treino excluído.');
            context.pop(true);
          }
        } catch (e) {
          if (context.mounted) {
            FeedbackHelper.showError(context, friendlyError(e));
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(treinoRepositoryProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final heroPrimary = BrandPalette.softened(primary, amount: 0.06);
    final heroDeep = BrandPalette.deep(heroPrimary);
    final contextLabel = _workoutContextLabel(treino, alunoNome);
    final displayName = _displayWorkoutName(treino.nome);
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final orderedExercises = [...treino.exercicios]
      ..sort((a, b) => a.ordem.compareTo(b.ordem));

    // Group by muscle taxonomy (consistent labels)
    final grouped = <String, List<TreinoExercicioItem>>{};
    for (final te in orderedExercises) {
      final group = _workoutGroupLabel(te);
      grouped.putIfAbsent(group, () => []).add(te);
    }
    final durationMin = math.max(4, (treino.exercicios.length * 3.5).round());
    double volumeKg = 0;
    for (final te in treino.exercicios) {
      final reps =
          int.tryParse(te.repeticoes.split('x').last.trim()) ??
          int.tryParse(te.repeticoes) ??
          0;
      volumeKg += te.series * reps * (te.cargaKg ?? 0);
    }
    final hasLoadVolume = volumeKg > 0;
    final volumeLabel =
        hasLoadVolume
            ? '${(volumeKg / 1000).toStringAsFixed(1)}t'
            : '${grouped.keys.length}';
    final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight + 6;
    final expandedHeight = topInset + 132;

    Future<void> openEditPrescription(TreinoExercicioItem item) async {
      HapticFeedback.selectionClick();
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: fxTransparent,
        barrierColor: heroScrim(0.34),
        builder:
            (_) => _EditPrescriptionSheet(
              treinoId: treinoId,
              item: item,
              isDark: isDark,
              repo: repo,
            ),
      );
      if (saved != true) return;
      ref.invalidate(treinoProvider(treinoId));
      if (context.mounted) {
        FeedbackHelper.showSuccess(context, 'Prescrição atualizada.');
      }
    }

    return CustomScrollView(
      slivers: [
        // Hero AppBar
        SliverAppBar(
          expandedHeight: expandedHeight,
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: isDark ? EagleTokens.darkBg : heroDeep,
          surfaceTintColor: fxTransparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leadingWidth: 48,
          iconTheme: IconThemeData(color: heroTealInk()),
          leading: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: _TreinoDetailBackButton(alunoId: alunoId),
          ),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      transform: const GradientRotation(160 * math.pi / 180),
                      colors: [heroPrimary, heroDeep],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
                CustomPaint(painter: const _GridTexturePainter()),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    TokensStrip.s5,
                    topInset,
                    20,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: heroTealSurface(0.1),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: heroTealSurface(0.12),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: heroScrim(0.14),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(17),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    heroTealSurface(0.18),
                                    heroTealSurface(0.05),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.fitness_center_rounded,
                                size: 29,
                                color: heroTealSurface(0.92),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contextLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.inter(
                                      color: heroTealInk().withValues(
                                        alpha: 0.68,
                                      ),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    displayName,
                                    style: AppTypography.inter(
                                      color: heroTealInk(),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0,
                                      height: 1.02,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${treino.exercicios.length} exercício${treino.exercicios.length == 1 ? '' : 's'}',
                                    style: AppTypography.mono(
                                      color: heroTealInk().withValues(
                                        alpha: 0.72,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _HeroMetricChip(
                            label: 'Duração est.',
                            value: '~${durationMin}min',
                          ),
                          const SizedBox(width: 8),
                          _HeroMetricChip(
                            label: 'Exercícios',
                            value: '${treino.exercicios.length}',
                          ),
                          const SizedBox(width: 8),
                          _HeroMetricChip(
                            label: hasLoadVolume ? 'Volume' : 'Grupos',
                            value: volumeLabel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 14, 20, 6),
            child: _TreinoHeroActions(
              primary: primary,
              onAdd: () {
                HapticFeedback.mediumImpact();
                context
                    .push<bool>(
                      '/treinos/$treinoId/exercicios/add',
                      extra: alunoId == null ? null : {'alunoId': alunoId},
                    )
                    .then((added) {
                      if (added == true) {
                        ref.invalidate(treinoProvider(treinoId));
                      }
                    });
              },
              onMenu: () => _openMenu(context),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 14, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exercícios',
                  style: AppTypography.inter(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color:
                        isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? heroTealSurface(0.06)
                                : EagleTokens.brandSofter,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color:
                              isDark
                                  ? heroTealSurface(0.08)
                                  : primary.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        '${treino.exercicios.length} ${treino.exercicios.length == 1 ? 'exercício' : 'exercícios'}',
                        style: AppTypography.inter(
                          color: primary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    if (treino.exercicios.length > 1) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Segure e arraste para reordenar',
                        style: AppTypography.inter(
                          color:
                              isDark
                                  ? EagleTokens.darkInkMute
                                  : TokensStrip.textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),

        if (treino.exercicios.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: FxEmptyState(
              icon: 'dumbbell',
              title: 'Nenhum exercício ainda',
              subtitle:
                  'Adicione exercícios da biblioteca curada para montar este treino.',
              action: FxEmptyAction(
                label: 'Adicionar exercício',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context
                      .push<bool>(
                        '/treinos/$treinoId/exercicios/add',
                        extra: alunoId == null ? null : {'alunoId': alunoId},
                      )
                      .then((added) {
                        if (added == true) {
                          ref.invalidate(treinoProvider(treinoId));
                        }
                      });
                },
              ),
            ),
          )
        else
          _TreinoExerciseReorderList(
            exercises: orderedExercises,
            treinoId: treinoId,
            alunoId: alunoId,
            isDark: isDark,
            primary: primary,
            primarySoft: primarySoft,
            repo: repo,
            ref: ref,
            onEditPrescription: openEditPrescription,
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}
