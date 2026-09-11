part of 'ia_copiloto_screen.dart';

extension IaCopilotScreenActions on _IaCopilotoScreenState {
  Future<void> _selecionarAluno() async {
    final List<IaCopilotoAlunoResumo> alunos;
    try {
      alunos = (await ref.read(iaCopilotoHomeProvider.future)).alunosResumo;
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        friendlyError(e, fallback: 'Não foi possível carregar os alunos.'),
      );
      return;
    }
    if (!mounted) return;
    if (alunos.isEmpty) {
      FeedbackHelper.showError(
        context,
        'Você ainda não possui alunos cadastrados.',
      );
      return;
    }
    final search = TextEditingController();
    final escolhido = await showFxHomeSheet<int>(
      context,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        final primary = Theme.of(ctx).colorScheme.primary;
        final ink = dark ? EagleTokens.darkInk : TokensStrip.textPrimary;
        final mute = dark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
        final line = dark ? EagleTokens.darkLine : TokensStrip.borderDefault;
        final cardBg = dark ? EagleTokens.darkCard : TokensStrip.cardBg;
        var query = '';

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered =
                alunos.where((a) {
                  final haystack =
                      '${a.nome} ${a.objetivo ?? ''}'.toLowerCase();
                  return haystack.contains(query.trim().toLowerCase());
                }).toList();

            return Semantics(
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: 'Selecionar aluno, ${filtered.length} de ${alunos.length}',
              child: FxHomeSheetSurface(
                isDark: dark,
                expand: true,
                maxHeight:
                    MediaQuery.sizeOf(ctx).height *
                    FxHomeSheetChrome.expandHeightFactor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FxHomeSheetHandle(isDark: dark),
                    SizedBox(height: TokensStrip.s4),
                    FxHomeSheetHeader(
                      isDark: dark,
                      title: 'Selecionar aluno',
                      subtitle: 'Escolha o aluno para analisar.',
                      leading: Icon(
                        Icons.person_search_outlined,
                        color: primary,
                        size: 18,
                      ),
                      trailing: Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: dark ? 0.16 : 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${filtered.length}/${alunos.length}',
                          style: TextStyle(
                            color: primary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: TokensStrip.s4),
                    TextField(
                      controller: search,
                      onChanged: (value) => setModalState(() => query = value),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Buscar por nome ou objetivo',
                        prefixIcon: Icon(Icons.search, color: mute, size: 20),
                        filled: true,
                        fillColor: cardBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: FxInputDeco.outlineBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: line),
                        ),
                        enabledBorder: FxInputDeco.outlineBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: line),
                        ),
                        focusedBorder: FxInputDeco.outlineBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ListView(
                        children: [
                          if (filtered.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(TokensStrip.s4),
                              decoration: fxListCardDecoration(ctx, radius: 18),
                              child: Text(
                                'Nenhum aluno encontrado para essa busca.',
                                style: TextStyle(
                                  color: mute,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            )
                          else
                            ...filtered.map((a) {
                              final selected = _selectedAlunoId == a.id;
                              final objetivo =
                                  (a.objetivo == null || a.objetivo!.isEmpty)
                                      ? 'Sem objetivo definido'
                                      : a.objetivo!;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => Navigator.of(ctx).pop(a.id),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.all(12),
                                    decoration:
                                        selected
                                            ? fxListCardDecoration(
                                              ctx,
                                              selected: true,
                                              accent: primary,
                                              radius: 18,
                                            )
                                            : fxListCardDecoration(
                                              ctx,
                                              radius: 18,
                                            ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color:
                                                selected
                                                    ? primary
                                                    : primary.withValues(
                                                      alpha: dark ? 0.16 : 0.10,
                                                    ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              _iniciais(a.nome),
                                              style: TextStyle(
                                                color:
                                                    selected
                                                        ? Colors.white
                                                        : primary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                              ),
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
                                                a.nome,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: ink,
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                objetivo,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: mute,
                                                  fontSize: 11.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Icon(
                                          selected
                                              ? Icons.check_circle
                                              : Icons.check_circle_outline,
                                          color: selected ? primary : mute,
                                          size: selected ? 22 : 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(search.dispose);
    if (escolhido == null) return;
    final aluno = alunos.firstWhere((a) => a.id == escolhido);
    setState(() {
      _selectedAlunoId = aluno.id;
      _selectedAlunoNome = aluno.nome;
      _gerado = false;
      _erro = null;
      _proximaAcao = null;
      _tarefaCriada = false;
      _tarefaPersistida = false;
      _aplicando = false;
    });
  }

  String _iniciais(String nome) {
    final partes =
        nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    final first = partes.first.characters.first;
    final second = partes.length > 1 ? partes.last.characters.first : '';
    return ('$first$second').toUpperCase();
  }

  Future<void> _gerar() async {
    if (_selectedAlunoId == null) {
      await _selecionarAluno();
      if (_selectedAlunoId == null) return;
    }
    if (!mounted) return;
    if (!await IaQuotaUpgrade.guardBeforeRequest(context, ref)) return;
    if (!mounted) return;
    final ok = await showFxConfirmSheet(
      context,
      title: iaCopilotoGerarConfirmTitle(_modeDisplay),
      message: iaCopilotoGerarConfirmMessage(),
      confirmLabel: iaCopilotoGerarConfirmLabel(_modeDisplay),
    );
    if (!ok || !mounted) return;

    setState(() {
      _gerando = true;
      _gerado = false;
      _erro = null;
      _geracaoMs = 0;
      _tarefaCriada = false;
      _tarefaPersistida = false;
      _aplicando = false;
    });
    final stopwatch = Stopwatch()..start();
    try {
      await AnalyticsService.instance.track(
        ProductEvents.iaInsightRequested,
        props: {'mode': _mode, 'alunoId': _selectedAlunoId},
      );
      final query = InsightsQuery(alunoId: _selectedAlunoId, mode: _mode);
      ref.invalidate(insightsProvider(query));
      await ref.read(insightsProvider(query).future);
      _proximaAcao = await ref.read(
        proximaAcaoProvider(_selectedAlunoId!).future,
      );
      ref.invalidate(iaCopilotoHomeProvider);
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _gerando = false;
          _gerado = true;
          _geracaoMs = stopwatch.elapsedMilliseconds;
          _fetchedAt = DateTime.now();
        });
      }
    } catch (e) {
      stopwatch.stop();
      await AnalyticsService.instance.track(
        ProductEvents.iaCopilotFailure,
        props: {
          'mode': _mode,
          'error': e.toString(),
          if (e is IaOperationalException) 'retryable': e.retryable,
          if (e is IaOperationalException && e.reference != null)
            'reference': e.reference,
        },
      );
      if (mounted) {
        setState(() {
          _gerando = false;
          _erro = e;
        });
        ref.invalidate(iaCopilotoHomeProvider);
        await IaQuotaUpgrade.handleError(context, ref, e);
      }
    }
  }

  bool _erroSugereUpgrade(Object erro) =>
      erro is IaOperationalException && erro.suggestsUpgrade;

  Future<void> _mostrarUpgradePorErro() async {
    if (_erro is IaOperationalException) {
      await IaQuotaUpgrade.showUpgradeDialog(
        context,
        ref,
        error: _erro! as IaOperationalException,
        features: ref.read(planoFeaturesProvider).valueOrNull,
      );
    }
  }

  String _erroIaTexto(Object erro) {
    if (erro is IaOperationalException) {
      final refText = erro.reference == null ? '' : ' Ref: ${erro.reference}.';
      if (erro.retryable) {
        return '${erro.message}$refText Tente novamente em alguns instantes.';
      }
      return '${erro.message}$refText';
    }
    return friendlyError(erro, fallback: FocuxMicrocopy.iaErroGenerico);
  }

  Future<void> _atribuir() async {
    if (_selectedAlunoId == null) {
      await _selecionarAluno();
      if (_selectedAlunoId == null) return;
    }
    try {
      final repo = IaRepository(ref.read(apiClientProvider));
      final acaoAtual =
          _proximaAcao ?? await repo.proximaAcao(_selectedAlunoId!);
      final textoAcao =
          acaoAtual.displayText == 'Sem detalhe' ? '' : acaoAtual.displayText;
      final motivo = acaoAtual.motivo;
      final draft = await _confirmarCriarTarefa(
        textoAcao.isEmpty ? 'Revisar aluno no Copiloto' : textoAcao,
        motivo,
      );
      if (draft == null) return;
      if (!mounted) return;
      final confirmar = await showFxConfirmSheet(
        context,
        title: iaCopilotoCriarTarefaConfirmTitle(),
        message: iaCopilotoCriarTarefaConfirmMessage(),
        confirmLabel: iaCopilotoCriarTarefaLabel(),
      );
      if (!confirmar || !mounted) return;
      final acao = await repo.salvarAcaoCopiloto(
        alunoId: _selectedAlunoId!,
        acao: draft.acao,
        motivo: draft.motivo,
        modo: _mode,
        source: 'COPILOT',
        recommendationId:
            'COPILOT_${_modeDisplay.toUpperCase()}_STUDENT_${_selectedAlunoId!}',
        createdFromInsight: true,
      );
      final actionKey = acao.actionKey ?? '';
      var persisted = acao.hasPersistedActionKey;
      if (persisted) {
        try {
          final abertas = await ref
              .read(dashboardRepositoryProvider)
              .getIaCommandActions(status: 'ABERTO', alunoId: _selectedAlunoId);
          persisted = abertas.any((item) => item.actionKey == actionKey);
        } catch (_) {
          persisted = false;
        }
      }
      if (!mounted) return;
      setState(() {
        _proximaAcao = acao;
        _tarefaCriada = true;
        _tarefaPersistida = persisted;
      });
      ref.invalidate(dashboardHomeProvider);
      ref.invalidate(commandCenterProvider);
      FeedbackHelper.showSuccess(
        context,
        persisted
            ? 'Tarefa salva no ${FocuxMicrocopy.commandCenter}.'
            : 'Tarefa criada. Confirme no ${FocuxMicrocopy.commandCenter}.',
      );
    } catch (_) {
      if (!mounted) return;
      FeedbackHelper.showError(context, 'Não foi possível atribuir agora.');
    }
  }

  Future<IaCopilotTaskDraft?> _confirmarCriarTarefa(
    String acaoInicial,
    String motivoInicial,
  ) {
    return showIaCopilotCreateTaskSheet(
      context,
      alunoNome: _selectedAlunoNome,
      acaoInicial: acaoInicial,
      motivoInicial: motivoInicial,
    );
  }
}
