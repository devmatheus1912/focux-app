import '../../alunos/data/aluno_repository.dart';
import '../../chat/data/chat_repository.dart';
import '../../checkin/data/checkin_repository.dart';
import '../../checkin/utils/treino_ficha_status.dart';
import '../../evolucao/data/evolucao_repository.dart';

enum AlunoTaskPriority { alta, media, baixa }

enum AlunoHomeMode {
  workoutReady,
  profileSetup,
  comeback,
  financialHold,
  evolution,
  noWorkout,
  awaitingRelease,
  steady,
}

enum AlunoTaskKind {
  perfil,
  fotoDados,
  medida,
  treino,
  chat,
  agenda,
  financeiro,
}

class AlunoHomeAction {
  final AlunoHomeMode mode;
  final String eyebrow;
  final String title;
  final String description;
  final String cta;
  final String route;
  final Object? routeExtra;

  const AlunoHomeAction({
    required this.mode,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.cta,
    required this.route,
    this.routeExtra,
  });
}

class FocuxScore {
  final int value;
  final String rhythmLabel;
  final String riskLabel;
  final String nextSignal;

  const FocuxScore({
    required this.value,
    required this.rhythmLabel,
    required this.riskLabel,
    required this.nextSignal,
  });
}

class AlunoObjectiveLens {
  final String label;
  final String primaryMetric;
  final String promise;

  const AlunoObjectiveLens({
    required this.label,
    required this.primaryMetric,
    required this.promise,
  });
}

class AlunoHomeExperience {
  final AlunoHomeAction action;
  final FocuxScore score;
  final AlunoAutonomyPlan plan;
  final AlunoObjectiveLens objectiveLens;
  final List<String> narratives;

  const AlunoHomeExperience({
    required this.action,
    required this.score,
    required this.plan,
    required this.objectiveLens,
    required this.narratives,
  });
}

class AlunoAutonomyTask {
  final String id;
  final String title;
  final String description;
  final String cta;
  final String route;
  final AlunoTaskKind kind;
  final AlunoTaskPriority priority;
  final bool done;

  const AlunoAutonomyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.cta,
    required this.route,
    required this.kind,
    required this.priority,
    required this.done,
  });
}

class AlunoAutonomyPlan {
  final List<AlunoAutonomyTask> tasks;
  final int profileCompletion;

  const AlunoAutonomyPlan({
    required this.tasks,
    required this.profileCompletion,
  });

  int get doneCount => tasks.where((task) => task.done).length;

  int get openCount => tasks.length - doneCount;

  int get progress =>
      tasks.isEmpty ? 100 : ((doneCount / tasks.length) * 100).round();

  AlunoAutonomyTask? get nextTask {
    final open =
        tasks.where((task) => !task.done).toList()
          ..sort((a, b) => a.priority.index.compareTo(b.priority.index));
    return open.isEmpty ? null : open.first;
  }
}

AlunoHomeExperience buildAlunoHomeExperience({
  required Aluno aluno,
  required List<MedidaCorporal> medidas,
  required List<ExecucaoTreino> treinos,
  required List<ExecucaoTreino> historico,
  required List<ChatMsg> mensagens,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final plan = buildAlunoAutonomyPlan(
    aluno: aluno,
    medidas: medidas,
    treinos: treinos,
    historico: historico,
    mensagens: mensagens,
    now: today,
  );
  final score = _buildFocuxScore(
    aluno: aluno,
    plan: plan,
    medidas: medidas,
    historico: historico,
    mensagens: mensagens,
    now: today,
  );
  final lens = _objectiveLens(aluno.objetivo);
  final action = _mainHomeAction(
    aluno: aluno,
    treinos: treinos,
    historico: historico,
    plan: plan,
    score: score,
    lens: lens,
    now: today,
  );

  return AlunoHomeExperience(
    action: action,
    score: score,
    plan: plan,
    objectiveLens: lens,
    narratives: _homeNarratives(
      aluno: aluno,
      treinos: treinos,
      historico: historico,
      mensagens: mensagens,
      score: score,
      lens: lens,
      now: today,
    ),
  );
}

AlunoAutonomyPlan buildAlunoAutonomyPlan({
  required Aluno aluno,
  required List<MedidaCorporal> medidas,
  required List<ExecucaoTreino> treinos,
  required List<ExecucaoTreino> historico,
  required List<ChatMsg> mensagens,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final profileCompletion = _profileCompletion(aluno);
  final hasPhoto = _isFilled(aluno.fotoUrl);
  final hasBodyData =
      aluno.peso != null &&
      aluno.altura != null &&
      _isFilled(aluno.dataNascimento);
  final lastMeasure = _latestMeasureDate(medidas);
  final hasFreshMeasure =
      lastMeasure != null && today.difference(lastMeasure).inDays <= 14;
  final hasWeeklyWorkout = historico.any(
    (item) =>
        item.status.toUpperCase() == 'CONCLUIDO' &&
        _isWithinDays(_eventDate(item), today, 7),
  );
  final hasStudentMessage = mensagens.any(
    (item) => item.remetente.toUpperCase() == 'ALUNO',
  );
  final startable = treinosProntosParaIniciar(treinos);
  final hasOpenWorkout = startable.isNotEmpty;
  final hasAwaitingOnly =
      !hasOpenWorkout && treinos.any(isTreinoAguardandoLiberacao);
  final isInadimplente =
      aluno.inadimplente ||
      aluno.statusFinanceiro.toUpperCase() == 'INADIMPLENTE';

  return AlunoAutonomyPlan(
    profileCompletion: profileCompletion,
    tasks: [
      AlunoAutonomyTask(
        id: 'perfil-base',
        title: 'Completar perfil base',
        description:
            'Contato, objetivo e dados corporais reduzem perguntas repetidas e melhoram os ajustes.',
        cta: 'Completar',
        route: '/aluno/perfil',
        kind: AlunoTaskKind.perfil,
        priority:
            profileCompletion < 60
                ? AlunoTaskPriority.alta
                : AlunoTaskPriority.media,
        done: profileCompletion >= 80,
      ),
      AlunoAutonomyTask(
        id: 'foto-dados',
        title: 'Adicionar foto e dados corporais',
        description:
            'Sua foto, peso, altura e nascimento deixam acompanhamento, comparativos e contato mais humanos.',
        cta: 'Atualizar',
        route: '/aluno/perfil',
        kind: AlunoTaskKind.fotoDados,
        priority: hasPhoto ? AlunoTaskPriority.media : AlunoTaskPriority.alta,
        done: hasPhoto && hasBodyData,
      ),
      AlunoAutonomyTask(
        id: 'medida-recente',
        title:
            medidas.isEmpty
                ? 'Registrar primeira medida'
                : 'Atualizar medida quinzenal',
        description:
            medidas.isEmpty
                ? 'Crie seu ponto de partida com peso, medidas e foto opcional de progresso.'
                : 'Mantenha peso, medidas e foto de progresso atualizados a cada 14 dias.',
        cta: 'Registrar',
        route: '/aluno/perfil',
        kind: AlunoTaskKind.medida,
        priority:
            medidas.isEmpty ? AlunoTaskPriority.alta : AlunoTaskPriority.media,
        done: hasFreshMeasure,
      ),
      AlunoAutonomyTask(
        id: 'treino-semana',
        title:
            hasOpenWorkout
                ? 'Concluir treino da semana'
                : hasAwaitingOnly
                ? 'Aguardando liberação da ficha'
                : 'Solicitar treino ativo',
        description:
            hasOpenWorkout
                ? 'Treinar pelo app gera histórico de carga, aderência e feedback para o personal.'
                : hasAwaitingOnly
                ? 'Seu personal já reservou o treino. Os exercícios aparecem quando forem liberados.'
                : 'Avise seu personal que você está pronto para receber um treino ativo.',
        cta:
            hasOpenWorkout
                ? 'Treinar'
                : hasAwaitingOnly
                ? 'Ver status'
                : 'Chamar',
        route:
            hasOpenWorkout || hasAwaitingOnly
                ? '/checkin/treinos'
                : '/chat/aluno',
        kind: AlunoTaskKind.treino,
        priority: AlunoTaskPriority.alta,
        done: hasWeeklyWorkout,
      ),
      AlunoAutonomyTask(
        id: 'chat-contexto',
        title: 'Enviar contexto no chat',
        description:
            'Use o chat para dúvidas, dor, dificuldade, preferência e feedback do treino no mesmo lugar.',
        cta: 'Abrir chat',
        route: '/chat/aluno',
        kind: AlunoTaskKind.chat,
        priority: AlunoTaskPriority.media,
        done: hasStudentMessage,
      ),
      AlunoAutonomyTask(
        id: 'agenda-semana',
        title: 'Conferir agenda da semana',
        description:
            'Revise horários, compromissos e presenças para evitar perda de acompanhamento.',
        cta: 'Ver agenda',
        route: '/agenda/aluno',
        kind: AlunoTaskKind.agenda,
        priority: AlunoTaskPriority.baixa,
        done: false,
      ),
      AlunoAutonomyTask(
        id: 'financeiro',
        title: isInadimplente ? 'Regularizar financeiro' : 'Financeiro em dia',
        description:
            isInadimplente
                ? 'Resolva pendências para não interromper acesso, treino e acompanhamento.'
                : 'Acompanhe pagamentos e recibos sem depender do personal.',
        cta: 'Abrir',
        route: '/financeiro/aluno',
        kind: AlunoTaskKind.financeiro,
        priority:
            isInadimplente ? AlunoTaskPriority.alta : AlunoTaskPriority.baixa,
        done: !isInadimplente,
      ),
    ],
  );
}

AlunoHomeAction _mainHomeAction({
  required Aluno aluno,
  required List<ExecucaoTreino> treinos,
  required List<ExecucaoTreino> historico,
  required AlunoAutonomyPlan plan,
  required FocuxScore score,
  required AlunoObjectiveLens lens,
  required DateTime now,
}) {
  final isInadimplente =
      aluno.inadimplente ||
      aluno.statusFinanceiro.toUpperCase() == 'INADIMPLENTE';
  if (isInadimplente) {
    return const AlunoHomeAction(
      mode: AlunoHomeMode.financialHold,
      eyebrow: 'Acesso em atenção',
      title: 'Regularize para manter seu plano vivo',
      description:
          'Treino, histórico e acompanhamento ficam mais seguros quando o financeiro está em dia.',
      cta: 'Abrir financeiro',
      route: '/financeiro/aluno',
    );
  }

  if (plan.profileCompletion < 60) {
    return const AlunoHomeAction(
      mode: AlunoHomeMode.profileSetup,
      eyebrow: 'Base incompleta',
      title: 'Complete seu mapa corporal',
      description:
          'Medidas e objetivo dão ao personal contexto para ajustar treino sem adivinhação.',
      cta: 'Completar perfil',
      route: '/aluno/perfil',
    );
  }

  if (!_isFilled(aluno.fotoUrl)) {
    return const AlunoHomeAction(
      mode: AlunoHomeMode.profileSetup,
      eyebrow: 'Quase lá',
      title: 'Adicione sua foto',
      description:
          'O avatar humaniza o acompanhamento e some assim que a foto estiver no cadastro.',
      cta: 'Enviar foto',
      route: '/aluno/perfil',
    );
  }

  final startable = treinosProntosParaIniciar(treinos);
  final awaiting = treinos.where(isTreinoAguardandoLiberacao).toList();
  final lastWorkout = _latestWorkoutDate(historico);
  final inactiveDays =
      lastWorkout == null ? 99 : now.difference(lastWorkout).inDays;
  if (inactiveDays >= 7 && startable.isNotEmpty) {
    final workout = startable.first;
    return AlunoHomeAction(
      mode: AlunoHomeMode.comeback,
      eyebrow: 'Retomada inteligente',
      title: 'Volte com ${workout.treinoNome}',
      description:
          'Uma sessão hoje já muda seu ritmo da semana. Sem pressão, só o próximo passo.',
      cta: 'Retomar agora',
      route: '/checkin/executar',
      routeExtra: workout.treinoId,
    );
  }

  if (startable.isNotEmpty) {
    final workout = startable.first;
    return AlunoHomeAction(
      mode: AlunoHomeMode.workoutReady,
      eyebrow: 'Plano de hoje',
      title: workout.treinoNome,
      description:
          '${workout.exercicios.length} exercícios prontos para trabalhar ${lens.primaryMetric.toLowerCase()}.',
      cta: 'Treinar agora',
      route: '/checkin/executar',
      routeExtra: workout.treinoId,
    );
  }

  if (awaiting.isNotEmpty) {
    final workout = awaiting.first;
    return AlunoHomeAction(
      mode: AlunoHomeMode.awaitingRelease,
      eyebrow: 'Em preparação',
      title: workout.treinoNome,
      description:
          'Treino reservado. A ficha abre assim que o personal liberar os exercícios.',
      cta: 'Ver status do treino',
      route: '/checkin/treinos',
    );
  }

  final lastEvolution = _latestEvolution(historico);
  if (lastEvolution != null) {
    return AlunoHomeAction(
      mode: AlunoHomeMode.evolution,
      eyebrow: 'Evolução detectada',
      title: 'Você abriu uma nova faixa de progresso',
      description: lastEvolution,
      cta: 'Ver evolução',
      route: '/checkin/historico',
    );
  }

  if (score.value >= 80) {
    return AlunoHomeAction(
      mode: AlunoHomeMode.steady,
      eyebrow: 'Rotina em alta',
      title: 'Você está pronto para o próximo ajuste',
      description:
          'Seu ritmo está consistente. Chame o personal para transformar isso em evolução planejada.',
      cta: 'Chamar personal',
      route: '/chat/aluno',
    );
  }

  return const AlunoHomeAction(
    mode: AlunoHomeMode.noWorkout,
    eyebrow: 'Próxima melhor ação',
    title: 'Peça um treino ativo ao personal',
    description:
        'Seu perfil já tem base suficiente. Falta liberar o próximo treino para movimentar a semana.',
    cta: 'Enviar mensagem',
    route: '/chat/aluno',
  );
}

FocuxScore _buildFocuxScore({
  required Aluno aluno,
  required AlunoAutonomyPlan plan,
  required List<MedidaCorporal> medidas,
  required List<ExecucaoTreino> historico,
  required List<ChatMsg> mensagens,
  required DateTime now,
}) {
  final completed7 = _completedSince(
    historico,
    now.subtract(const Duration(days: 7)),
  );
  final consistency = (completed7 / 3).clamp(0.0, 1.0);
  final hasEvolution = _latestEvolution(historico) != null;
  final hasRecentMeasure =
      _latestMeasureDate(
        medidas,
      )?.isAfter(now.subtract(const Duration(days: 14))) ??
      false;
  final hasRecentChat = mensagens.any(
    (item) =>
        item.remetente.toUpperCase() == 'ALUNO' &&
        !item.enviadoEm.isBefore(now.subtract(const Duration(days: 14))),
  );
  final financeOk =
      !aluno.inadimplente &&
      aluno.statusFinanceiro.toUpperCase() != 'INADIMPLENTE';

  final value = (plan.profileCompletion * 0.18 +
          consistency * 32 +
          (hasEvolution ? 18 : 0) +
          (hasRecentMeasure ? 12 : 0) +
          (hasRecentChat ? 10 : 0) +
          (financeOk ? 10 : 0))
      .round()
      .clamp(0, 100);
  final lastWorkout = _latestWorkoutDate(historico);
  final inactiveDays =
      lastWorkout == null ? 99 : now.difference(lastWorkout).inDays;
  final riskLabel =
      aluno.emRisco || inactiveDays >= 10
          ? 'Risco alto'
          : inactiveDays >= 5
          ? 'Risco moderado'
          : 'Risco baixo';
  final rhythmLabel =
      value >= 85
          ? 'Ritmo forte'
          : value >= 65
          ? 'Ritmo construindo'
          : value >= 40
          ? 'Ritmo instável'
          : 'Ritmo em retomada';
  final nextSignal =
      plan.nextTask == null
          ? 'Sinal verde para evolução'
          : 'Próxima ação: ${plan.nextTask!.title.toLowerCase()}';

  return FocuxScore(
    value: value,
    rhythmLabel: rhythmLabel,
    riskLabel: riskLabel,
    nextSignal: nextSignal,
  );
}

AlunoObjectiveLens _objectiveLens(String? objetivo) {
  final normalized = objetivo?.toLowerCase() ?? '';
  if (normalized.contains('emagrec')) {
    return const AlunoObjectiveLens(
      label: 'Emagrecimento',
      primaryMetric: 'frequência e medidas',
      promise: 'O foco é transformar presença em tendência corporal.',
    );
  }
  if (normalized.contains('saúde') || normalized.contains('saude')) {
    return const AlunoObjectiveLens(
      label: 'Saúde',
      primaryMetric: 'regularidade e bem-estar',
      promise: 'O foco é manter o corpo seguro e a rotina sustentável.',
    );
  }
  if (normalized.contains('performance')) {
    return const AlunoObjectiveLens(
      label: 'Performance',
      primaryMetric: 'intensidade e metas',
      promise: 'O foco é converter execução em resultado mensurável.',
    );
  }
  if (normalized.contains('reabil')) {
    return const AlunoObjectiveLens(
      label: 'Reabilitação',
      primaryMetric: 'controle e segurança',
      promise: 'O foco é evoluir sem atropelar limite, dor ou técnica.',
    );
  }
  return const AlunoObjectiveLens(
    label: 'Hipertrofia',
    primaryMetric: 'volume e carga',
    promise: 'O foco é fazer cada sessão gerar sinal de progressão.',
  );
}

List<String> _homeNarratives({
  required Aluno aluno,
  required List<ExecucaoTreino> treinos,
  required List<ExecucaoTreino> historico,
  required List<ChatMsg> mensagens,
  required FocuxScore score,
  required AlunoObjectiveLens lens,
  required DateTime now,
}) {
  final firstName = aluno.nome.trim().split(RegExp(r'\s+')).first;
  final completed7 = _completedSince(
    historico,
    now.subtract(const Duration(days: 7)),
  );
  final lastEvolution = _latestEvolution(historico);
  final lastChat =
      mensagens
          .where((item) => item.remetente.toUpperCase() == 'ALUNO')
          .toList()
        ..sort((a, b) => b.enviadoEm.compareTo(a.enviadoEm));
  final startable = treinosProntosParaIniciar(treinos);
  final awaiting = treinos.where(isTreinoAguardandoLiberacao).toList();
  return [
    if (startable.isNotEmpty)
      '$firstName tem ${startable.first.treinoNome} pronto com foco em ${lens.primaryMetric}.',
    if (startable.isEmpty && awaiting.isNotEmpty)
      '${awaiting.first.treinoNome} está em preparação — aguardando liberação dos exercícios.',
    if (completed7 > 0)
      'Você concluiu $completed7 treino${completed7 == 1 ? '' : 's'} nos últimos 7 dias.',
    if (lastEvolution != null) lastEvolution,
    if (lastChat.isNotEmpty)
      'Seu último feedback já virou contexto para o personal.',
    score.nextSignal,
    lens.promise,
  ].take(4).toList();
}

bool _isFilled(String? value) => value != null && value.trim().isNotEmpty;

int _profileCompletion(Aluno aluno) {
  final fields = [
    aluno.telefone,
    aluno.whatsapp,
    aluno.objetivo,
    aluno.genero,
    aluno.peso?.toString(),
    aluno.altura?.toString(),
    aluno.dataNascimento,
  ];
  final filled = fields.where((value) => _isFilled(value)).length;
  return ((filled / fields.length) * 100).round();
}

DateTime? _latestMeasureDate(List<MedidaCorporal> medidas) {
  final dates =
      medidas
          .map((item) => DateTime.tryParse(item.data))
          .whereType<DateTime>()
          .toList()
        ..sort();
  return dates.isEmpty ? null : dates.last;
}

DateTime? _eventDate(ExecucaoTreino treino) {
  return DateTime.tryParse(treino.concluidoEm ?? '') ??
      DateTime.tryParse(treino.iniciadoEm ?? '');
}

bool _isWithinDays(DateTime? date, DateTime now, int days) {
  if (date == null) return false;
  final diff = now.difference(date);
  return diff.inDays >= 0 && diff.inDays <= days;
}

DateTime? _latestWorkoutDate(List<ExecucaoTreino> historico) {
  final dates =
      historico.map(_eventDate).whereType<DateTime>().toList()..sort();
  return dates.isEmpty ? null : dates.last;
}

int _completedSince(List<ExecucaoTreino> historico, DateTime start) {
  return historico.where((treino) {
    final date = _eventDate(treino);
    return treino.status.toUpperCase() == 'CONCLUIDO' &&
        date != null &&
        !date.isBefore(start);
  }).length;
}

String? _latestEvolution(List<ExecucaoTreino> historico) {
  for (final treino in historico) {
    if (treino.evolucoesPerformance.isNotEmpty) {
      final item = treino.evolucoesPerformance.first;
      if (item.mensagem.trim().isNotEmpty) return item.mensagem;
      return 'Você evoluiu em ${item.exercicioNome}.';
    }
    if (treino.evolucoesCarga.isNotEmpty) {
      final item = treino.evolucoesCarga.first;
      if (item.mensagem.trim().isNotEmpty) return item.mensagem;
      return 'Sua carga em ${item.exercicioNome} subiu ${item.diferencaKg.toStringAsFixed(1)} kg.';
    }
  }
  return null;
}
