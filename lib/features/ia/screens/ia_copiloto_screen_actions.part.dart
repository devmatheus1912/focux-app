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
                      title: 'Analisar um aluno',
                      subtitle:
                          'Escolha o aluno. ${iaCopilotoCustoAnalise()}',
                      leading: Icon(
                        FxIcons.buscarPessoa,
                        color: primary,
                        size: 18,
                      ),
                    ),
                    SizedBox(height: TokensStrip.s4),
                    TextField(
                      controller: search,
                      onChanged: (value) => setModalState(() => query = value),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Buscar por nome ou objetivo',
                        prefixIcon: Icon(FxIcons.buscar, color: mute, size: 20),
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
                                  fontSize: TokensStrip.fontBodySm,
                                  height: 1.35,
                                ),
                              ),
                            )
                          else
                            ...filtered.map((a) {
                              final selected = _selectedAlunoId == a.id;
                              final objetivo = a.objetivo?.trim() ?? '';
                              return InkWell(
                                borderRadius: BorderRadius.circular(
                                  TokensStrip.rCard,
                                ),
                                onTap: () => Navigator.of(ctx).pop(a.id),
                                child: Ink(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: TokensStrip.s2,
                                    vertical: TokensStrip.s2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        selected
                                            ? primary.withValues(alpha: 0.08)
                                            : null,
                                    borderRadius: BorderRadius.circular(
                                      TokensStrip.rCard,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      AlunoAvatar(
                                        name: a.nome,
                                        variant: AlunoAvatarVariant.strip,
                                      ),
                                      const SizedBox(width: TokensStrip.s3),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              a.nome,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  FocuxHubTypography.cardTitle(
                                                    color: ink,
                                                  ),
                                            ),
                                            if (objetivo.isNotEmpty)
                                              Text(
                                                objetivo,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    FocuxHubTypography.bodyMuted(
                                                      color: mute,
                                                    ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (selected)
                                        Icon(
                                          FxIcons.check,
                                          color: primary,
                                          size: 20,
                                        ),
                                    ],
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
      _aplicando = false;
    });
  }

  /// Escolher o aluno já analisa (o custo aparece na folha).
  Future<void> _escolherEAnalisar() async {
    await _selecionarAluno();
    if (!mounted || _selectedAlunoId == null) return;
    await _gerar();
  }

  Future<void> _analisar(int alunoId, String nome) {
    setState(() {
      _selectedAlunoId = alunoId;
      _selectedAlunoNome = nome;
    });
    return _gerar();
  }

  /// Análise já feita nesta sessão volta sem gastar cota; [refazer] pede outra.
  Future<void> _gerar({bool refazer = false}) async {
    if (_selectedAlunoId == null) {
      await _selecionarAluno();
      if (_selectedAlunoId == null) return;
    }
    if (!mounted) return;
    final guardada = ref.read(
      insightsProvider(InsightsQuery(alunoId: _selectedAlunoId, mode: _mode)),
    );
    final acaoGuardada = ref.read(proximaAcaoProvider(_selectedAlunoId!));
    if (!refazer && guardada.hasValue && acaoGuardada.hasValue) {
      setState(() {
        _proximaAcao = acaoGuardada.value;
        _gerado = true;
        _erro = null;
      });
      return;
    }
    // Aceite do personal e cota, antes de qualquer dado sair para a IA.
    if (!await IaQuotaUpgrade.guardBeforeRequest(context, ref)) return;
    if (!mounted) return;

    setState(() {
      _gerando = true;
      _gerado = false;
      _erro = null;
      _geracaoMs = 0;
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
      ref.invalidate(proximaAcaoProvider(_selectedAlunoId!));
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
        });
      }
    } catch (e) {
      stopwatch.stop();
      await AnalyticsService.instance.track(
        ProductEvents.iaCopilotFailure,
        props: {
          'mode': _mode,
          // Só o tipo: a mensagem pode repetir texto do aluno.
          'error': e.runtimeType.toString(),
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
        features: ref.read(planoFeaturesProvider).value,
      );
    }
  }

  String _erroIaTexto(Object erro) {
    if (erro is IaOperationalException) {
      final refText = erro.reference == null ? '' : ' Ref: ${erro.reference}.';
      if (erro.quotaExhausted) {
        return iaCotaEsgotadaTexto(
          limite:
              ref.read(planoFeaturesProvider).value?.limiteIaMensal ??
              PlanoIaLimits.enterprise,
          agora: DateTime.now(),
        );
      }
      if (erro.retryable) {
        return '${erro.message}$refText Tente novamente em alguns instantes.';
      }
      return '${erro.message}$refText';
    }
    if (ApiError.from(erro)?.codigo == IaConsentimentos.codigoAceiteAluno) {
      final nome = _selectedAlunoNome?.split(' ').first ?? 'O aluno';
      return '$nome ainda não autorizou o assistente de IA. '
          'O pedido aparece no app dele na próxima abertura.';
    }
    return friendlyError(erro, fallback: FocuxMicrocopy.iaErroGenerico);
  }

  /// Tarefa a partir de uma recomendação: o texto é o "O que fazer" dela.
  Future<void> _atribuir({String? texto, String? motivo}) async {
    if (_selectedAlunoId == null) {
      await _selecionarAluno();
      if (_selectedAlunoId == null) return;
    }
    try {
      final repo = IaRepository(ref.read(apiClientProvider));
      final textoAcao = texto?.trim() ?? '';
      final draft = await _confirmarCriarTarefa(
        textoAcao.isEmpty ? 'Revisar aluno no Copiloto' : textoAcao,
        (motivo ?? _proximaAcao?.motivo ?? '').trim(),
      );
      if (draft == null) return;
      final acao = await repo.salvarAcaoCopiloto(
        alunoId: _selectedAlunoId!,
        acao: draft.acao,
        motivo: draft.motivo,
        modo: _mode,
        source: 'COPILOT',
        recommendationId: 'COPILOT_TREINO_STUDENT_${_selectedAlunoId!}',
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
      invalidatePersonalDashboardHome(ref);
      ref.invalidate(commandCenterProvider);
      ref.invalidate(copilotoTarefasAbertasProvider);
      FeedbackHelper.showSuccess(
        context,
        persisted
            ? S.of(context).copilotoTarefaSalva
            : S.of(context).copilotoTarefaConfirme,
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
