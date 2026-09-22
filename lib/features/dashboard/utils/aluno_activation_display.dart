class AlunoActivationStep {
  const AlunoActivationStep({
    required this.title,
    required this.description,
    required this.done,
    required this.cta,
    required this.route,
    this.optional = false,
  });

  final String title;
  final String description;
  final bool done;
  final String cta;
  final String route;
  final bool optional;
}

class AlunoActivationProgress {
  const AlunoActivationProgress({
    required this.steps,
    required this.current,
  });

  final List<AlunoActivationStep> steps;
  final AlunoActivationStep current;

  List<AlunoActivationStep> get _requiredSteps =>
      steps.where((step) => !step.optional).toList(growable: false);

  int get doneCount =>
      _requiredSteps.where((step) => step.done).length;

  int get totalCount => _requiredSteps.isEmpty ? 1 : _requiredSteps.length;

  bool get allDone =>
      _requiredSteps.isNotEmpty &&
      _requiredSteps.every((step) => step.done);

  String get etapaLabel {
    final total = totalCount;
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
      title: 'Falar com seu personal',
      description:
          'Dúvidas e feedback podem ficar no chat — quando quiser.',
      done: hasChat,
      cta: 'Abrir chat',
      route: '/chat/aluno',
      optional: true,
    ),
  ];
  final current = steps.firstWhere(
    (step) => !step.optional && !step.done,
    orElse: () => steps.firstWhere((step) => !step.optional, orElse: () => steps.last),
  );
  return AlunoActivationProgress(steps: steps, current: current);
}

String alunoActivationLeaveTitle() => 'Pular por agora?';

String alunoActivationLeaveMessage() =>
    'O progresso já feito continua salvo. Você pode voltar depois.';

String alunoActivationLeaveConfirm() => 'Pular';

String alunoActivationChatSkipLabel() => 'Falar depois';

String alunoActivationQuestion({required bool allDone}) =>
    allDone ? 'Tudo pronto para evoluir' : 'Próximo passo';
