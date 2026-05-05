import '../../alunos/data/aluno_repository.dart';
import '../../chat/data/chat_repository.dart';
import '../../checkin/data/checkin_repository.dart';
import '../../evolucao/data/evolucao_repository.dart';

enum AlunoTaskPriority { alta, media, baixa }

enum AlunoTaskKind {
  perfil,
  fotoDados,
  medida,
  treino,
  chat,
  agenda,
  financeiro,
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
  final hasOpenWorkout = treinos.isNotEmpty;
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
            'Foto, contato, objetivo e dados corporais reduzem perguntas repetidas e melhoram os ajustes.',
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
        priority: AlunoTaskPriority.alta,
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
                : 'Solicitar treino ativo',
        description:
            hasOpenWorkout
                ? 'Treinar pelo app gera histórico de carga, aderência e feedback para o personal.'
                : 'Avise seu personal que você está pronto para receber um treino ativo.',
        cta: hasOpenWorkout ? 'Treinar' : 'Chamar',
        route: hasOpenWorkout ? '/checkin/treinos' : '/chat/aluno',
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
    aluno.fotoUrl,
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
