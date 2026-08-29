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
        width: TreinosLayout.headerChromeSize,
        height: TreinosLayout.headerChromeSize,
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
  final String? freshnessLabel;
  final VoidCallback onHelp;
  final Future<void> Function() onRefresh;
  final WidgetRef ref;
  const _TreinoDetailBody({
    required this.treino,
    required this.treinoId,
    required this.alunoId,
    required this.alunoNome,
    required this.isDark,
    required this.freshnessLabel,
    required this.onHelp,
    required this.onRefresh,
    required this.ref,
  });

  Future<void> _openMenu(BuildContext context) async {
    AnalyticsService.instance.track(
      ProductEvents.treinoDetailMenuOpened,
      props: {'id': treinoId},
    );
    final action = await _showTreinoSheet<String>(
      context: context,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.82;
        return TreinoInsetActionSheet(
          isDark: isDark,
          maxHeight: maxHeight,
          headerIcon: Icons.fitness_center_rounded,
          title: 'Ações do treino',
          subtitle: _displayWorkoutName(treino.nome),
          accent: Theme.of(sheetContext).colorScheme.primary,
          actions: [
            TreinoInsetActionSpec(
              icon: Icons.add_rounded,
              label: 'Adicionar exercício',
              showChevron: true,
              onTap: () => Navigator.pop(sheetContext, 'add'),
            ),
            TreinoInsetActionSpec(
              icon: Icons.view_agenda_outlined,
              label: 'Montar por modelo',
              showChevron: true,
              onTap: () => Navigator.pop(sheetContext, 'template_split'),
            ),
            TreinoInsetActionSpec(
              icon: Icons.person_add_alt_1_rounded,
              label: 'Atribuir a aluno',
              showChevron: true,
              onTap: () => Navigator.pop(sheetContext, 'assign'),
            ),
            TreinoInsetActionSpec(
              icon: Icons.assignment_ind_rounded,
              label: 'Copiar para aluno',
              showChevron: true,
              onTap: () => Navigator.pop(sheetContext, 'clone'),
            ),
            TreinoInsetActionSpec(
              icon: Icons.control_point_duplicate_rounded,
              label: 'Duplicar treino',
              onTap: () => Navigator.pop(sheetContext, 'duplicate'),
            ),
            TreinoInsetActionSpec(
              icon: Icons.bookmark_border_rounded,
              label: 'Salvar como template',
              onTap: () => Navigator.pop(sheetContext, 'template'),
            ),
            TreinoInsetActionSpec(
              icon: Icons.delete_outline_rounded,
              label: 'Excluir treino',
              danger: true,
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          ],
        );
      },
    );

    if (!context.mounted || action == null) {
      return;
    }

    final repo = ref.read(treinoRepositoryProvider);

    switch (action) {
      case 'add':
        AnalyticsService.instance.track(
          ProductEvents.treinoDetailAddTapped,
          props: {'source': 'menu', 'id': treinoId},
        );
        final added = await context.push<bool>(
          '/treinos/$treinoId/exercicios/add',
          extra: alunoId == null ? null : {'alunoId': alunoId},
        );
        if (added == true) {
          ref.invalidate(treinoProvider(treinoId));
        }
        break;
      case 'template_split':
        await openMontarPorModelo(
          context: context,
          ref: ref,
          treinoId: treinoId,
          alreadyInTreinoIds:
              treino.exercicios.map((item) => item.exercicio.id).toSet(),
        );
        break;
      case 'assign':
        try {
          final alunos = await ref.read(alunosProvider.future);
          if (!context.mounted) return;
          final selected = await _showTreinoSheet<int>(
            context: context,
            builder:
                (dialogContext) =>
                    _AssignWorkoutSheet(alunos: alunos, isDark: isDark),
          );
          if (selected == null) return;
          await repo.atribuirAluno(treinoId, selected);
          AnalyticsService.instance.track(
            ProductEvents.treinosAssigned,
            props: {'source': 'detail', 'id': treinoId},
          );
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
          final selected = await _showTreinoSheet<int>(
            context: context,
            builder:
                (dialogContext) =>
                    _AssignWorkoutSheet(alunos: alunos, isDark: isDark),
          );
          if (selected == null) return;
          await repo.clonarParaAluno(treinoId, selected);
          AnalyticsService.instance.track(
            ProductEvents.treinosCloned,
            props: {'source': 'detail', 'id': treinoId},
          );
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
          AnalyticsService.instance.track(
            ProductEvents.treinosDuplicated,
            props: {'source': 'detail', 'id': treinoId},
          );
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
        final confirm = await _showTreinoSheet<bool>(
          context: context,
          builder:
              (dialogContext) =>
                  _DeleteTrainingSheet(title: treino.nome, isDark: isDark),
        );
        if (confirm != true) break;
        HapticFeedback.mediumImpact();
        try {
          await repo.excluirTreino(treinoId);
          AnalyticsService.instance.track(
            ProductEvents.treinosDeleted,
            props: {'source': 'detail', 'id': treinoId},
          );
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
    final soft = BrandPalette.softened(primary);
    final chrome = ShellChrome.forDark(isDark);
    final contextLabel = _workoutContextLabel(treino, alunoNome);
    final displayName = _displayWorkoutName(treino.nome);
    final orderedExercises = [...treino.exercicios]
      ..sort((a, b) => a.ordem.compareTo(b.ordem));
    final metaLine = treinoDetailMetaLine(orderedExercises);

    Future<void> openEditPrescription(TreinoExercicioItem item) async {
      HapticFeedback.selectionClick();
      final saved = await _showTreinoSheet<bool>(
        context: context,
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

    Future<void> openAdd({String source = 'cta'}) async {
      HapticFeedback.mediumImpact();
      AnalyticsService.instance.track(
        ProductEvents.treinoDetailAddTapped,
        props: {'source': source, 'id': treinoId},
      );
      final added = await context.push<bool>(
        '/treinos/$treinoId/exercicios/add',
        extra: alunoId == null ? null : {'alunoId': alunoId},
      );
      if (added == true) {
        ref.invalidate(treinoProvider(treinoId));
      }
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: FxContentWidthLimiter(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: fxTransparent,
              surfaceTintColor: fxTransparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              leadingWidth: 52,
              leading: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: _TreinoDetailBackButton(alunoId: alunoId),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(
                    right: TreinosLayout.headerChromeGap,
                  ),
                  child: FxHelpIconButton(
                    tooltip: 'Como montar este treino',
                    onTap: onHelp,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: TokensStrip.s3),
                  child: IconButton(
                    tooltip: 'Opções do treino',
                    onPressed: () => _openMenu(context),
                    icon: Container(
                      width: TreinosLayout.headerChromeSize,
                      height: TreinosLayout.headerChromeSize,
                      decoration: chrome.headerAction(radius: 12),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 18,
                        color: chrome.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s2,
                  FxSettingsLayout.pageInset,
                  TokensStrip.s3,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contextLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FocuxHubTypography.eyebrow(
                        context,
                        color: chrome.mute,
                      ),
                    ),
                    SizedBox(height: TokensStrip.s1),
                    Text(
                      displayName,
                      style: FocuxHubTypography.pageTitle(
                        context,
                        color: chrome.ink,
                      ),
                    ),
                    SizedBox(height: TokensStrip.s2),
                    Text(
                      metaLine,
                      style: FocuxHubTypography.bodyMuted(
                        color: chrome.mute,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (freshnessLabel != null &&
                        freshnessLabel!.isNotEmpty) ...[
                      SizedBox(height: TokensStrip.s1),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          freshnessLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FocuxHubTypography.bodyMuted(
                            color: chrome.mute,
                            fontWeight: FontWeight.w600,
                          ).copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s2,
                  FxSettingsLayout.pageInset,
                  TokensStrip.s3,
                ),
                child: FxSettingsGroup(
                  accent: primary,
                  children: [
                    FxSettingsTile(
                      icon: Icons.add_rounded,
                      accent: soft,
                      label: 'Adicionar exercício',
                      value: '',
                      highlight: true,
                      showDivider: false,
                      onTap: () => openAdd(),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s3,
                  FxSettingsLayout.pageInset,
                  TokensStrip.s2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Exercícios',
                        style: FocuxHubTypography.sectionTitle(
                          context,
                          color: chrome.ink,
                        ),
                      ),
                    ),
                    if (orderedExercises.length > 1)
                      Text(
                        'Segure para reordenar',
                        style: FocuxHubTypography.bodyMuted(
                          color: chrome.mute,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (treino.exercicios.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    0,
                    FxSettingsLayout.pageInset,
                    32,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: FxSettingsGroup(
                      caption:
                          'Adicione exercícios da biblioteca curada para montar este treino.',
                      accent: primary,
                      children: [
                        FxSettingsTile(
                          icon: Icons.fitness_center_rounded,
                          accent: soft,
                          label: 'Nenhum exercício ainda',
                          subtitle: 'Adicionar exercício',
                          value: '',
                          highlight: true,
                          onTap: () => openAdd(source: 'empty'),
                        ),
                        FxSettingsTile(
                          icon: Icons.view_agenda_outlined,
                          accent: soft,
                          label: 'Montar por modelo',
                          subtitle: 'ABC, full body, superior/inferior…',
                          value: '',
                          showDivider: false,
                          onTap: () => openMontarPorModelo(
                            context: context,
                            ref: ref,
                            treinoId: treinoId,
                            alreadyInTreinoIds: const {},
                          ),
                        ),
                      ],
                    ),
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
                repo: repo,
                ref: ref,
                onEditPrescription: openEditPrescription,
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}
