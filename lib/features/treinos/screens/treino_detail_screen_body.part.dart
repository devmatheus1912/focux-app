part of 'treino_detail_screen.dart';

Future<void> _openTreinoDetailMenu({
  required BuildContext context,
  required WidgetRef ref,
  required Treino treino,
  required int treinoId,
  required int? alunoId,
  required bool isDark,
}) async {
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
              onTap: () => Navigator.pop(sheetContext, 'template_split'),
            ),
            TreinoInsetActionSpec(
              icon: Icons.person_add_alt_1_rounded,
              label: 'Atribuir a aluno',
              onTap: () => Navigator.pop(sheetContext, 'assign'),
            ),
            TreinoInsetActionSpec(
              icon: Icons.stay_current_landscape_rounded,
              label: 'Modo presencial',
              showChevron: true,
              onTap: () => Navigator.pop(sheetContext, 'presencial'),
            ),
            TreinoInsetActionSpec(
              icon: Icons.assignment_ind_rounded,
              label: 'Copiar para aluno',
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

    await _dispatchTreinoDetailAction(
      context: context,
      ref: ref,
      treino: treino,
      treinoId: treinoId,
      alunoId: alunoId,
      isDark: isDark,
      action: action,
    );
}

class _TreinoDetailBody extends StatelessWidget {
  final Treino treino;
  final int treinoId;
  final int? alunoId;
  final String? alunoNome;
  final bool isDark;
  final Future<void> Function() onRefresh;
  final WidgetRef ref;
  const _TreinoDetailBody({
    required this.treino,
    required this.treinoId,
    required this.alunoId,
    required this.alunoNome,
    required this.isDark,
    required this.onRefresh,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(treinoRepositoryProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forBrightness(context, isDark);
    final contextLabel = _workoutContextLabel(treino, alunoNome);
    final displayName = _displayWorkoutName(treino.nome);
    final orderedExercises = [...treino.exercicios]
      ..sort((a, b) => a.ordem.compareTo(b.ordem));

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

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: FxContentWidthLimiter(
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s2,
                  FxSettingsLayout.pageInset,
                  TokensStrip.s3,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FxHubHeader(
                      title: displayName,
                      subtitle: contextLabel,
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    Wrap(
                      spacing: TokensStrip.s2,
                      runSpacing: TokensStrip.s2,
                      children: [
                        DashboardHomeActionChip(
                          label: 'Lista',
                          accent: primary,
                          isDark: isDark,
                          onPressed: () => _popTreinoDetail(
                            context,
                            alunoId: alunoId,
                          ),
                        ),
                        if (alunoId != null)
                          DashboardHomeActionChip(
                            label: 'Aluno',
                            accent: primary,
                            isDark: isDark,
                            onPressed: () =>
                                context.push('/alunos/$alunoId'),
                          ),
                        DashboardHomeActionChip(
                          label: 'Atribuir',
                          accent: primary,
                          isDark: isDark,
                          onPressed: () => _dispatchTreinoDetailAction(
                            context: context,
                            ref: ref,
                            treino: treino,
                            treinoId: treinoId,
                            alunoId: alunoId,
                            isDark: isDark,
                            action: 'assign',
                          ),
                        ),
                        DashboardHomeActionChip(
                          label: 'Duplicar',
                          accent: primary,
                          isDark: isDark,
                          onPressed: () => _dispatchTreinoDetailAction(
                            context: context,
                            ref: ref,
                            treino: treino,
                            treinoId: treinoId,
                            alunoId: alunoId,
                            isDark: isDark,
                            action: 'duplicate',
                          ),
                        ),
                      ],
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
                  child: FxEmptyState(
                    icon: 'dumbbell',
                    title: 'Nenhum exercício ainda',
                    subtitle:
                        'Adicione da biblioteca ou monte rápido por um modelo de split.',
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
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              TokensStrip.s2,
              FxSettingsLayout.pageInset,
              TokensStrip.s3 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child:
                treino.exercicios.isEmpty
                    ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FxLiquidPrimaryButton(
                          label: 'Adicionar exercício',
                          onPressed: () => openAdd(),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => openMontarPorModelo(
                            context: context,
                            ref: ref,
                            treinoId: treinoId,
                            alreadyInTreinoIds: const {},
                          ),
                          child: const Text('Montar por modelo'),
                        ),
                      ],
                    )
                    : FxLiquidPrimaryButton(
                      label: 'Adicionar exercício',
                      onPressed: () => openAdd(),
                    ),
          ),
        ),
      ],
    );
  }
}
