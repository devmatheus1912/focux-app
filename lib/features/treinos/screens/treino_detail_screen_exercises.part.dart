part of 'treino_detail_screen.dart';

/// Lista única do treino: seções fixas (Aquecimento · Trabalho · Alongamento)
/// com os exercícios de cada uma. Os exercícios arrastam pela alça, inclusive
/// de uma seção para outra; os cabeçalhos não se movem.
class _TreinoListaUnica extends StatefulWidget {
  final List<TreinoExercicioItem> exercises;
  final int treinoId;
  final int? alunoId;
  final bool isDark;
  final Color primary;
  final TreinoRepository repo;
  final WidgetRef ref;
  final Map<String, String> nomesDosBlocos;
  final Future<void> Function(TreinoExercicioItem item) onEditPrescription;
  final void Function(String bloco) onAdd;

  const _TreinoListaUnica({
    super.key,
    required this.exercises,
    required this.treinoId,
    required this.alunoId,
    required this.isDark,
    required this.primary,
    required this.repo,
    required this.ref,
    required this.nomesDosBlocos,
    required this.onEditPrescription,
    required this.onAdd,
  });

  @override
  State<_TreinoListaUnica> createState() => _TreinoListaUnicaState();
}

class _TreinoListaUnicaState extends State<_TreinoListaUnica> {
  late List<LinhaTreino> _linhas;

  @override
  void initState() {
    super.initState();
    _linhas = linhasDoTreino(widget.exercises);
  }

  @override
  void didUpdateWidget(covariant _TreinoListaUnica oldWidget) {
    super.didUpdateWidget(oldWidget);
    _linhas = linhasDoTreino(widget.exercises);
  }

  /// Grava o bloco novo (quando mudou) e a ordem global. Em falha, volta ao
  /// que o servidor tinha.
  Future<void> _gravar(MovimentoDeTreino movimento) async {
    try {
      if (movimento.mudouDeBloco) {
        final item = movimento.movido;
        await widget.repo.salvarSeries(
          widget.treinoId,
          item.id,
          linhas: _linhasDe(item),
          bloco: movimento.blocoNovo,
          descansoSegundos: item.descansoSegundos,
        );
      }
      await widget.repo.reordenarExercicios(
        widget.treinoId,
        movimento.idsEmOrdem,
      );
      widget.ref.invalidate(treinoProvider(widget.treinoId));
    } catch (error) {
      if (!mounted) return;
      setState(() => _linhas = linhasDoTreino(widget.exercises));
      FeedbackHelper.showError(
        context,
        friendlyError(error, fallback: 'Erro ao reordenar exercícios.'),
      );
    }
  }

  List<SeriePrescrita> _linhasDe(TreinoExercicioItem item) {
    if (item.seriesLinhas.isNotEmpty) return item.seriesLinhas;
    return [
      for (var n = 1; n <= item.series; n++)
        SeriePrescrita(
          numero: n,
          repeticoes: item.repeticoes,
          cargaKg: item.cargaKg,
        ),
    ];
  }

  Future<void> _onReorderItem(int oldIndex, int newIndex) async {
    final movimento = moverNaLista(_linhas, oldIndex, newIndex);
    if (movimento == null) return;
    HapticFeedback.mediumImpact();
    // Reflexo imediato; em falha, `_gravar` volta ao que o servidor tinha.
    setState(() => _linhas = _linhasAposMovimento(movimento));
    await _gravar(movimento);
  }

  /// Refaz a lista com o exercício movido já no bloco novo.
  List<LinhaTreino> _linhasAposMovimento(MovimentoDeTreino m) {
    final blocoDe = {
      for (final item in m.itens)
        item.id: item.id == m.movido.id ? m.blocoNovo : item.bloco,
    };
    return [
      for (final bloco in blocosDoTreino)
        if (blocosFixos.contains(bloco) || blocoDe.values.contains(bloco)) ...[
          LinhaSecao(bloco),
          for (final item in m.itens)
            if (blocoDe[item.id] == bloco) LinhaItem(item),
        ],
    ];
  }

  Future<void> _moverPara(TreinoExercicioItem item, String bloco) async {
    final movimento = moverParaBloco(widget.exercises, item, bloco);
    HapticFeedback.mediumImpact();
    await _gravar(movimento);
  }

  Future<void> _escolherBloco(TreinoExercicioItem item) async {
    final destino = await showFxInsetPickerSheet<String>(
      context,
      title: 'Mover para',
      subtitle: item.exercicio.nomeDisplay,
      items: [
        for (final bloco in blocosFixos)
          if (bloco != item.bloco)
            FxInsetPickerSheetItem(
              value: bloco,
              label: widget.nomesDosBlocos[bloco] ?? bloco,
            ),
      ],
    );
    if (destino == null || !mounted) return;
    await _moverPara(item, destino);
  }

  Future<void> _remover(TreinoExercicioItem te) async {
    HapticFeedback.mediumImpact();
    try {
      await widget.repo.removerExercicio(widget.treinoId, te.id);
      widget.ref.invalidate(treinoProvider(widget.treinoId));
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showApiFailure(
          context,
          e,
          fallback: 'Erro ao remover exercício.',
        );
      }
      return;
    }
    if (!mounted) return;
    final desfazer = await FeedbackHelper.showUndo(
      context,
      '${te.exercicio.nomeDisplay} saiu do treino.',
    );
    if (!desfazer) return;
    try {
      final treino = await widget.repo.adicionarExercicio(
        widget.treinoId,
        te.exercicio.id,
        series: te.series,
        repeticoes: te.repeticoes,
        descanso: te.descansoSegundos ?? 60,
        cargaKg: te.cargaKg,
        rpeAlvo: te.rpeAlvo,
        observacoes: te.observacoes,
        tipoSerie: te.tipoSerie,
        grupoSuperset: te.grupoSuperset,
      );
      final novo = treino.exercicios
          .where((e) => e.exercicio.id == te.exercicio.id)
          .fold<TreinoExercicioItem?>(
            null,
            (a, e) => a == null || e.id > a.id ? e : a,
          );
      if (novo != null) {
        await widget.repo.salvarSeries(
          widget.treinoId,
          novo.id,
          linhas: _linhasDe(te),
          bloco: te.bloco,
          descansoSegundos: te.descansoSegundos,
        );
      }
      widget.ref.invalidate(treinoProvider(widget.treinoId));
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showApiFailure(
          context,
          e,
          fallback: 'Não foi possível desfazer.',
        );
      }
    }
  }

  Future<void> _duplicar(TreinoExercicioItem te) async {
    try {
      await widget.repo.duplicarExercicio(widget.treinoId, te.id);
      widget.ref.invalidate(treinoProvider(widget.treinoId));
    } catch (error) {
      if (mounted) {
        FeedbackHelper.showApiFailure(
          context,
          error,
          fallback: 'Erro ao duplicar exercício.',
        );
      }
    }
  }

  Future<void> _substituir(TreinoExercicioItem te) async {
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
                  FeedbackHelper.showApiFailure(
                    context,
                    error,
                    fallback: 'Erro ao substituir exercício.',
                  );
                }
              }
            },
            onCriarNovo: () => context.push('/exercicios/novo'),
          ),
    );
  }

  Future<void> _menu(TreinoExercicioItem te) async {
    HapticFeedback.selectionClick();
    AnalyticsService.instance.track(
      ProductEvents.treinoExerciseMenuOpened,
      props: {'id': te.id},
    );
    final acao = await showFxGroupedActionSheet<String>(
      context,
      titulo: 'Ações do exercício',
      subtitulo: te.exercicio.nomeDisplay,
      icone: Icons.fitness_center_rounded,
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: 'edit',
            rotulo: 'Editar prescrição',
            icone: Icons.edit_note_rounded,
          ),
          FxActionItem(
            valor: 'move',
            rotulo: 'Mover para…',
            icone: Icons.drive_file_move_outline,
          ),
          FxActionItem(
            valor: 'duplicate',
            rotulo: 'Duplicar',
            icone: Icons.copy_rounded,
          ),
          FxActionItem(
            valor: 'substitute',
            rotulo: 'Substituir',
            icone: Icons.swap_horiz_rounded,
          ),
        ]),
      ],
      destrutiva: FxActionItem(
        valor: 'remove',
        rotulo: 'Remover do treino',
        icone: Icons.remove_circle_outline_rounded,
      ),
      confirmar: false,
    );
    if (!mounted) return;
    switch (acao) {
      case 'edit':
        await widget.onEditPrescription(te);
      case 'move':
        await _escolherBloco(te);
      case 'duplicate':
        await _duplicar(te);
      case 'substitute':
        await _substituir(te);
      case 'remove':
        await _remover(te);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forBrightness(context, widget.isDark);
    return SliverReorderableList(
      itemCount: _linhas.length,
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
        final linha = _linhas[index];
        if (linha is LinhaSecao) {
          final vazia =
              index + 1 >= _linhas.length || _linhas[index + 1] is LinhaSecao;
          return _SecaoDoTreino(
            key: ValueKey('secao-${linha.bloco}'),
            nome: widget.nomesDosBlocos[linha.bloco] ?? linha.bloco,
            vazia: vazia,
            quantidade: _quantidadeNaSecao(index),
            isDark: widget.isDark,
            primary: widget.primary,
            onAdd: () => widget.onAdd(linha.bloco),
            ink: chrome.ink,
          );
        }
        final te = (linha as LinhaItem).item;
        final primeiro = _linhas[index - 1] is LinhaSecao;
        final ultimo =
            index + 1 >= _linhas.length || _linhas[index + 1] is LinhaSecao;
        return Padding(
          key: ValueKey('item-${te.id}'),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            margin: EdgeInsets.only(
              bottom: ultimo ? TreinosLayout.exerciseGroupGap : 0,
            ),
            decoration: fxListCardDecoration(
              context,
              accent: widget.primary,
            ).copyWith(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(primeiro ? TokensStrip.rCard : 0),
                bottom: Radius.circular(ultimo ? TokensStrip.rCard : 0),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _ExercicioRow(
              te: te,
              reorderIndex: index,
              isDark: widget.isDark,
              isLast: ultimo,
              onEditPrescription: () => widget.onEditPrescription(te),
              onMenu: () => _menu(te),
            ),
          ),
        );
      },
    );
  }

  int _quantidadeNaSecao(int indiceDaSecao) {
    var n = 0;
    for (var i = indiceDaSecao + 1; i < _linhas.length; i++) {
      if (_linhas[i] is LinhaSecao) break;
      n++;
    }
    return n;
  }
}

/// Cabeçalho de seção: nome, quantos exercícios e "+ Adicionar". Seção vazia
/// ganha uma linha convidativa.
class _SecaoDoTreino extends StatelessWidget {
  const _SecaoDoTreino({
    super.key,
    required this.nome,
    required this.vazia,
    required this.quantidade,
    required this.isDark,
    required this.primary,
    required this.onAdd,
    required this.ink,
  });

  final String nome;
  final bool vazia;
  final int quantidade;
  final bool isDark;
  final Color primary;
  final VoidCallback onAdd;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forBrightness(context, isDark);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        TokensStrip.s2,
        FxSettingsLayout.pageInset,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    quantidade > 0 ? '$nome · $quantidade' : nome,
                    style: FocuxHubTypography.cardTitle(color: ink),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('Adicionar', semanticsLabel: 'Adicionar em $nome'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: primary,
                ),
              ),
            ],
          ),
          if (vazia)
            Padding(
              padding: const EdgeInsets.only(bottom: TokensStrip.s3),
              child: Material(
                color: fxTransparent,
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(TokensStrip.rCard),
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(TokensStrip.rCard),
                      border: Border.all(color: chrome.lineStrong),
                    ),
                    child: Text(
                      'Nenhum exercício. Toque para adicionar.',
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
