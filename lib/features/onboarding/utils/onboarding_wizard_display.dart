import '../data/onboarding_repository.dart';
import '../data/setup_steps_catalog.dart';

/// O botão diz o que acontece: "Cadastrar aluno", não "Continuar".
String wizardStickyLabel({
  required bool allDone,
  required List<OnboardingStep> steps,
}) {
  if (allDone) return 'Concluir';
  final atual = steps.where((s) => !s.completed).firstOrNull;
  if (atual == null) return 'Concluir';
  return setupStepCatalog
          .where((e) => e.id == atual.id)
          .firstOrNull
          ?.acao ??
      atual.title;
}

String wizardFazerDepoisLabel() => 'Agora não';

String wizardIntroTitle() => 'Seu primeiro aluno treinando';

String wizardIntroBody() => 'Três passos e você já está usando o app de verdade.';

String wizardDoneTitle() => 'Tudo pronto';

String wizardDoneBody() => 'Seu aluno já pode treinar pelo app.';

int wizardEtapaCurrent({
  required int completedCount,
  required int totalCount,
  required bool allDone,
}) {
  if (totalCount <= 0) return 1;
  if (allDone) return totalCount;
  final current = completedCount + 1;
  if (current < 1) return 1;
  if (current > totalCount) return totalCount;
  return current;
}

String wizardEtapaLabel({
  required int completedCount,
  required int totalCount,
  required bool allDone,
}) {
  final total = totalCount <= 0 ? 1 : totalCount;
  return 'Etapa ${wizardEtapaCurrent(
    completedCount: completedCount,
    totalCount: total,
    allDone: allDone,
  )} de $total';
}

String wizardHelpTitle() => 'Primeiros passos';

String wizardHelpSubtitle() =>
    'Uma etapa de cada vez. Pode fechar e voltar depois.';

String wizardHelpPassosBody() =>
    'Continuar abre o próximo passo. O progresso fica salvo; você retoma de onde parou.';

String wizardHelpConcluirBody() =>
    'Concluir esconde o checklist da Home. O que você já cadastrou fica.';

