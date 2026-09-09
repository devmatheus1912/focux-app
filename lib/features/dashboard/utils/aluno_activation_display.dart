class AlunoActivationStep {
  const AlunoActivationStep({
    required this.title,
    required this.description,
    required this.done,
    required this.cta,
    required this.route,
  });

  final String title;
  final String description;
  final bool done;
  final String cta;
  final String route;
}

class AlunoActivationProgress {
  const AlunoActivationProgress({
    required this.steps,
    required this.current,
  });

  final List<AlunoActivationStep> steps;
  final AlunoActivationStep current;

  int get doneCount => steps.where((step) => step.done).length;

  int get totalCount => steps.length;

  bool get allDone => doneCount == totalCount && steps.isNotEmpty;

  String get etapaLabel {
    final total = totalCount <= 0 ? 1 : totalCount;
    final currentEtapa = allDone ? total : (doneCount + 1).clamp(1, total);
    return 'Etapa $currentEtapa de $total';
  }
}

int alunoActivationProfileCompletion({
  required String? telefone,
  required String? whatsapp,
  required String? objetivo,
  required String? genero,
  required String? peso,
  required String? altura,
  required String? dataNascimento,
  String? fotoUrl,
}) {
  final filled = [
    telefone,
    whatsapp,
    objetivo,
    genero,
    peso,
    altura,
    dataNascimento,
  ].where((value) => value != null && value.toString().trim().isNotEmpty).length;
  return (filled / 7 * 100).round();
}

AlunoActivationProgress alunoActivationProgress({
  required int profileCompletion,
  required bool hasMedidas,
  required bool hasTreinoConcluido,
  required bool hasChat,
}) {
  final steps = <AlunoActivationStep>[
    AlunoActivationStep(
      title: 'Completar seu perfil',
      description:
          'Objetivo, dados corporais e contato deixam o acompanhamento mais inteligente.',
      done: profileCompletion >= 80,
      cta: 'Ir para perfil',
      route: '/aluno/perfil',
    ),
    AlunoActivationStep(
      title: 'Registrar a primeira medida',
      description:
          'Seu corpo precisa de um ponto de partida para mostrar evolução de verdade.',
      done: hasMedidas,
      cta: 'Registrar medida',
      route: '/aluno/perfil',
    ),
    AlunoActivationStep(
      title: 'Fazer o primeiro treino',
      description:
          'Quando você treina pelo app, o personal ganha histórico para ajustar carga e frequência.',
      done: hasTreinoConcluido,
      cta: 'Abrir treinos',
      route: '/checkin/treinos',
    ),
    AlunoActivationStep(
      title: 'Abrir seu chat com o personal',
      description:
          'Dúvidas, feedback e alinhamento precisam acontecer no mesmo lugar do treino.',
      done: hasChat,
      cta: 'Abrir chat',
      route: '/chat/aluno',
    ),
  ];
  final current = steps.firstWhere(
    (step) => !step.done,
    orElse: () => steps.last,
  );
  return AlunoActivationProgress(steps: steps, current: current);
}

String alunoActivationLeaveTitle() => 'Pular por agora?';

String alunoActivationLeaveMessage() =>
    'O progresso já feito continua salvo. Você pode voltar depois.';

String alunoActivationLeaveConfirm() => 'Pular';

String alunoActivationQuestion({required bool allDone}) =>
    allDone ? 'Tudo pronto para evoluir' : 'Próximo passo';
