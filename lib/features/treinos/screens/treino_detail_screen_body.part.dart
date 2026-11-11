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
          headerIcon: FxIcons.treino,
          title: 'Ações do treino',
          subtitle: _displayWorkoutName(treino.nome),
          accent: Theme.of(sheetContext).colorScheme.primary,
          actions: [
            TreinoInsetActionSpec(
              icon: FxIcons.adicionar,
              label: 'Adicionar exercício',
              grupo: 'Montar',
              onTap: () => Navigator.pop(sheetContext, 'add'),
            ),
            // O objetivo é da sessão: define a prescrição de quem entra.
            TreinoInsetActionSpec(
              icon: FxIcons.meta,
              label: _rotuloDoObjetivo(treino.objetivo) == null
                  ? 'Objetivo da sessão'
                  : 'Objetivo da sessão · ${_rotuloDoObjetivo(treino.objetivo)}',
              grupo: 'Montar',
              onTap: () => Navigator.pop(sheetContext, 'objetivo'),
            ),
            if (naSemana || temSugestao)
              TreinoInsetActionSpec(
                icon: FxIcons.ia,
                label: s.treinoSugerirExercicios,
                grupo: 'Montar',
                onTap: () => Navigator.pop(sheetContext, 'sugerir'),
              ),
            TreinoInsetActionSpec(
              icon: FxIcons.editar,
              label: s.treinoRenomear,
              grupo: 'Montar',
              onTap: () => Navigator.pop(sheetContext, 'rename'),
            ),
            if (naSemana)
              TreinoInsetActionSpec(
                icon: FxIcons.copiar,
                label: s.rotinaCopiarDia,
                grupo: 'Semana',
                onTap: () => Navigator.pop(sheetContext, 'copy_day'),
              )
            else ...[
              TreinoInsetActionSpec(
                icon: FxIcons.duplicar,
                label: s.treinoDuplicarSessao,
                grupo: 'Usar',
                onTap: () => Navigator.pop(sheetContext, 'duplicate'),
              ),
              TreinoInsetActionSpec(
                icon: FxIcons.adicionarPessoa,
                label: s.treinoAplicarNaFicha,
                grupo: 'Usar',
                subtitle: s.treinoDetalheCopiarSubtitulo,
                onTap: () => Navigator.pop(sheetContext, 'assign'),
              ),
            ],
            if (naSemana)
              TreinoInsetActionSpec(
                icon: FxIcons.removerCirculo,
                label: lugar == LugarDoTreino.ficha ? s.treinoTirarDaFicha : s.treinoTirarDoModelo,
                danger: true,
                onTap: () => Navigator.pop(sheetContext, 'remove_from'),
              )
            else
              TreinoInsetActionSpec(
                icon: FxIcons.excluir,
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
    );
}

class _TreinoDetailBody extends StatelessWidget {
  final Treino treino;
  final bool salvando;
  final int treinoId;
  final int? alunoId;
  final String? alunoNome;
  final int? modeloId;
  final bool isDark;
  final Future<void> Function() onRefresh;
  final WidgetRef ref;
  const _TreinoDetailBody({
    required this.treino,
    required this.salvando,
    required this.treinoId,
    required this.alunoId,
    required this.alunoNome,
    required this.modeloId,
    required this.isDark,
    required this.onRefresh,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(treinoRepositoryProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forBrightness(context, isDark);
    final orderedExercises = [...treino.exercicios]
      ..sort((a, b) => a.ordem.compareTo(b.ordem));
    final s = S.of(context);
    final nomesDosBlocos = {
      'AQUECIMENTO': s.treinoBlocoAquecimento,
      'TRABALHO': s.treinoBlocoTrabalho,
      'ALONGAMENTO': s.treinoBlocoAlongamento,
      'AJUSTE': s.treinoBlocoAjuste,
    };

    Future<void> openEditPrescription(
      TreinoExercicioItem item, [
      String? adicionarPapel,
    ]) async {
      HapticFeedback.selectionClick();
      final saved = await _showTreinoSheet<Object>(
        context: context,
        builder:
            (_) => _EditPrescriptionSheet(
              treinoId: treinoId,
              item: item,
              isDark: isDark,
              repo: repo,
              adicionarPapel: adicionarPapel,
              outrosNoBloco: [
                for (final e in orderedExercises)
                  if (e.id != item.id && e.bloco == item.bloco) e,
              ],
            ),
      );
      if (saved == null || saved == false) return;
      sessaoMudou(ref, treinoId, alunoId: alunoId, modeloId: modeloId);
      if (!context.mounted) return;
      if (saved case PrescricaoAplicadaAoBloco(:final quantos, :final desfazer)) {
        FeedbackHelper.showSuccessAction(
          context,
          quantos == 1
              ? 'Prescrição aplicada a mais 1 exercício.'
              : 'Prescrição aplicada a mais $quantos exercícios.',
          actionLabel: 'Desfazer',
          onAction: () async {
            await desfazer();
            sessaoMudou(ref, treinoId, alunoId: alunoId, modeloId: modeloId);
          },
        );
      } else {
        FeedbackHelper.showSuccess(context, 'Prescrição atualizada.');
      }
    }

    Future<void> openAdd({String source = 'cta', String destino = 'TRABALHO'}) async {
      HapticFeedback.mediumImpact();
      AnalyticsService.instance.track(
        ProductEvents.treinoDetailAddTapped,
        props: {'source': source, 'id': treinoId},
      );
      await context.push(
        '/treinos/$treinoId/exercicios/add',
        extra:
            TreinoRouteExtra(
              alunoId: alunoId,
              modeloId: modeloId,
              bloco: destino,
            ).toExtra(),
      );
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
                    // Uma linha: estado do salvo à esquerda, contexto à direita.
                    if (alunoId != null)
                      FichaContextoDoTreino(
                        alunoId: alunoId!,
                        alunoNome: alunoNome,
                        treinoId: treinoId,
                        inicio: EstadoDoSalvo(salvando: salvando),
                      )
                    else if (modeloId != null)
                      ModeloContextoDoTreino(
                        modeloId: modeloId!,
                        treinoId: treinoId,
                        inicio: EstadoDoSalvo(salvando: salvando),
                      )
                    else
                      EstadoDoSalvo(salvando: salvando),

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
                    icon: FxIcons.treino,
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
                modeloId: modeloId,
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
              TokensStrip.s3,
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
                            alunoId: alunoId,
                            modeloId: modeloId,
                            nomeDaSessao: treino.nome,
                            alreadyInTreinoIds: const {},
                          ), compact: true),
                      ],
                    )
                    : alunoId != null || modeloId != null
                    ? MontarEmSequencia(
                      treinoId: treinoId,
                      alunoId: alunoId,
                      alunoNome: alunoNome,
                      modeloId: modeloId,
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
