part of 'ia_copiloto_screen.dart';

extension IaCopilotScreenApply on _IaCopilotoScreenState {
  CopilotExecutarAcaoSpec _toExecutarSpec(IaCopilotoApplySpec spec) {
    final backendTipo = spec.backendTipo!;
    return switch (backendTipo) {
      'REDUZIR_CARGA' => CopilotExecutarAcaoSpec(
        backendTipo: backendTipo,
        label: spec.label,
        icon: FxIcons.treino,
        executingLabel: 'Aplicando…',
        executingSemantics: 'Aplicando ajuste de carga',
      ),
      'ENVIAR_PUSH' => CopilotExecutarAcaoSpec(
        backendTipo: backendTipo,
        label: spec.label,
        icon: FxIcons.notificacaoTocando,
        executingLabel: 'Enviando…',
        executingSemantics: 'Enviando notificação ao aluno',
        parametros: spec.parametros,
      ),
      _ => CopilotExecutarAcaoSpec(
        backendTipo: backendTipo,
        label: spec.label,
        icon: FxIcons.alerta,
        executingLabel: 'Registrando…',
        executingSemantics: 'Registrando contato prioritário',
      ),
    };
  }

  Future<void> _aplicarAcao(IaCopilotoApplySpec apply) async {
    final alunoId = _selectedAlunoId;
    if (alunoId == null || _aplicando) return;
    // Carga e medida abrem a tela de revisão; nada é aplicado daqui.
    if (apply.rota case final rota?) {
      context.push(rota, extra: _selectedAlunoNome);
      return;
    }

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
        if (spec.backendTipo == 'ENVIAR_PUSH') {
          setState(() => _mensagemEnviada = true);
        }
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

  /// "⋯" de uma recomendação: criar tarefa com o "O que fazer" dela.
  Future<void> _menuDoInsight(IaCopilotInsight insight) async {
    final action = await showFxGroupedActionSheet<String>(
      context,
      titulo: insight.titulo,
      subtitulo: _selectedAlunoNome,
      icone: FxIcons.ia,
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: 'criar',
            rotulo: iaCopilotoCriarTarefaLabel(),
            icone: FxIcons.pranchetaFeita,
          ),
        ]),
      ],
    );
    if (!mounted || action != 'criar') return;
    await _atribuir(texto: insight.recomendacao, motivo: insight.detalhe);
  }

  Future<void> _denunciar() async {
    final insights =
        ref
            .read(
              insightsProvider(
                InsightsQuery(alunoId: _selectedAlunoId, mode: _mode),
              ),
            )
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
      icone: FxIcons.filtros,
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: 'progressao',
            rotulo: s.copilotoProgressaoCarga,
            icone: FxIcons.subindo,
          ),
          FxActionItem(
            valor: 'refazer',
            rotulo: s.copilotoRefazer,
            descricao: iaCopilotoCustoAnalise(),
            icone: FxIcons.atualizar,
          ),
          FxActionItem(
            valor: 'denunciar',
            rotulo: S.of(context).moderacaoDenunciarIa,
            icone: FxIcons.meta,
          ),
        ]),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'progressao':
        _abrirProgressao();
      case 'refazer':
        await _gerar(refazer: true);
      case 'denunciar':
        await _denunciar();
    }
  }
}
