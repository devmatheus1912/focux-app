part of 'aluno_detail_screen.dart';

class _Aluno360CopilotCard extends ConsumerWidget {
  final Aluno aluno;
  final int alunoId;
  final AsyncValue<AlunoAutonomiaResumo> resumoAsync;
  final ProximaAcaoResumo? proximaAcao360;
  final bool hasOpenCopilotTask360;
  final bool isDark;
  final bool showFocusToggle;

  const _Aluno360CopilotCard({
    required this.aluno,
    required this.alunoId,
    required this.resumoAsync,
    required this.proximaAcao360,
    required this.hasOpenCopilotTask360,
    required this.isDark,
    this.showFocusToggle = false,
  });

  Future<void> _openProfileGap(
    BuildContext context,
    Aluno aluno,
    CopilotProfileGap gap,
  ) async {
    if (gap.route == 'measures') {
      await context.push('/alunos/${aluno.id}/evolucao', extra: aluno.nome);
      return;
    }
    if (gap.route == 'equipment') {
      await context.push('/alunos/${aluno.id}/equipamentos');
      return;
    }
    await context.push('/alunos/${aluno.id}/editar', extra: aluno);
  }

  Future<void> _completeProfile(BuildContext context, Aluno aluno) async {
    final gaps = copilotProfileGapsForCard(aluno);
    if (gaps.isEmpty) return;
    if (gaps.length == 1) {
      await _openProfileGap(context, aluno, gaps.first);
      return;
    }
    await _showProfileGapSheet(context, aluno, gaps);
  }

  Future<void> _showProfileGapSheet(
    BuildContext context,
    Aluno aluno,
    List<CopilotProfileGap> gaps,
  ) async {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);

    Future<void> go(CopilotProfileGap gap, BuildContext sheetContext) async {
      Navigator.of(sheetContext).pop();
      await _openProfileGap(context, aluno, gap);
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                4,
                16,
                16 + MediaQuery.of(sheetContext).padding.bottom,
              ),
              child: ShellSurface(
                radius: TokensStrip.rCard,
                accent: primary,
                padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 8, 20, 20),
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.fact_check_outlined,
                          color: primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Completar perfil',
                              style: TextStyle(
                                color: ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              gaps.isEmpty
                                  ? 'Perfil pronto para decisões da IA.'
                                  : '${gaps.length} lacuna(s) afetam a prescrição.',
                              style: TextStyle(color: mute, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  if (gaps.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: EagleTokens.good.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: EagleTokens.good.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Text('Nada pendente no perfil agora.'),
                    )
                  else
                    ...gaps.map(
                      (gap) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => go(gap, sheetContext),
                          child: Container(
                            padding: const EdgeInsets.all(13),
                            decoration: fxListCardDecoration(
                              sheetContext,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: BrandPalette.soft(
                                      primary,
                                      dark: isDark,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    gap.icon,
                                    color: primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        gap.title,
                                        style: TextStyle(
                                          color: ink,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        gap.detail,
                                        style: TextStyle(
                                          color: mute,
                                          fontSize: 12,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: mute),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (gaps.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Para ajustes gerais, use Editar nas ações rápidas.',
                        style: TextStyle(color: mute, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            ),
          ),
    );
  }

  void _prepararMensagem(
    BuildContext context,
    String acao, {
    String? backendMessage,
    String? outreachMessage,
  }) {
    unawaited(
      AnalyticsService.instance.track(
        ProductEvents.aluno360OutreachPrepared,
        props: {'aluno_id': aluno.id},
      ),
    );
    showAlunoOutreachMessageSheet(
      context,
      alunoId: aluno.id,
      alunoNome: aluno.nome,
      message:
          outreachMessage ??
          resolveOutreachMessage(
            aluno,
            acao: acao,
            backendMessage: backendMessage,
          ),
      title: 'Mensagem sugerida',
      subtitle: 'Copiloto · revise antes de enviar.',
      icon: Icons.auto_awesome_rounded,
    );
  }

  Future<bool> _criarTarefaCopiloto(
    BuildContext context,
    WidgetRef ref,
    String acao,
  ) async {
    try {
      final existing = findOpenCopilotTask(
        await ref
            .read(dashboardRepositoryProvider)
            .getIaCommandActions(status: 'ABERTO', alunoId: aluno.id),
      );
      if (existing != null) {
        ref.invalidate(alunoOpenIaActionsProvider(aluno.id));
        if (context.mounted) {
          FeedbackHelper.showSnackBar(
            context,
            SnackBar(
              content: const Text('Tarefa já aberta no Command Center.'),
              action: SnackBarAction(
                label: 'Ver',
                onPressed:
                    () => context.push('/dashboard/command-center/copiloto'),
              ),
            ),
          );
        }
        return true;
      }

      final saved = await IaRepository(
        ref.read(apiClientProvider),
      ).salvarAcaoCopiloto(
        alunoId: aluno.id,
        acao: acao,
        motivo:
            'Aluno 360: ação prescrita a partir de perfil, autonomia e risco.',
        modo: 'ALUNO_360',
        source: 'ALUNO_360',
        recommendationId:
            'ALUNO_360_${aluno.id}_${DateTime.now().millisecondsSinceEpoch}',
        createdFromInsight: true,
      );
      final actionKey = (saved['actionKey'] ?? '').toString();
      var persisted = actionKey.isNotEmpty;
      if (persisted) {
        final abertas = await ref
            .read(dashboardRepositoryProvider)
            .getIaCommandActions(status: 'ABERTO', alunoId: aluno.id);
        persisted = abertas.any((item) => item.actionKey == actionKey);
      }
      ref.invalidate(dashboardHomeProvider);
      ref.invalidate(commandCenterProvider);
      ref.invalidate(alunoOpenIaActionsProvider(aluno.id));
      if (context.mounted) {
        FeedbackHelper.showSnackBar(
          context,
          SnackBar(
            content: Text(
              persisted
                  ? 'Tarefa criada no Command Center.'
                  : 'Servidor aceitou, mas a tarefa ainda não apareceu.',
            ),
            action:
                persisted
                    ? SnackBarAction(
                      label: 'Ver',
                      onPressed:
                          () => context.push(
                            '/dashboard/command-center/copiloto',
                          ),
                    )
                    : null,
          ),
        );
      }
      return persisted;
    } catch (e) {
      if (context.mounted) {
        FeedbackHelper.showSnackBar(
          context,
          SnackBar(content: Text('Não foi possível criar tarefa: ${friendlyError(e)}')),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final line = ShellChrome.of(context).line;
    final forceIa = ref.watch(alunoCopilotoForceIaProvider(aluno.id));
    final iaAsync =
        forceIa ? ref.watch(alunoCopilotoActionProvider(aluno.id)) : null;
    final openActionsAsync = ref.watch(alunoOpenIaActionsProvider(aluno.id));
    final openTask = findOpenCopilotTask(openActionsAsync.valueOrNull ?? const []);
    final hasOpenTask = openTask != null || hasOpenCopilotTask360;
    final operacao =
        ref.watch(aluno360OperacaoProvider(aluno.id)) ??
        resolveAluno360OperacaoSnapshot(
          aluno: aluno,
          proximaAcao360: proximaAcao360,
          forceIa: forceIa,
          iaAsync: iaAsync,
          hasOpenTask: hasOpenTask,
          followUpDue: isAlunoFollowUpDue(aluno),
          wearableRelevant: alunoTemHistoricoWearable(
            ref.watch(alunoRecoveryProvider(aluno.id)).valueOrNull,
          ),
        );
    final iaLoading =
        forceIa && iaAsync != null && iaAsync.isLoading && !iaAsync.hasValue;
    final resumo = resumoAsync.valueOrNull;
    final profileCompletion = copilotProfileCompletion(aluno);
    final signals = resolveCopilotSignals(
      aluno: aluno,
      resumo: resumo,
      primary: primary,
    );
    final fallback = copilotFallbackAction(aluno, resumo);
    final seed360 =
        proximaAcao360 != null
            ? copilotActionFrom360(proximaAcao360!)
            : null;
    final stickyAction = operacao.stickyAction;
    final effectiveProxima = operacao.effectiveProxima;
    final hideCopilotChat = operacao.hideCopilotChatRow;
    final showCopilotPrescription = shouldShowCopilotPrescriptionBlock(
      forceIa: forceIa,
      sticky: stickyAction,
      aluno: aluno,
      proximaAcaoRaw: proximaAcao360?.acao,
    );
    final hideCopilotPrimary =
        operacao.hideCopilotTaskRow ||
        shouldHideCopilotPrimaryCtaWhenMatchesSticky(
          sticky: stickyAction,
          aluno: aluno,
          proximaAcaoRaw: proximaAcao360?.acao,
        );
    final resolvedAcao = resolveCopilotAcao(
      seed360: seed360,
      forceIa: forceIa,
      iaAsync: iaAsync,
      fallback: fallback,
    );
    final showPrepareInPrescription = operacao.showPrepareMessage;
    final cardPadding = hasOpenTask ? 10.0 : 14.0;
    final wearableRelevant =
        effectiveProxima?.wearableRelevant ??
        alunoTemHistoricoWearable(
          ref.watch(alunoRecoveryProvider(aluno.id)).valueOrNull,
        );

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: fxListCardDecoration(
        context,
        accent: primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BrandPalette.soft(primary, dark: isDark),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.hub_outlined, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copilotCardTitle(
                        contactPriority: operacao.contactPriority,
                      ),
                      style: TextStyle(
                        color: ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            copilotCardSubtitle(
                              forceIa: forceIa,
                              iaAsync: iaAsync,
                              resumoLoading:
                                  resumoAsync.isLoading && !resumoAsync.hasValue,
                            ),
                            style: TextStyle(
                              color: mute,
                              fontSize: 12.5,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (shouldShowCopilotContactBadge(
                          contactPriority: operacao.contactPriority,
                          sticky: stickyAction,
                        )) ...[
                          const SizedBox(width: 8),
                          _ContactPriorityBadge(primary: primary),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (showFocusToggle)
                _OperacaoFocusModeToggle(
                  alunoId: alunoId,
                  primary: primary,
                  iconOnly: true,
                ),
              _CopilotIaRefreshButton(
                alunoId: aluno.id,
                primary: primary,
              ),
            ],
          ),
          if (iaLoading) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: primary.withValues(alpha: 0.12),
                color: primary,
              ),
            ),
          ],
          if (!hasOpenTask) ...[
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.15,
              children:
                  signals
                      .map((signal) => _Aluno360SignalTile(signal: signal))
                      .toList(),
            ),
          ],
          if (!hasOpenTask) const SizedBox(height: 10),
          if (shouldShowCopilotProfileGapsButton(
            aluno,
            profileCompletion,
            sticky: stickyAction,
          )) ...[
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () => _completeProfile(context, aluno),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: Text(
                  copilotProfileGapsButtonLabel(aluno),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary.withValues(alpha: 0.28)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (showCopilotPrescription) ...[
            Aluno360CopilotPrescriptionBody(
              aluno: aluno,
              primary: primary,
              fallback: fallback,
              seed360: seed360,
              forceIa: forceIa,
              iaAsync: iaAsync,
              resumoLoading: resumoAsync.isLoading && !resumoAsync.hasValue,
              preferContactPriority: operacao.contactPriority,
              wearableRelevant: wearableRelevant,
              contactPriority: operacao.contactPriority,
              onPrepareMessage:
                  showPrepareInPrescription
                      ? () => _prepararMensagem(
                        context,
                        resolvedAcao,
                        backendMessage: effectiveProxima?.mensagemSugerida,
                        outreachMessage: operacao.outreachMessage,
                      )
                      : null,
            ),
            const SizedBox(height: 10),
          ],
          if (!hasOpenTask)
            openActionsAsync.maybeWhen(
              loading:
                  () => const _CopilotTaskStatus(
                    icon: Icons.sync_rounded,
                    title: 'Sincronizando tarefas',
                    subtitle: 'Checando Command Center antes de criar.',
                  ),
              orElse: () => const SizedBox.shrink(),
            ),
          if (!hasOpenTask && openActionsAsync.isLoading)
            const SizedBox(height: 10),
          if (!hasOpenTask)
            _Aluno360ActionRow(
            aluno: aluno,
            primary: primary,
            existingTask: openTask,
            openTaskHint: hasOpenCopilotTask360 && openTask == null,
            hidePrimaryCta: hasOpenTask || hideCopilotPrimary,
            hideChatCta: hideCopilotChat,
            acao: resolvedAcao,
            onAssign: (acao) => _criarTarefaCopiloto(context, ref, acao),
            onPrepareMessage: (acao) => _prepararMensagem(context, acao),
          ),
        ],
      ),
    );
  }
}

class _CopilotIaRefreshButton extends ConsumerStatefulWidget {
  const _CopilotIaRefreshButton({
    required this.alunoId,
    required this.primary,
  });

  final int alunoId;
  final Color primary;

  @override
  ConsumerState<_CopilotIaRefreshButton> createState() =>
      _CopilotIaRefreshButtonState();
}

class _CopilotIaRefreshButtonState extends ConsumerState<_CopilotIaRefreshButton> {
  var _refreshing = false;

  Future<void> _refreshIa() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    unawaited(
      AnalyticsService.instance.track(
        ProductEvents.aluno360CopilotRefresh,
        props: {'aluno_id': widget.alunoId},
      ),
    );
    await AlunoCopilotIaCacheStore.clear(widget.alunoId);
    ref.read(alunoCopilotIaSkipCacheProvider(widget.alunoId).notifier).state =
        true;
    ref.read(alunoCopilotoForceIaProvider(widget.alunoId).notifier).state = true;
    try {
      await ref.refresh(alunoCopilotoActionProvider(widget.alunoId).future);
      if (mounted) {
        FeedbackHelper.showSuccess(
          context,
          'Sugestão atualizada com IA',
        );
      }
    } catch (e) {
      ref.read(alunoCopilotoForceIaProvider(widget.alunoId).notifier).state =
          false;
      if (!mounted) return;
      if (_shouldSurfaceIaRefreshError(e)) {
        FeedbackHelper.showWarn(
          context,
          friendlyError(e, fallback: 'IA indisponível agora.'),
        );
      } else {
        FeedbackHelper.showSnackBar(
          context,
          SnackBar(
            content: Text(
              friendlyError(
                e,
                fallback:
                    'IA indisponível agora — mantendo sugestão do Aluno 360.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  bool _shouldSurfaceIaRefreshError(Object error) {
    if (error is IaOperationalException) {
      return error.quotaExhausted || error.planUpgradeRequired;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          _refreshing
              ? 'Atualizando sugestão com IA'
              : 'Atualizar sugestão com IA',
      child: IconButton.filledTonal(
      onPressed: _refreshing ? null : _refreshIa,
      icon:
          _refreshing
              ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: widget.primary,
                ),
              )
              : const Icon(Icons.refresh_rounded, size: 18),
      tooltip: _refreshing ? 'Atualizando…' : 'Regenerar sugestão com IA',
    ),
    );
  }
}

class _ContactPriorityBadge extends StatelessWidget {
  const _ContactPriorityBadge({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: EagleTokens.bad.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: EagleTokens.bad.withValues(alpha: 0.22)),
      ),
      child: Text(
        'Contato',
        style: TextStyle(
          color: EagleTokens.bad,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
