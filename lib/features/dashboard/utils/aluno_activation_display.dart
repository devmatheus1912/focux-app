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

/// Só o necessário para treinar: nada de formulário longo na entrada.
AlunoActivationProgress alunoActivationProgress({
  required bool temFoto,
  required bool anamneseResolvida,
  required bool hasTreinoConcluido,
}) {
  final steps = <AlunoActivationStep>[
    AlunoActivationStep(
      title: 'Confirmar nome e foto',
      description: 'Assim seu personal reconhece você no app.',
      done: temFoto,
      cta: 'Abrir perfil',
      route: '/aluno/perfil',
    ),
    AlunoActivationStep(
      title: 'Responder a anamnese',
      description: 'Seu personal usa estas respostas para montar o treino.',
      done: anamneseResolvida,
      cta: 'Responder',
      route: '/aluno/anamnese',
    ),
    AlunoActivationStep(
      title: 'Ver o primeiro treino',
      description: 'Abra o treino e comece quando quiser.',
      done: hasTreinoConcluido,
      cta: 'Abrir treinos',
      route: '/checkin/treinos',
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

String alunoActivationQuestion({required bool allDone}) =>
    allDone ? 'Tudo pronto para evoluir' : 'Próximo passo';
