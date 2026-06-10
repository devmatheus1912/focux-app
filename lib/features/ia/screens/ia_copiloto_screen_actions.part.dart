part of 'ia_copiloto_screen.dart';

extension IaCopilotScreenActions on _IaCopilotoScreenState {
  Future<void> _selecionarAluno() async {
    final alunos = await ref.read(alunosProvider.future);
    if (!mounted) return;
    if (alunos.isEmpty) {
      FeedbackHelper.showError(
        context,
        'Você ainda não possui alunos cadastrados.',
      );
      return;
    }
    final search = TextEditingController();
    final escolhido = await showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
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
              child: DraggableScrollableSheet(
                initialChildSize: 0.58,
                minChildSize: 0.42,
                maxChildSize: 0.82,
                expand: false,
                builder: (ctx, scrollController) {
                  return ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: DecoratedBox(
                      decoration: fxListCardDecoration(
                        ctx,
                        accent: primary,
                        radius: 28,
                      ),
                      child: SafeArea(
                        top: false,
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                          children: [
                            Center(
                              child: Container(
                                width: 34,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: line,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: BrandPalette.soft(
                                      primary,
                                      dark: dark,
                                    ),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Icon(
                                    Icons.person_search_outlined,
                                    color: primary,
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Selecionar aluno',
                                        style: TextStyle(
                                          color: ink,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          height: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Escolha o aluno para analisar.',
                                        style: TextStyle(
                                          color: mute,
                                          fontSize: 12.2,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BrandPalette.soft(
                                      primary,
                                      dark: dark,
                                    ),
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
                              ],
                            ),
                            const SizedBox(height: TokensStrip.s4),
                            TextField(
                              controller: search,
                              onChanged:
                                  (value) => setModalState(() => query = value),
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: 'Buscar por nome ou objetivo',
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: mute,
                                  size: 20,
                                ),
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
                            if (filtered.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(TokensStrip.s4),
                                decoration: fxListCardDecoration(
                                  ctx,
                                  radius: 18,
                                ),
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
                                      duration: const Duration(
                                        milliseconds: 160,
                                      ),
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
                                                      : BrandPalette.soft(
                                                        primary,
                                                        dark: dark,
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                                : Icons.chevron_right,
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
                    ),
                  );
                },
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

    setState(() {
      _gerando = true;
      _gerado = false;
      _erro = null;
      _geracaoMs = 0;
      _tarefaCriada = false;
      _tarefaPersistida = false;
    });
    final stopwatch = Stopwatch()..start();
    try {
      await AnalyticsService.instance.track(
        ProductEvents.iaInsightRequested,
        props: {'mode': _mode, 'alunoId': _selectedAlunoId},
      );
      final query = InsightsQuery(alunoId: _selectedAlunoId, mode: _mode);
      ref.invalidate(insightsProvider(query));
      ref.invalidate(resumoSemanalProvider);
      await ref.read(insightsProvider(query).future);
      _proximaAcao = await ref.read(
        proximaAcaoProvider(_selectedAlunoId!).future,
      );
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
    return 'Não foi possível gerar agora. Tente novamente.';
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
          (acaoAtual['acao'] ??
                  acaoAtual['titulo'] ??
                  acaoAtual['mensagem'] ??
                  '')
              .toString();
      final motivo = (acaoAtual['motivo'] ?? '').toString();
      final draft = await _confirmarCriarTarefa(
        textoAcao.isEmpty ? 'Revisar aluno no Copiloto' : textoAcao,
        motivo,
      );
      if (draft == null) return;
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
      final actionKey = (acao['actionKey'] ?? '').toString();
      var persisted = actionKey.isNotEmpty;
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
            ? 'Tarefa salva no Command Center.'
            : 'Tarefa criada. Confirme no Command Center.',
      );
    } catch (_) {
      if (!mounted) return;
      FeedbackHelper.showError(context, 'Não foi possível atribuir agora.');
    }
  }

  Future<IaCopilotTaskDraft?> _confirmarCriarTarefa(
    String acaoInicial,
    String motivoInicial,
  ) async {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final brand = dark ? BrandPalette.accent(primary) : primary;
    final ink = dark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = dark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = dark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final cardBg = dark ? EagleTokens.darkCard : TokensStrip.cardBg;
    final controller = TextEditingController(text: acaoInicial);

    final result = await showModalBottomSheet<IaCopilotTaskDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: DecoratedBox(
                decoration: fxListCardDecoration(
                  ctx,
                  accent: brand,
                  radius: 28,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: line,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: brand.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.assignment_turned_in_outlined,
                              color: brand,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Criar tarefa para ${_selectedAlunoNome ?? "aluno"}?',
                                  style: TextStyle(
                                    color: ink,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Vai para o Command Center. Nada é aplicado automaticamente.',
                                  style: TextStyle(
                                    color: mute,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TokensStrip.s4),
                      Text(
                        'Ação',
                        style: TextStyle(
                          color: ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller,
                        minLines: 3,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: cardBg,
                          hintText: 'Descreva a tarefa para revisar depois',
                          hintStyle: TextStyle(color: mute),
                          contentPadding: const EdgeInsets.all(14),
                          enabledBorder: FxInputDeco.outlineBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: line),
                          ),
                          focusedBorder: FxInputDeco.outlineBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: brand, width: 1.2),
                          ),
                        ),
                        style: TextStyle(
                          color: ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          IaCopilotMetaChip(
                            label: 'Destino: Command Center',
                            icon: Icons.space_dashboard_outlined,
                            brand: brand,
                            ink: ink,
                            line: line,
                          ),
                          IaCopilotMetaChip(
                            label: 'Prioridade P1',
                            icon: Icons.flag_outlined,
                            brand: brand,
                            ink: ink,
                            line: line,
                          ),
                          IaCopilotMetaChip(
                            label: 'SLA 24h',
                            icon: Icons.timer_outlined,
                            brand: brand,
                            ink: ink,
                            line: line,
                          ),
                        ],
                      ),
                      if (motivoInicial.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          motivoInicial,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: mute,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: FxLiquidPrimaryButton(
                              label: 'Criar tarefa',
                              icon: Icons.add_task_outlined,
                              onPressed: () {
                                final text = controller.text.trim();
                                if (text.isEmpty) return;
                                Navigator.of(ctx).pop(
                                  IaCopilotTaskDraft(
                                    acao: text,
                                    motivo: motivoInicial.trim(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    controller.dispose();
    return result;
  }

  Future<void> _abrirMenu() async {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = dark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = dark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = dark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(TokensStrip.rXl),
              child: DecoratedBox(
                decoration: fxListCardDecoration(
                  ctx,
                  accent: primary,
                  radius: TokensStrip.rXl,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 34,
                        height: 4,
                        decoration: BoxDecoration(
                          color: line,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: BrandPalette.soft(primary, dark: dark),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              Icons.tune_outlined,
                              color: primary,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ações das recomendações',
                                  style: TextStyle(
                                    color: ink,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Atualize, troque o aluno ou limpe este resultado.',
                                  style: TextStyle(
                                    color: mute,
                                    fontSize: 12.2,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TokensStrip.s4),
                      IaCopilotMenuAction(
                        icon: Icons.person_search_outlined,
                        title: 'Trocar aluno',
                        subtitle: 'Gera novas recomendações para outro aluno.',
                        ink: ink,
                        mute: mute,
                        onTap: () => Navigator.of(ctx).pop('trocar'),
                      ),
                      IaCopilotMenuAction(
                        icon: Icons.refresh_rounded,
                        title: 'Atualizar insights',
                        subtitle: 'Recalcula as recomendações para este aluno.',
                        ink: ink,
                        mute: mute,
                        onTap: () => Navigator.of(ctx).pop('atualizar'),
                      ),
                      IaCopilotMenuAction(
                        icon: Icons.cleaning_services_outlined,
                        title: 'Limpar resultado',
                        subtitle: 'Volta para o estado inicial do Copiloto.',
                        ink: ink,
                        mute: mute,
                        onTap: () => Navigator.of(ctx).pop('limpar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    switch (action) {
      case 'trocar':
        await _selecionarAluno();
        break;
      case 'atualizar':
        await _gerar();
        break;
      case 'limpar':
        setState(() {
          _gerado = false;
          _proximaAcao = null;
          _tarefaCriada = false;
          _tarefaPersistida = false;
          _erro = null;
        });
        break;
    }
  }
}
