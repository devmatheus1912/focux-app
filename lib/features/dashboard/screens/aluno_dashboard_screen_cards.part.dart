part of 'aluno_dashboard_screen.dart';

class _StudentJourneyCard extends ConsumerStatefulWidget {
  final Aluno aluno;
  final List<ExecucaoTreino> treinos;
  final AsyncValue<List<MedidaCorporal>> medidasAsync;
  final AsyncValue<List<ExecucaoTreino>> historicoAsync;
  final AsyncValue<List<ChatMsg>> chatAsync;
  final bool isDark;
  final bool agendaReviewed;
  final Future<void> Function()? onReturnedFromTask;

  const _StudentJourneyCard({
    required this.aluno,
    required this.treinos,
    required this.medidasAsync,
    required this.historicoAsync,
    required this.chatAsync,
    required this.isDark,
    this.agendaReviewed = false,
    this.onReturnedFromTask,
  });

  @override
  ConsumerState<_StudentJourneyCard> createState() =>
      _StudentJourneyCardState();
}

class _StudentJourneyCardState extends ConsumerState<_StudentJourneyCard> {
  final Set<String> _trackedSessionEvents = {};

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.of(context);
    final ink = chrome.ink;
    final mute = chrome.mute;

    final medidas = widget.medidasAsync.value ?? const <MedidaCorporal>[];
    final historico =
        widget.historicoAsync.value ?? const <ExecucaoTreino>[];
    final mensagens = widget.chatAsync.value ?? const <ChatMsg>[];

    final plan = buildAlunoAutonomyPlan(
      aluno: widget.aluno,
      medidas: medidas,
      treinos: widget.treinos,
      historico: historico,
      mensagens: mensagens,
      agendaReviewed: widget.agendaReviewed,
    );
    final nextTask = plan.nextTask;
    final visibleTasks = [if (nextTask != null) nextTask];
    _trackVisibleTasks(visibleTasks, plan.profileCompletion);

    // Pendências 100% → some card (não misturar com % de perfil incompleto).
    if (plan.progress >= 100 && nextTask == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Central do aluno',
                      style: FocuxHubTypography.sectionTitle(
                        context,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s2),
                    Text(
                      'Pendências e próximos passos para você evoluir sem depender de cobrança do personal.',
                      style: FocuxHubTypography.bodyMuted(
                        color: mute,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TokensStrip.s3),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TokensStrip.s3,
                  vertical: TokensStrip.s2,
                ),
                decoration: BoxDecoration(
                  color: BrandPalette.soft(primary, dark: widget.isDark),
                  borderRadius: BorderRadius.circular(TokensStrip.rXl),
                ),
                child: Text(
                  '${plan.progress}%',
                  style: FocuxHubTypography.metric(
                    color: primary,
                    fontSize: FocuxHubTypography.metricEm,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s3),
          ClipRRect(
            borderRadius: BorderRadius.circular(TokensStrip.rPill),
            child: LinearProgressIndicator(
              value:
                  plan.tasks.isEmpty ? 1 : plan.doneCount / plan.tasks.length,
              minHeight: TokensStrip.s2,
              backgroundColor: BrandPalette.soft(primary, dark: widget.isDark),
              valueColor: AlwaysStoppedAnimation(primary),
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            plan.progress >= 100
                ? '${plan.doneCount} de ${plan.tasks.length} pendências fechadas.'
                : '${plan.doneCount} de ${plan.tasks.length} pendências fechadas. Perfil ${plan.profileCompletion}%.',
            style: FocuxHubTypography.bodyMuted(
              color: mute,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TokensStrip.s4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(TokensStrip.s3),
            decoration: BoxDecoration(
              color: BrandPalette.softer(primary, dark: widget.isDark),
              borderRadius: BorderRadius.circular(TokensStrip.rXl),
            ),
            child: _NextBestTaskPanel(
              task: nextTask,
              isDark: widget.isDark,
              onTap: nextTask == null ? null : () => _openTask(nextTask),
            ),
          ),
          const SizedBox(height: TokensStrip.s3),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed:
                  () => _showAlunoPlanSheet(
                    context,
                    isDark: widget.isDark,
                    primary: primary,
                    plan: plan,
                    onOpenTask: _openTask,
                  ),
              child: Text(
                plan.tasks.isEmpty
                    ? 'Ver plano completo'
                    : 'Ver plano completo (${plan.tasks.length})',
                style: FocuxHubTypography.chip(
                  BrandPalette.sectionLink(primary, dark: widget.isDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _trackVisibleTasks(
    List<AlunoAutonomyTask> tasks,
    int profileCompletion,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final task in tasks) {
        _trackTask(task, 'VIEWED', profileCompletion);
        if (task.done) {
          _trackTask(task, 'COMPLETED', profileCompletion);
        }
      }
    });
  }

  void _openTask(AlunoAutonomyTask task) {
    _trackTask(task, 'CLICKED', null);
    unawaited(
      context.push(task.route).then((_) async {
        final reload = widget.onReturnedFromTask;
        if (reload != null) await reload();
      }),
    );
  }

  void _trackTask(
    AlunoAutonomyTask task,
    String action,
    int? profileCompletion,
  ) {
    final sessionKey = '$action:${task.id}:${task.done}';
    if (action != 'CLICKED' && !_trackedSessionEvents.add(sessionKey)) {
      return;
    }
    final eventName = switch (action) {
      'CLICKED' => ProductEvents.alunoAutonomyTaskClicked,
      'COMPLETED' => ProductEvents.alunoAutonomyTaskCompleted,
      _ => ProductEvents.alunoAutonomyTaskViewed,
    };
    final props = {
      'taskId': task.id,
      'taskTitle': task.title,
      'route': task.route,
      'priority': task.priority.name,
      'done': task.done,
      if (profileCompletion != null) 'profileCompletion': profileCompletion,
    };
    unawaited(AnalyticsService.instance.track(eventName, props: props));
    unawaited(
      ref
          .read(alunoRepositoryProvider)
          .registrarEventoAutonomia(
            taskId: task.id,
            taskTitle: task.title,
            action: action,
            route: task.route,
            priority: task.priority.name.toUpperCase(),
            done: task.done,
            profileCompletion: profileCompletion,
          )
          .catchError((_) {}),
    );
  }
}

void _showAlunoPlanSheet(
  BuildContext context, {
  required bool isDark,
  required Color primary,
  required AlunoAutonomyPlan plan,
  required void Function(AlunoAutonomyTask task) onOpenTask,
}) {
  showFxHomeSheet<void>(
    context,
    builder: (sheetContext) {
      return FxHomeSheetSurface(
        isDark: isDark,
        maxHeight:
            MediaQuery.sizeOf(sheetContext).height *
            FxHomeSheetChrome.maxHeightFactor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FxHomeSheetHandle(isDark: isDark),
            SizedBox(height: TokensStrip.s4),
            FxHomeSheetHeader(
              isDark: isDark,
              title: 'Plano do aluno',
              subtitle:
                  '${plan.doneCount} de ${plan.tasks.length} passos fechados.',
              leading: Icon(Icons.route_outlined, size: 18, color: primary),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value:
                    plan.tasks.isEmpty ? 1 : plan.doneCount / plan.tasks.length,
                minHeight: 8,
                backgroundColor: BrandPalette.soft(primary, dark: isDark),
                valueColor: AlwaysStoppedAnimation(primary),
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: plan.tasks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 9),
                itemBuilder: (_, index) {
                  final task = plan.tasks[index];
                  return _AutonomyTaskTile(
                    task: task,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onOpenTask(task);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _NextBestTaskPanel extends StatelessWidget {
  final AlunoAutonomyTask? task;
  final bool isDark;
  final VoidCallback? onTap;

  const _NextBestTaskPanel({
    required this.task,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.of(context);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final icon = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: BrandPalette.soft(primary, dark: isDark),
        borderRadius: BorderRadius.circular(TokensStrip.rXl),
      ),
      child: Icon(_alunoTaskIcon(task?.kind), color: primary),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task == null ? 'Tudo em dia' : 'Próximo melhor passo',
          style: FocuxHubTypography.eyebrow(context, color: mute),
        ),
        const SizedBox(height: TokensStrip.s1),
        Text(
          task == null
              ? 'Sua rotina está organizada. Continue acompanhando treino, medidas e agenda.'
              : task!.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: FocuxHubTypography.cardTitle(color: ink),
        ),
        if (task != null) ...[
          const SizedBox(height: TokensStrip.s1),
          Text(
            task!.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: FocuxHubTypography.bodyMuted(color: mute),
          ),
        ],
      ],
    );
    final action =
        task == null
            ? null
            : TextButton(
              onPressed: onTap,
              child: Text(task!.cta, overflow: TextOverflow.ellipsis),
            );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Expanded(child: copy),
                ],
              ),
              if (action != null) ...[
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: action),
              ],
            ],
          );
        }

        return Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(child: copy),
            if (action != null) ...[
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 144),
                child: action,
              ),
            ],
          ],
        );
      },
    );
  }
}

IconData _alunoTaskIcon(AlunoTaskKind? kind) {
  switch (kind) {
    case AlunoTaskKind.perfil:
      return Icons.person_outline;
    case AlunoTaskKind.fotoDados:
      return Icons.add_a_photo_outlined;
    case AlunoTaskKind.medida:
      return Icons.straighten_outlined;
    case AlunoTaskKind.treino:
      return Icons.play_circle_outline;
    case AlunoTaskKind.chat:
      return Icons.chat_bubble_outline;
    case AlunoTaskKind.agenda:
      return Icons.calendar_month_outlined;
    case AlunoTaskKind.financeiro:
      return Icons.payments_outlined;
    case null:
      return Icons.check_circle_outline;
  }
}

class _AutonomyTaskTile extends StatelessWidget {
  final AlunoAutonomyTask task;
  final bool isDark;
  final VoidCallback onTap;

  const _AutonomyTaskTile({
    required this.task,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.of(context);
    final ink = chrome.ink;
    final mute = chrome.mute;

    final icon = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color:
            task.done
                ? EagleTokens.good.withValues(alpha: 0.14)
                : BrandPalette.soft(primary, dark: isDark),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        task.done ? Icons.check_rounded : _alunoTaskIcon(task.kind),
        color: task.done ? EagleTokens.good : primary,
        size: 20,
      ),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: FocuxHubTypography.cardTitle(color: ink),
        ),
        const SizedBox(height: TokensStrip.s1),
        Text(
          task.description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: FocuxHubTypography.bodyMuted(color: mute, height: 1.4),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _AutonomyTaskPill(
              label: _taskPriorityLabel(task.priority),
              color: _taskPriorityColor(task.priority, primary),
            ),
            _AutonomyTaskPill(
              label: task.done ? 'Sem ação agora' : _taskHint(task.kind),
              color: task.done ? EagleTokens.good : mute,
            ),
          ],
        ),
      ],
    );
    final action =
        task.done
            ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: EagleTokens.good.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Feito',
                style: FocuxHubTypography.chip(EagleTokens.good),
              ),
            )
            : TextButton(
              onPressed: onTap,
              child: Text(task.cta, overflow: TextOverflow.ellipsis),
            );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: fxListCardDecoration(context, accent: primary),
          child:
              compact
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          icon,
                          const SizedBox(width: 12),
                          Expanded(child: copy),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: action,
                        ),
                      ),
                    ],
                  )
                  : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      icon,
                      const SizedBox(width: 12),
                      Expanded(child: copy),
                      const SizedBox(width: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 132),
                        child: action,
                      ),
                    ],
                  ),
        );
      },
    );
  }
}

class _AutonomyTaskPill extends StatelessWidget {
  final String label;
  final Color color;

  const _AutonomyTaskPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: FocuxHubTypography.chip(color),
      ),
    );
  }
}

String _taskPriorityLabel(AlunoTaskPriority priority) {
  return switch (priority) {
    AlunoTaskPriority.alta => 'Prioridade alta',
    AlunoTaskPriority.media => 'Prioridade média',
    AlunoTaskPriority.baixa => 'Opcional',
  };
}

Color _taskPriorityColor(AlunoTaskPriority priority, Color primary) {
  return switch (priority) {
    AlunoTaskPriority.alta => EagleTokens.warn,
    AlunoTaskPriority.media => primary,
    AlunoTaskPriority.baixa => EagleTokens.priorityLow,
  };
}

String _taskHint(AlunoTaskKind kind) {
  return switch (kind) {
    AlunoTaskKind.perfil => 'Atualize seus dados',
    AlunoTaskKind.fotoDados => 'Foto e medidas',
    AlunoTaskKind.medida => 'Registrar progresso',
    AlunoTaskKind.treino => 'Mover treino',
    AlunoTaskKind.chat => 'Chamar personal',
    AlunoTaskKind.agenda => 'Conferir horário',
    AlunoTaskKind.financeiro => 'Ver financeiro',
  };
}
