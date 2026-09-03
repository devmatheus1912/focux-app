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
    final confirmed = await showCopilotExecutarConfirmSheet(
      context,
      spec: spec,
      primary: BrandPalette.softened(Theme.of(context).colorScheme.primary),
    );
    if (!confirmed || !mounted) return;

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
        parametros: spec.parametros,
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

  Future<void> _abrirMenu({bool includeCreateTask = false}) async {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = dark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = dark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    final action = await showFxHomeSheet<String>(
      context,
      builder: (ctx) {
        return FxHomeSheetSurface(
          isDark: dark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FxHomeSheetHandle(isDark: dark),
              SizedBox(height: TokensStrip.s4),
              FxHomeSheetHeader(
                isDark: dark,
                title: 'Ações das recomendações',
                subtitle: 'Atualize, troque o aluno ou limpe este resultado.',
                leading: Icon(Icons.tune_outlined, color: primary, size: 18),
              ),
              SizedBox(height: TokensStrip.s4),
              if (includeCreateTask)
                IaCopilotMenuAction(
                  icon: Icons.assignment_turned_in_outlined,
                  title: iaCopilotoCriarTarefaLabel(),
                  subtitle: 'Salva no ${FocuxMicrocopy.commandCenter}.',
                  ink: ink,
                  mute: mute,
                  onTap: () => Navigator.of(ctx).pop('criar'),
                ),
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
        );
      },
    );

    if (!mounted || action == null) return;
    switch (action) {
      case 'criar':
        await _atribuir();
        break;
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
          _aplicando = false;
          _erro = null;
        });
        break;
    }
  }
}
