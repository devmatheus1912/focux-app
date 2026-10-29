part of 'treino_detail_screen.dart';

Future<void> _openTreinoDetailMenu({
  required BuildContext context,
  required WidgetRef ref,
  required Treino treino,
  required int treinoId,
  required int? alunoId,
  required String? alunoNome,
  required int? modeloId,
  required bool isDark,
  required VoidCallback onAssigned,
}) async {
    AnalyticsService.instance.track(
      ProductEvents.treinoDetailMenuOpened,
      props: {'id': treinoId},
    );
    final lugar = lugarDoTreino(alunoId: alunoId, modeloId: modeloId);
    final naSemana = lugar != LugarDoTreino.biblioteca;
    final temSugestao = sugestaoDaSessao(treino.nome) != null;
    final action = await _showTreinoSheet<String>(
      context: context,
      builder: (sheetContext) {
        final s = S.of(sheetContext);
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
              grupo: 'Montar',
              showChevron: true,
              onTap: () => Navigator.pop(sheetContext, 'add'),
            ),
            if (naSemana || temSugestao)
              TreinoInsetActionSpec(
                icon: Icons.auto_awesome_rounded,
                label: temSugestao
                    ? s.treinoSugerirDe(treino.nome.trim())
                    : s.treinoSugerirExercicios,
                grupo: 'Montar',
                onTap: () => Navigator.pop(sheetContext, 'sugerir'),
              ),
            TreinoInsetActionSpec(
              icon: Icons.edit_outlined,
              label: s.treinoRenomear,
              grupo: 'Montar',
              onTap: () => Navigator.pop(sheetContext, 'rename'),
            ),
            if (naSemana)
              TreinoInsetActionSpec(
                icon: Icons.copy_rounded,
                label: s.rotinaCopiarDia,
                grupo: 'Semana',
                onTap: () => Navigator.pop(sheetContext, 'copy_day'),
              )
            else ...[
              TreinoInsetActionSpec(
                icon: Icons.control_point_duplicate_rounded,
                label: s.treinoDuplicarSessao,
                grupo: 'Usar',
                onTap: () => Navigator.pop(sheetContext, 'duplicate'),
              ),
              TreinoInsetActionSpec(
                icon: Icons.person_add_alt_1_rounded,
                label: s.treinoAplicarNaFicha,
                grupo: 'Usar',
                subtitle: s.treinoDetalheCopiarSubtitulo,
                onTap: () => Navigator.pop(sheetContext, 'assign'),
              ),
            ],
            if (naSemana)
              TreinoInsetActionSpec(
                icon: Icons.remove_circle_outline_rounded,
                label: lugar == LugarDoTreino.ficha ? s.treinoTirarDaFicha : s.treinoTirarDoModelo,
                danger: true,
                onTap: () => Navigator.pop(sheetContext, 'remove_from'),
              )
            else
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
      alunoNome: alunoNome,
      modeloId: modeloId,
      isDark: isDark,
      action: action,
      onAssigned: onAssigned,
    );
}

class _TreinoDetailBody extends StatelessWidget {
  final Treino treino;
  final int treinoId;
  final int? alunoId;
  final String? alunoNome;
  final int? modeloId;
  final bool isDark;
  final bool atribuirEmDestaque;
  final VoidCallback onAssigned;
  final Future<void> Function() onRefresh;
  final WidgetRef ref;
  const _TreinoDetailBody({
    required this.treino,
    required this.treinoId,
    required this.alunoId,
    required this.alunoNome,
    required this.modeloId,
    required this.isDark,
    required this.atribuirEmDestaque,
    required this.onAssigned,
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
    final s = S.of(context);
    final nomesDosBlocos = {
      'AQUECIMENTO': s.treinoBlocoAquecimento,
      'TRABALHO': s.treinoBlocoTrabalho,
      'ALONGAMENTO': s.treinoBlocoAlongamento,
      'AJUSTE': s.treinoBlocoAjuste,
    };

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
              outrosNoBloco: [
                for (final e in orderedExercises)
                  if (e.id != item.id && e.bloco == item.bloco) e,
              ],
            ),
      );
      if (saved != true) return;
      ref.invalidate(treinoProvider(treinoId));
      if (context.mounted) {
        FeedbackHelper.showSuccess(context, 'Prescrição atualizada.');
      }
    }

    Future<void> openAdd({String source = 'cta', String destino = 'TRABALHO'}) async {
      HapticFeedback.mediumImpact();
      AnalyticsService.instance.track(
        ProductEvents.treinoDetailAddTapped,
        props: {'source': source, 'id': treinoId},
      );
      final added = await context.push<bool>(
        '/treinos/$treinoId/exercicios/add',
        extra: TreinoRouteExtra(alunoId: alunoId, bloco: destino).toExtra(),
      );
      if (added == true) {
        ref.invalidate(treinoProvider(treinoId));
      }
    }

    Future<void> openAssign() => _dispatchTreinoDetailAction(
      context: context,
      ref: ref,
      treino: treino,
      treinoId: treinoId,
      alunoId: alunoId,
      isDark: isDark,
      action: 'assign',
      onAssigned: onAssigned,
    );

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
                      subtitle:
                          alunoId == null && modeloId == null
                              ? contextLabel
                              : null,
                    ),
                    if (alunoId != null)
                      FichaContextoDoTreino(
                        alunoId: alunoId!,
                        alunoNome: alunoNome,
                        treinoId: treinoId,
                      )
                    else if (modeloId != null)
                      ModeloContextoDoTreino(
                        modeloId: modeloId!,
                        treinoId: treinoId,
                      )

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
                    Padding(
                      padding: const EdgeInsets.only(right: TokensStrip.s2),
                      child: Text(
                        'Exercícios',
                        style: FocuxHubTypography.sectionTitle(
                          context,
                          color: chrome.ink,
                        ),
                      ),
                    ),
                    if (orderedExercises.isNotEmpty)
                      Flexible(
                        child: Text(
                          treinoResumoLinha(orderedExercises),
                          maxLines: 2,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: FocuxHubTypography.bodyMuted(
                            color: chrome.mute,
                            fontWeight: FontWeight.w600,
                          ),
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
            else ...[
              _TreinoListaUnica(
                key: const ValueKey('lista-unica'),
                exercises: orderedExercises,
                treinoId: treinoId,
                alunoId: alunoId,
                isDark: isDark,
                primary: primary,
                repo: repo,
                ref: ref,
                nomesDosBlocos: nomesDosBlocos,
                onEditPrescription: openEditPrescription,
                onAdd: (bloco) => openAdd(source: 'bloco', destino: bloco),
              ),
            ],
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
                        FxTonalButton(label: sugestaoDaSessao(treino.nome) != null
                            ? S.of(context).treinoSugerirDe(treino.nome.trim())
                            : S.of(context).treinoSugerirExercicios, onPressed: () => openSugerirExercicios(
                            context: context,
                            ref: ref,
                            treinoId: treinoId,
                            nomeDaSessao: treino.nome,
                            alreadyInTreinoIds: const {},
                          ), compact: true),
                      ],
                    )
                    : atribuirEmDestaque
                    ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FxLiquidPrimaryButton(
                          label: S.of(context).treinoDetalheAtribuirAluno,
                          onPressed: openAssign,
                        ),
                        const SizedBox(height: 8),
                        FxTonalButton(label: 'Adicionar exercício', onPressed: () => openAdd(), compact: true),
                      ],
                    )
                    : alunoId != null || modeloId != null
                    ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FxLiquidPrimaryButton(
                          label: 'Adicionar exercício',
                          onPressed: () => openAdd(),
                        ),
                        const SizedBox(height: 8),
                        MontarEmSequencia(
                          treinoId: treinoId,
                          alunoId: alunoId,
                          alunoNome: alunoNome,
                          modeloId: modeloId,
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
