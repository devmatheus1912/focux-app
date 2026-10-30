part of 'ia_copiloto_screen.dart';

extension IaCopilotScreenApply on _IaCopilotoScreenState {
  CopilotExecutarAcaoSpec _toExecutarSpec(IaCopilotoApplySpec spec) {
    return switch (spec.backendTipo) {
      'REDUZIR_CARGA' => CopilotExecutarAcaoSpec(
        backendTipo: spec.backendTipo,
        label: spec.label,
        icon: Icons.fitness_center_rounded,
        executingLabel: 'Aplicando…',
        executingSemantics: 'Aplicando ajuste de carga',
      ),
      'ENVIAR_PUSH' => CopilotExecutarAcaoSpec(
        backendTipo: spec.backendTipo,
        label: spec.label,
        icon: Icons.notifications_active_outlined,
        executingLabel: 'Enviando…',
        executingSemantics: 'Enviando notificação ao aluno',
        parametros: spec.parametros,
      ),
      _ => CopilotExecutarAcaoSpec(
        backendTipo: spec.backendTipo,
        label: spec.label,
        icon: Icons.warning_amber_rounded,
        executingLabel: 'Registrando…',
        executingSemantics: 'Registrando contato prioritário',
      ),
    };
  }

  Future<void> _aplicarAcao() async {
    final alunoId = _selectedAlunoId;
    final apply = _applySpec;
    if (alunoId == null || apply == null || _aplicando) return;

    final spec = _toExecutarSpec(apply);
    var parametros = spec.parametros;
    if (spec.backendTipo == 'ENVIAR_PUSH') {
      parametros = await showIaCopilotoMensagemSheet(
        context,
        mensagem: parametros ?? '',
      );
      if (parametros == null || !mounted) return;
    } else {
      final confirmed = await showCopilotExecutarConfirmSheet(
        context,
        spec: spec,
        primary: BrandPalette.softened(Theme.of(context).colorScheme.primary),
      );
      if (!confirmed || !mounted) return;
    }

    setState(() => _aplicando = true);
    await AnalyticsService.instance.track(
      ProductEvents.aluno360CopilotExecutarAcao,
      props: {
        'aluno_id': alunoId,
        'tipo_acao': spec.backendTipo,
        'source': 'copiloto',
      },
    );
    try {
      final resp = await IaRepository(
        ref.read(apiClientProvider),
      ).executarAcaoCopiloto(
        alunoId: alunoId,
        tipoAcao: spec.backendTipo,
        parametros: parametros,
      );
      if (!mounted) return;
      if (resp.ok) {
        FeedbackHelper.showSuccess(context, resp.mensagem);
      } else {
        FeedbackHelper.showError(context, resp.mensagem);
      }
      ref.invalidate(iaCopilotoHomeProvider);
      ref.invalidate(proximaAcaoProvider(alunoId));
    } catch (e) {
      if (!mounted) return;
      await IaQuotaUpgrade.handleError(context, ref, e);
      if (!mounted) return;
      if (e is IaOperationalException &&
          IaQuotaUpgrade.shouldPromptUpgrade(e)) {
        return;
      }
      FeedbackHelper.showError(
        context,
        friendlyError(e, fallback: 'Não foi possível aplicar agora.'),
      );
    } finally {
      if (mounted) setState(() => _aplicando = false);
    }
  }

  void _abrirProgressao() {
    final alunoId = _selectedAlunoId;
    if (alunoId == null) return;
    context.push('/alunos/$alunoId/ia/progressao');
  }

  Future<void> _denunciar() async {
    final insights = ref
        .read(insightsProvider(InsightsQuery(alunoId: _selectedAlunoId, mode: _mode)))
        .value;
    await showDenunciarSheet(
      context,
      repo: ModeracaoRepository(ref.read(apiClientProvider)),
      tipo: DenunciaTipo.iaResposta,
      conteudo: (insights ?? const [])
          .map((i) => '${i.titulo}: ${i.detalhe}')
          .join('\n'),
    );
  }

  Future<void> _abrirMenu() async {
    final s = S.of(context);
    final action = await showFxGroupedActionSheet<String>(
      context,
      titulo: s.copilotoMenuTitulo,
      subtitulo: _selectedAlunoNome,
      icone: Icons.tune_outlined,
      grupos: [
        FxActionGroup<String>(null, [
          if (_applySpec != null)
            FxActionItem(
              valor: 'criar',
              rotulo: iaCopilotoCriarTarefaLabel(),
              icone: Icons.assignment_turned_in_outlined,
            ),
          FxActionItem(
            valor: 'progressao',
            rotulo: s.copilotoProgressaoCarga,
            icone: Icons.trending_up_rounded,
          ),
          FxActionItem(
            valor: 'refazer',
            rotulo: s.copilotoRefazer,
            icone: Icons.refresh_rounded,
          ),
          FxActionItem(
            valor: 'denunciar',
            rotulo: S.of(context).moderacaoDenunciarIa,
            icone: Icons.flag_outlined,
          ),
        ]),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'criar':
        await _atribuir();
      case 'progressao':
        _abrirProgressao();
      case 'refazer':
        await _gerar(refazer: true);
      case 'denunciar':
        await _denunciar();
    }
  }

  /// Volta à abertura para analisar outro aluno.
  Future<void> _trocarAluno() async {
    setState(() {
      _gerado = false;
      _proximaAcao = null;
      _aplicando = false;
      _erro = null;
    });
    await _selecionarAluno();
    if (mounted && _selectedAlunoId != null) await _gerar();
  }
}
