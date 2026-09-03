part of 'aluno_dashboard_screen.dart';

class _StudentJourneyCard extends ConsumerStatefulWidget {
  final Aluno aluno;
  final List<ExecucaoTreino> treinos;
  final AsyncValue<List<MedidaCorporal>> medidasAsync;
  final AsyncValue<List<ExecucaoTreino>> historicoAsync;
  final AsyncValue<List<ChatMsg>> chatAsync;
  final bool isDark;

  const _StudentJourneyCard({
    required this.aluno,
    required this.treinos,
    required this.medidasAsync,
    required this.historicoAsync,
    required this.chatAsync,
    required this.isDark,
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
    final ink = widget.isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute =
        widget.isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    final medidas = widget.medidasAsync.valueOrNull ?? const <MedidaCorporal>[];
    final historico =
        widget.historicoAsync.valueOrNull ?? const <ExecucaoTreino>[];
    final mensagens = widget.chatAsync.valueOrNull ?? const <ChatMsg>[];

    final plan = buildAlunoAutonomyPlan(
      aluno: widget.aluno,
      medidas: medidas,
      treinos: widget.treinos,
      historico: historico,
      mensagens: mensagens,
    );
    final nextTask = plan.nextTask;
    final visibleTasks = [if (nextTask != null) nextTask];
    _trackVisibleTasks(visibleTasks, plan.profileCompletion);

    return Container(
      padding: const EdgeInsets.all(18),
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
                      style: TextStyle(
                        color: ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pendências e próximos passos para você evoluir sem depender de cobrança do personal.',
                      style: TextStyle(color: mute, height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: BrandPalette.soft(primary, dark: widget.isDark),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${plan.progress}%',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value:
                  plan.tasks.isEmpty ? 1 : plan.doneCount / plan.tasks.length,
              minHeight: 9,
              backgroundColor: BrandPalette.soft(primary, dark: widget.isDark),
              valueColor: AlwaysStoppedAnimation(primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${plan.doneCount} de ${plan.tasks.length} pendências fechadas. Perfil ${plan.profileCompletion}%.',
            style: TextStyle(
              color: mute,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TokensStrip.s4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  widget.isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : BrandPalette.softer(primary),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _NextBestTaskPanel(
              task: nextTask,
              isDark: widget.isDark,
              onTap: nextTask == null ? null : () => _openTask(nextTask),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: DashboardHomeActionChip(
              label:
                  plan.tasks.isEmpty
                      ? 'Ver plano completo'
                      : 'Ver plano completo (${plan.tasks.length})',
              accent: primary,
              isDark: widget.isDark,
              onPressed:
                  () => _showAlunoPlanSheet(
                    context,
                    isDark: widget.isDark,
                    primary: primary,
                    plan: plan,
                    onOpenTask: _openTask,
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
    context.push(task.route);
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
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final icon = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: BrandPalette.soft(primary, dark: isDark),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(_alunoTaskIcon(task?.kind), color: primary),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task == null ? 'Tudo em dia' : 'Próximo melhor passo',
          style: TextStyle(
            color: mute,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          task == null
              ? 'Sua rotina está organizada. Continue acompanhando treino, medidas e agenda.'
              : task!.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ink,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        if (task != null) ...[
          const SizedBox(height: 5),
          Text(
            task!.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: mute, fontSize: 12, height: 1.3),
          ),
        ],
      ],
    );
    final action =
        task == null
            ? null
            : FilledButton.tonal(
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
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

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
          style: TextStyle(
            color: ink,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          task.description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: mute, fontSize: 12.5, height: 1.4),
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
              child: const Text(
                'Feito',
                style: TextStyle(
                  color: EagleTokens.good,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
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
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
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
