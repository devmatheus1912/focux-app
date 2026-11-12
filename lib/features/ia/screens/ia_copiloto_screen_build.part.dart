part of 'ia_copiloto_screen.dart';

/// Rótulo do que foi feito numa recomendação ("Mensagem enviada").
String copilotoResultadoLabel(String? resultado) => switch (resultado) {
  'MENSAGEM_ENVIADA' => 'Mensagem enviada',
  'CHECKIN_PEDIDO' => 'Check-in pedido',
  'CONTATO_REGISTRADO' => 'Contato registrado',
  'TAREFA_CRIADA' => 'Tarefa criada',
  'CARGAS_AJUSTADAS' => 'Cargas ajustadas',
  'MEDIDAS_REVISADAS' => 'Medidas revisadas',
  _ => 'Feito à mão',
};

/// "Hoje · 2 de 3 feitas", "Ontem · Concluída", "seg · 1 pendente".
String copilotoResumoLinha(CopilotoAnaliseResumo r, DateTime agora) {
  final criada = r.criadaEm?.toLocal();
  final dia =
      criada == null
          ? ''
          : DateUtils.isSameDay(criada, agora)
          ? 'Hoje'
          : DateUtils.isSameDay(criada, agora.subtract(const Duration(days: 1)))
          ? 'Ontem'
          : dataCurta(criada);
  final estado =
      r.concluidaEm != null || r.pendentes == 0
          ? 'Concluída'
          : r.feitas + r.dispensadas == 0
          ? (r.pendentes == 1 ? '1 pendente' : '${r.pendentes} pendentes')
          : '${r.feitas + r.dispensadas} de ${r.total} feitas';
  return dia.isEmpty ? estado : '$dia · $estado';
}

extension IaCopilotoScreenBuild on _IaCopilotoScreenState {
  /// Três portas da IA Focux, sem cardápio: conversar, analisar, cargas.
  Widget _atalhos({required bool cotaEsgotada}) => Padding(
    padding: const EdgeInsets.fromLTRB(
      FxSettingsLayout.pageInset,
      0,
      FxSettingsLayout.pageInset,
      TokensStrip.s4,
    ),
    child: Wrap(
      spacing: TokensStrip.s2,
      runSpacing: TokensStrip.s2,
      children: [
        FxTonalButton(
          label: 'Conversar',
          icon: FxIcons.chat,
          compact: true,
          onPressed: () => context.push('/ia/chat'),
        ),
        FxTonalButton(
          label: 'Analisar um aluno',
          icon: FxIcons.ia,
          compact: true,
          onPressed: cotaEsgotada ? null : _escolherEAnalisar,
        ),
        FxTonalButton(
          label: 'Ajustar cargas',
          icon: FxIcons.subindo,
          compact: true,
          onPressed: cotaEsgotada ? null : _ajustarCargasDeUmAluno,
        ),
      ],
    ),
  );

  /// Grupos da abertura: análises recentes e o que a IA faz.
  Widget _abertura({
    required bool cotaEsgotada,
    required List<CopilotoAnaliseResumo> recentes,
  }) {
    final chrome = ShellChrome.of(context);
    final cargas = ref.watch(cargasParaRevisarProvider).value ?? 0;
    final conversas = ref.watch(iaConversasProvider).value ?? const [];
    final agora = DateTime.now();
    final ordenadas = [...recentes]..sort((a, b) {
      final pa = a.concluidaEm == null && a.pendentes > 0 ? 0 : 1;
      final pb = b.concluidaEm == null && b.pendentes > 0 ? 0 : 1;
      if (pa != pb) return pa - pb;
      return (b.criadaEm ?? agora).compareTo(a.criadaEm ?? agora);
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        TokensStrip.s4,
        FxSettingsLayout.pageInset,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ordenadas.isNotEmpty) ...[
            Text(
              'Análises recentes',
              style: FxSettingsLayout.sectionHeader(color: chrome.mute),
            ),
            const SizedBox(height: FxSettingsLayout.headerToGroup),
            FxSettingsGroup(
              children: [
                for (final (i, r) in ordenadas.indexed)
                  FxSettingsTile(
                    icon: FxIcons.ia,
                    label: satelliteFirstName(r.alunoNome),
                    subtitle: copilotoResumoLinha(r, agora),
                    value: '',
                    showDivider: i < ordenadas.length - 1,
                    onTap:
                        () => _abrirAnaliseGuardada(r.id, r.alunoNome ?? ''),
                  ),
              ],
            ),
            const SizedBox(height: FxSettingsLayout.groupGap),
          ],
          if (cargas > 0) ...[
            FxSettingsGroup(
              children: [
                FxSettingsTile(
                  icon: FxIcons.checklist,
                  label: 'Cargas para revisar',
                  subtitle:
                      cargas == 1
                          ? '1 sugestão esperando sua revisão.'
                          : '$cargas sugestões esperando sua revisão.',
                  value: '',
                  showDivider: false,
                  onTap: () => context.push('/ia/progressao/aceitar'),
                ),
              ],
            ),
            const SizedBox(height: FxSettingsLayout.groupGap),
          ],
          if (conversas.isNotEmpty) ...[
            Text(
              'Conversas recentes',
              style: FxSettingsLayout.sectionHeader(color: chrome.mute),
            ),
            const SizedBox(height: FxSettingsLayout.headerToGroup),
            FxSettingsGroup(
              children: [
                for (final (i, c) in conversas.take(5).indexed)
                  FxSettingsTile(
                    icon: FxIcons.chat,
                    label: c.titulo,
                    subtitle: [
                      if (c.alunoNome != null) 'Sobre ${c.alunoNome}',
                      dataCurta(c.atualizadaEm),
                    ].join(' · '),
                    value: '',
                    showDivider: i < conversas.take(5).length - 1,
                    onTap: () => context.push('/ia/chat?c=${c.id}'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Resultado: o motivo, as recomendações com estado e o aviso de segurança.
  Widget _resultado({
    required Color brand,
    required Color mute,
    required Color ink,
  }) {
    final analise = _analise;
    final motivo = (_proximaAcao?.motivo ?? analise?.motivo ?? '').trim();
    final criada = analise?.criadaEm?.toLocal();
    final deOutroDia =
        criada != null && !DateUtils.isSameDay(criada, DateTime.now());
    final recs = analise?.recomendacoes ?? const <CopilotoRecomendacao>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        0,
        FxSettingsLayout.pageInset,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (deOutroDia) ...[
            Text(
              'Análise de ${dataCurta(criada)}',
              style: FocuxHubTypography.chip(mute),
            ),
            const SizedBox(height: TokensStrip.s2),
          ],
          if (motivo.isNotEmpty) ...[
            Text(motivo, style: FocuxHubTypography.body(color: ink)),
            const SizedBox(height: TokensStrip.s3),
          ],
          if (recs.isEmpty)
            FxEmptyState(
              icon: FxIcons.ia,
              title: 'Sem recomendações no momento',
              subtitle:
                  'Adicione mais treinos e check-ins para que a IA gere recomendações personalizadas.',
              action: FxEmptyAction(
                label: 'Gerar novamente',
                onTap: () => _gerar(refazer: true),
              ),
            )
          else ...[
            if (recs.any((r) => !r.insight.ready)) ...[
              Text(
                'A IA respondeu fora do formato ideal. Mantivemos as recomendações para revisão manual.',
                style: FocuxHubTypography.bodyMuted(color: mute),
              ),
              const SizedBox(height: TokensStrip.s3),
            ],
            for (final (i, rec) in recs.indexed)
              IaCopilotInsightItem(
                key: ValueKey('rec-${rec.id}-${rec.estado.name}'),
                index: i,
                insight: rec.insight,
                brand: brand,
                mute: mute,
                acaoLabel: _acaoDoInsight(rec.insight)?.label,
                onAcao: switch (_acaoDoInsight(rec.insight)) {
                  final acao? when rec.pendente =>
                    () => _aplicarAcao(acao, rec: rec),
                  _ => null,
                },
                onMais: () => _menuDoInsight(rec),
                feitoLabel:
                    rec.estado == CopilotoEstado.feita
                        ? copilotoResultadoLabel(rec.resultado)
                        : null,
                dispensada: rec.estado == CopilotoEstado.dispensada,
              ),
            const SizedBox(height: TokensStrip.s2),
            const IaSafetyDisclaimer(compact: true),
          ],
        ],
      ),
    );
  }

  Widget buildIaCopilotoBody(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final dark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final brand = BrandPalette.softened(primary);
    final wash = primary.withValues(alpha: dark ? 0.16 : 0.10);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final homeAsync = ref.watch(iaCopilotoHomeProvider);
    final home = homeAsync.value;
    final tarefas = ref.watch(copilotoTarefasAbertasProvider).value;
    final recentes =
        ref.watch(copilotoAnalisesRecentesProvider).value ??
        const <CopilotoAnaliseResumo>[];
    final planoFromHome = home?.planoFeatures;
    if (planoFromHome != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          ref.read(planoFeaturesProvider.notifier).seedFromHome(planoFromHome);
        } on StateError catch (e) {
          // QA route cycling can dispose the element before this frame runs.
          if (!e.message.contains('ref')) rethrow;
        }
      });
    }
    final cotaEsgotada = planoFromHome?.iaQuotaEsgotada ?? false;

    if (home != null && !_viewTracked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _viewTracked) return;
        _viewTracked = true;
        AnalyticsService.instance.track(
          ProductEvents.iaCopilotoViewed,
          props: {'mode': _mode},
        );
        if (!_ttvTracked) {
          _ttvTracked = true;
          AnalyticsService.instance.track(
            ProductEvents.iaCopilotoTtv,
            props: {
              'ms': DateTime.now().difference(_openedAt).inMilliseconds,
              'mode': _mode,
            },
          );
        }
      });
    }

    // Aluno com análise de hoje sai de "Quem precisa de você"; com análise
    // de outro dia, o "Analisar" abre a guardada.
    final hoje = DateTime.now();
    final analisadosHoje = {
      for (final r in recentes)
        if (r.criadaEm != null && DateUtils.isSameDay(r.criadaEm!.toLocal(), hoje))
          r.alunoId,
    };
    final guardadas = {for (final r in recentes) r.alunoId: r};
    final proxima = _proximaComAcao;

    return fxScreenA11yScope(
      label: 'IA Focux',
      child: PopScope(
        canPop: !_gerado,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _voltarAoInicio();
        },
        child: FeatureGate(
          featureName: 'IA Focux',
          requiredPlan: SubscriptionPlan.PRO,
          capability: 'iaCopiloto',
          child: FxShellScaffold(
            useMesh: true,
            constrainWidth: false,
            safeArea: false,
            appBar: FxShellAppBar(
              title: 'IA Focux',
              subtitle: _gerado ? _selectedAlunoNome : null,
              // Voltar sempre: sem análise aberta, volta para a Hoje (o
              // Copiloto deixou de ser aba e travava sem seta).
              onBack:
                  _gerado
                      ? _voltarAoInicio
                      : () => safePopOrGo(context, '/dashboard/personal'),
              actions: [
                if (_gerado)
                  IconButton(
                    tooltip: S.of(context).copilotoMenuTitulo,
                    icon: Icon(FxIcons.mais, color: brand),
                    onPressed: _abrirMenu,
                  ),
                FxHelpIconButton(
                  tooltip: 'Como usar a IA Focux',
                  onTap: () {
                    AnalyticsService.instance.track(
                      ProductEvents.iaCopilotoHelpOpened,
                    );
                    showIaCopilotoHelpSheet(context);
                  },
                ),
              ],
            ),
            bottomNavigationBar:
                _gerado && _analise != null
                    ? IaCopilotResultActionBar(
                      onConcluir: _concluir,
                      proximaLabel: proxima?.$2.label,
                      onProxima:
                          proxima == null
                              ? null
                              : () => _aplicarAcao(proxima.$2, rec: proxima.$1),
                    )
                    : null,
            body: SafeArea(
              bottom: false,
              child: FxContentWidthLimiter(
                child: SingleChildScrollView(
                  clipBehavior: Clip.hardEdge,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: TokensStrip.s3),
                      if (!_gerado) ...[
                        if (planoFromHome case final plano?
                            when (plano.limiteIaMensal ?? 0) > 0)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              FxSettingsLayout.pageInset,
                              0,
                              FxSettingsLayout.pageInset,
                              TokensStrip.s4,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                IaUsoLinha(
                                  usado: plano.iaUsadaMes,
                                  limite: plano.limiteIaMensal!,
                                ),
                                if (cotaEsgotada) ...[
                                  const SizedBox(height: TokensStrip.s3),
                                  _cotaEsgotadaCard(plano),
                                ],
                              ],
                            ),
                          ),
                        if (homeAsync.hasError)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              FxSettingsLayout.pageInset,
                              0,
                              FxSettingsLayout.pageInset,
                              12,
                            ),
                            child: FxErrorState(
                              chromeOnDark: dark,
                              primary: brand,
                              message: friendlyError(
                                homeAsync.error!,
                                fallback:
                                    'Não foi possível carregar alunos e cota.',
                              ),
                              onRetry:
                                  () => ref.invalidate(iaCopilotoHomeProvider),
                            ),
                          )
                        else if (!_gerando) ...[
                          _atalhos(cotaEsgotada: cotaEsgotada),
                          Semantics(
                            hint: iaCopilotoComoCalculamos,
                            child: CopilotoCardView(
                              prioridades: [
                                for (final p in copilotoPrioridades(
                                  tarefas?.itens ?? const [],
                                  {
                                    for (final a
                                        in home?.alunosResumo ??
                                            const <IaCopilotoAlunoResumo>[])
                                      a.id: a.nome,
                                  },
                                ))
                                  if (!analisadosHoje.contains(p.alunoId)) p,
                              ],
                              tarefasAbertas: tarefas?.totalItens ?? 0,
                              podeAnalisar: !cotaEsgotada,
                              rotuloAnalisar:
                                  (alunoId) =>
                                      guardadas.containsKey(alunoId)
                                          ? 'Ver análise'
                                          : null,
                              onAnalisar: (alunoId, nome) {
                                final guardada = guardadas[alunoId];
                                if (guardada != null) {
                                  _abrirAnaliseGuardada(guardada.id, nome);
                                } else {
                                  _analisar(alunoId, nome);
                                }
                              },
                              onEscolherAluno: _escolherEAnalisar,
                              onVerTarefas:
                                  () => context.push(
                                    '/dashboard/command-center/copiloto',
                                  ),
                            ),
                          ),
                          _abertura(
                            cotaEsgotada: cotaEsgotada,
                            recentes: recentes,
                          ),
                        ],
                      ],
                      if (_gerando)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            FxSettingsLayout.pageInset,
                            0,
                            FxSettingsLayout.pageInset,
                            18,
                          ),
                          child: IaCopilotGenerationStatus(
                            gerando: _gerando,
                            gerado: false,
                            elapsedMs: _geracaoMs,
                            ink: ink,
                            mute: mute,
                            wash: wash,
                          ),
                        ),
                      if (_erro != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            TokensStrip.s4,
                            0,
                            16,
                            16,
                          ),
                          child: FxErrorState(
                            chromeOnDark: dark,
                            primary: brand,
                            message: _erroIaTexto(_erro!),
                            icon: FxIcons.erro,
                            onRetry:
                                _erroSugereUpgrade(_erro!)
                                    ? _mostrarUpgradePorErro
                                    : () => _gerar(refazer: true),
                            retryLabel:
                                _erroSugereUpgrade(_erro!)
                                    ? 'Fazer upgrade'
                                    : null,
                            retryIcon:
                                _erroSugereUpgrade(_erro!)
                                    ? FxIcons.premium
                                    : FxIcons.atualizar,
                          ),
                        )
                      else if (_gerado)
                        _resultado(brand: brand, mute: mute, ink: ink),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
