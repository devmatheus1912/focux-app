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

  Future<void> _aplicarAcao(
    IaCopilotoApplySpec apply, {
    CopilotoRecomendacao? rec,
  }) async {
    final alunoId = _selectedAlunoId;
    if (alunoId == null || _aplicando) return;
    // Carga e medida abrem a tela de revisão; nada é aplicado daqui. Voltando
    // com resultado aplicado (pop true), a recomendação fica feita.
    if (apply.rota case final rota?) {
      final aplicou = await context.push<bool>(rota, extra: _selectedAlunoNome);
      if (aplicou == true && rec != null && mounted) {
        await _marcar(
          rec,
          CopilotoEstado.feita,
          resultado:
              rota.contains('progressao') ? 'CARGAS_AJUSTADAS' : 'MEDIDAS_REVISADAS',
        );
      }
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
        FeedbackHelper.showSuccess(context, resp.mensagem);
        if (rec != null) {
          await _marcar(
            rec,
            CopilotoEstado.feita,
            resultado: switch (spec.backendTipo) {
              'ENVIAR_PUSH' => 'MENSAGEM_ENVIADA',
              'REDUZIR_CARGA' => 'CARGAS_AJUSTADAS',
              _ => 'CONTATO_REGISTRADO',
            },
          );
        }
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

  /// "⋯" de uma recomendação: criar tarefa, marcar feita, não fazer agora
  /// ou desfazer.
  Future<void> _menuDoInsight(CopilotoRecomendacao rec) async {
    final action = await showFxGroupedActionSheet<String>(
      context,
      titulo: rec.insight.titulo,
      subtitulo: _selectedAlunoNome,
      icone: FxIcons.ia,
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: 'criar',
            rotulo: iaCopilotoCriarTarefaLabel(),
            icone: FxIcons.pranchetaFeita,
          ),
          if (rec.pendente) ...[
            const FxActionItem(
              valor: 'feita',
              rotulo: 'Marcar como feita',
              icone: FxIcons.concluido,
            ),
            const FxActionItem(
              valor: 'dispensar',
              rotulo: 'Não fazer agora',
              icone: FxIcons.fechar,
            ),
          ] else
            const FxActionItem(
              valor: 'desfazer',
              rotulo: 'Desfazer',
              icone: FxIcons.desfazer,
            ),
        ]),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'criar':
        await _atribuir(
          texto: rec.insight.recomendacao,
          motivo: rec.insight.detalhe,
          rec: rec,
        );
      case 'feita':
        await _marcar(rec, CopilotoEstado.feita, resultado: 'FEITA_A_MAO');
      case 'dispensar':
        await _marcar(rec, CopilotoEstado.dispensada);
      case 'desfazer':
        await _marcar(rec, CopilotoEstado.pendente);
    }
  }

  Future<void> _denunciar() async {
    final recs = _analise?.recomendacoes ?? const <CopilotoRecomendacao>[];
    await showDenunciarSheet(
      context,
      repo: ModeracaoRepository(ref.read(apiClientProvider)),
      tipo: DenunciaTipo.iaResposta,
      conteudo: recs
          .map((r) => '${r.insight.titulo}: ${r.insight.detalhe}')
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
