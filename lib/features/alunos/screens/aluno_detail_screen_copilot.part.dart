part of 'aluno_detail_screen.dart';

class _Aluno360CopilotCard extends ConsumerWidget {
  final Aluno aluno;
  final AsyncValue<AlunoAutonomiaResumo> resumoAsync;
  final bool isDark;

  const _Aluno360CopilotCard({
    required this.aluno,
    required this.resumoAsync,
    required this.isDark,
  });

  List<_Aluno360Signal> _signals(
    BuildContext context,
    Aluno aluno,
    AlunoAutonomiaResumo? resumo,
  ) {
    final profile = _perfilCompletion(aluno);
    final financeiroOk = aluno.statusFinanceiro != 'INADIMPLENTE';
    final hasAutonomyFriction =
        resumo != null && resumo.cliques > resumo.concluidos;
    final hasEquipment = aluno.equipamentosDisponiveis.isNotEmpty;
    return [
      _Aluno360Signal(
        label: 'Perfil',
        value: '$profile%',
        detail:
            profile >= 80
                ? 'dados bons para prescrição'
                : 'faltam dados que melhoram decisão',
        color:
            profile >= 80
                ? EagleTokens.good
                : Theme.of(context).colorScheme.primary,
      ),
      _Aluno360Signal(
        label: 'Financeiro',
        value: financeiroOk ? 'OK' : 'Atenção',
        detail: financeiroOk ? 'sem bloqueio operacional' : 'pendência ativa',
        color: financeiroOk ? EagleTokens.good : EagleTokens.bad,
      ),
      _Aluno360Signal(
        label: 'Autonomia',
        value:
            resumo == null
                ? '--'
                : '${(resumo.concluidos / (resumo.cliques == 0 ? 1 : resumo.cliques) * 100).clamp(0, 100).round()}%',
        detail:
            hasAutonomyFriction
                ? 'clicou e ainda não fechou'
                : 'sem gargalo aberto forte',
        color:
            hasAutonomyFriction
                ? EagleTokens.warn
                : Theme.of(context).colorScheme.primary,
      ),
      _Aluno360Signal(
        label: 'Contexto',
        value: hasEquipment ? 'Rico' : 'Base',
        detail:
            hasEquipment
                ? '${aluno.equipamentosDisponiveis.length} equipamentos'
                : 'equipamentos não definidos',
        color: Theme.of(context).colorScheme.primary,
      ),
    ];
  }

  String _fallbackAction(Aluno aluno, AlunoAutonomiaResumo? resumo) {
    if (aluno.statusFinanceiro == 'INADIMPLENTE') {
      return 'Regularizar financeiro antes que isso vire atrito de acesso.';
    }
    if (_perfilCompletion(aluno) < 80) {
      return 'Completar perfil do aluno e remover lacunas de prescrição.';
    }
    if (resumo != null && resumo.cliques > resumo.concluidos) {
      return 'Resolver o gargalo de autonomia: ${resumo.gargaloTitulo ?? "tarefa aberta"}.';
    }
    return 'Revisar treino e propor a próxima evolução de ${aluno.objetivo ?? "objetivo"}.';
  }

  List<_ProfileGap> _profileGaps(Aluno aluno) {
    return [
      if ((aluno.telefone ?? '').trim().isEmpty &&
          (aluno.whatsapp ?? '').trim().isEmpty)
        const _ProfileGap(
          icon: Icons.call_outlined,
          title: 'Contato',
          detail: 'Telefone ou WhatsApp para acionar o aluno.',
          route: 'edit',
        ),
      if ((aluno.objetivo ?? '').trim().isEmpty)
        const _ProfileGap(
          icon: Icons.flag_outlined,
          title: 'Objetivo',
          detail: 'Define foco da prescrição e do Copiloto.',
          route: 'edit',
        ),
      if ((aluno.genero ?? '').trim().isEmpty ||
          (aluno.tipoConsultoria ?? '').trim().isEmpty)
        const _ProfileGap(
          icon: Icons.badge_outlined,
          title: 'Perfil do aluno',
          detail: 'Gênero e consultoria usados no atendimento.',
          route: 'edit',
        ),
    ];
  }

  Future<void> _openProfileGap(
    BuildContext context,
    Aluno aluno,
    _ProfileGap gap,
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
    final gaps = _profileGaps(aluno);
    if (gaps.length == 1) {
      await _openProfileGap(context, aluno, gaps.first);
      return;
    }
    await _showProfileGapSheet(context, aluno, gaps);
  }

  Future<void> _showProfileGapSheet(
    BuildContext context,
    Aluno aluno,
    List<_ProfileGap> gaps,
  ) async {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);

    Future<void> go(_ProfileGap gap, BuildContext sheetContext) async {
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

  void _prepararMensagem(BuildContext context, String acao) {
    final message = _mensagemPronta(aluno, acao);
    final primary = Theme.of(context).colorScheme.primary;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder:
          (sheetContext) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 4, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Mensagem sugerida',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: BrandPalette.softer(primary),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(message, style: const TextStyle(height: 1.35)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: message));
                            Navigator.pop(sheetContext);
                            FeedbackHelper.showSnackBar(
                              context,
                              const SnackBar(
                                content: Text('Mensagem copiada.'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copiar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FxLiquidPrimaryButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Abrir chat',
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            context.push(
                              '/alunos/${aluno.id}/chat',
                              extra: {'nome': aluno.nome},
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
    );
  }

  FilaAcaoResumo? _firstOpenCopilotAction(List<FilaAcaoResumo>? actions) {
    for (final item in actions ?? const <FilaAcaoResumo>[]) {
      if (item.status.toUpperCase() != 'ABERTO') continue;
      final source = (item.source ?? '').toUpperCase();
      final mode = (item.sourceMode ?? '').toUpperCase();
      if (item.tipo == 'IA_COPILOTO' ||
          source == 'ALUNO_360' ||
          mode == 'ALUNO_360' ||
          item.createdFromInsight) {
        return item;
      }
    }
    return null;
  }

  Future<bool> _criarTarefaCopiloto(
    BuildContext context,
    WidgetRef ref,
    String acao,
  ) async {
    try {
      final existing = _firstOpenCopilotAction(
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
              content: const Text('Tarefa ja aberta no Command Center.'),
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

  String _mensagemPronta(Aluno aluno, String acao) {
    final primeiroNome =
        aluno.nome.trim().isEmpty
            ? 'tudo bem'
            : aluno.nome.trim().split(' ').first;
    final lower = _cleanCopilotText(acao).toLowerCase();
    if (lower.contains('financeir') || lower.contains('inadimpl')) {
      return 'Oi, $primeiroNome. Preciso alinhar uma pendência rápida para manter seu acesso sem bloqueio. Me responde por aqui?';
    }
    if (lower.contains('perfil') || lower.contains('medida')) {
      return 'Oi, $primeiroNome. Quero completar alguns dados seus para ajustar melhor o plano. Me responde por aqui?';
    }
    if (lower.contains('treino') || lower.contains('carga')) {
      return 'Oi, $primeiroNome. Quero ajustar seu treino para o próximo passo com segurança. Me responde por aqui?';
    }
    return 'Oi, $primeiroNome. Notei que você se afastou um pouco dos treinos. Quer retomar? Me responde por aqui que eu ajusto o plano.';
  }

  String _displayAction(Aluno aluno, String acao) {
    final lower = _cleanCopilotText(acao).toLowerCase();
    if (lower.contains('financeir') || lower.contains('inadimpl')) {
      return 'Alinhar pendência financeira antes de qualquer ajuste.';
    }
    if (lower.contains('perfil') || lower.contains('medida')) {
      return 'Completar dados do perfil para melhorar a prescrição.';
    }
    if (lower.contains('treino') || lower.contains('carga')) {
      return 'Ajustar treino e orientar próximo check-in.';
    }
    return 'Retomar contato e ajustar plano com base na resposta.';
  }

  String _cleanCopilotText(String value) {
    return value
        .replaceAll(RegExp(r'\*\*|__|`'), '')
        .replaceAll(RegExp(r'^\s*[-•]\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final line = ShellChrome.of(context).line;
    final actionAsync = ref.watch(alunoCopilotoActionProvider(aluno.id));
    final openActionsAsync = ref.watch(alunoOpenIaActionsProvider(aluno.id));
    final openTask = _firstOpenCopilotAction(openActionsAsync.valueOrNull);
    final resumo = resumoAsync.valueOrNull;
    final profileCompletion = _perfilCompletion(aluno);
    final signals = _signals(context, aluno, resumo);
    final fallback = _fallbackAction(aluno, resumo);

    return Container(
      padding: const EdgeInsets.all(14),
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
                      'Próxima melhor ação',
                      style: TextStyle(
                        color: ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Decisão sugerida com perfil, autonomia e financeiro.',
                      style: TextStyle(
                        color: mute,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed:
                    () => ref.invalidate(alunoCopilotoActionProvider(aluno.id)),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                tooltip: 'Atualizar Copiloto',
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3.4,
            children:
                signals
                    .map((signal) => _Aluno360SignalTile(signal: signal))
                    .toList(),
          ),
          const SizedBox(height: 10),
          if (profileCompletion < 80) ...[
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () => _completeProfile(context, aluno),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: Text(
                  _profileGaps(aluno).length > 1
                      ? 'Resolver lacunas'
                      : 'Completar perfil',
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : BrandPalette.softer(primary),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: line),
            ),
            child: actionAsync.when(
              loading:
                  () => const SizedBox(
                    height: 52,
                    child: Center(child: LinearProgressIndicator(minHeight: 2)),
                  ),
              error:
                  (_, __) => _CopilotPrescription(
                    title: 'Sugestão offline',
                    action: fallback,
                    reason:
                        'IA indisponível agora; usando sinais do Aluno 360.',
                    color: primary,
                  ),
              data:
                  (action) => _CopilotPrescription(
                    title:
                        (action['titulo'] ??
                                action['tipo'] ??
                                'Próxima melhor ação')
                            .toString(),
                    action: _displayAction(
                      aluno,
                      (action['acao'] ??
                              action['mensagem'] ??
                              action['descricao'] ??
                              fallback)
                          .toString(),
                    ),
                    reason:
                        (action['motivo'] ?? 'Baseado nos sinais atuais.')
                            .toString(),
                    color: primary,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          openActionsAsync.maybeWhen(
            loading:
                () => const _CopilotTaskStatus(
                  icon: Icons.sync_rounded,
                  title: 'Sincronizando tarefas',
                  subtitle: 'Checando Command Center antes de criar.',
                ),
            data:
                (_) =>
                    openTask == null
                        ? const SizedBox.shrink()
                        : const _CopilotTaskStatus(
                          icon: Icons.task_alt_rounded,
                          title: 'Tarefa aberta',
                          subtitle:
                              'Já existe no Command Center. Sem duplicar.',
                        ),
            orElse: () => const SizedBox.shrink(),
          ),
          if (openActionsAsync.isLoading || openTask != null)
            const SizedBox(height: 10),
          actionAsync.maybeWhen(
            data:
                (action) => _Aluno360ActionRow(
                  aluno: aluno,
                  primary: primary,
                  existingTask: openTask,
                  acao: _cleanCopilotText(
                    (action['acao'] ??
                            action['mensagem'] ??
                            action['descricao'] ??
                            fallback)
                        .toString(),
                  ),
                  onAssign: (acao) => _criarTarefaCopiloto(context, ref, acao),
                  onPrepareMessage: (acao) => _prepararMensagem(context, acao),
                ),
            orElse:
                () => _Aluno360ActionRow(
                  aluno: aluno,
                  primary: primary,
                  existingTask: openTask,
                  acao: fallback,
                  onAssign: (acao) => _criarTarefaCopiloto(context, ref, acao),
                  onPrepareMessage: (acao) => _prepararMensagem(context, acao),
                ),
          ),
        ],
      ),
    );
  }
}
