import '../data/onboarding_repository.dart';
import '../data/setup_steps_catalog.dart';

/// Reordena o wizard do BFF para a ordem canônica do produto e aplica
/// título/descrição do catálogo (evita copy legado tipo "cor da marca").
/// Passos fora do catálogo (ou link-bio sem capability) são descartados.
OnboardingWizard normalizeOnboardingWizard(
  OnboardingWizard raw, {
  required bool landingCompleta,
}) {
  final byId = <String, OnboardingStep>{
    for (final step in raw.steps) step.id: step,
  };
  final visible = visibleSetupSteps(landingCompleta: landingCompleta);
  final steps = <OnboardingStep>[
    for (final entry in visible)
      OnboardingStep(
        id: entry.id,
        title: entry.title,
        description: entry.description,
        icon:
            byId[entry.id]?.icon.isNotEmpty == true
                ? byId[entry.id]!.icon
                : entry.icon,
        completed: byId[entry.id]?.completed ?? false,
        actionRoute:
            byId[entry.id]?.actionRoute.isNotEmpty == true
                ? byId[entry.id]!.actionRoute
                : entry.actionRoute,
        estimatedMinutes:
            (byId[entry.id]?.estimatedMinutes ?? 0) > 0
                ? byId[entry.id]!.estimatedMinutes
                : entry.estimatedMinutes,
      ),
  ];

  final completedCount = steps.where((s) => s.completed).length;
  final totalCount = steps.length;
  final pending = steps.where((s) => !s.completed).toList();
  final next = pending.isEmpty ? null : pending.first;
  final allDone = totalCount > 0 && pending.isEmpty;
  final progressPercent =
      totalCount == 0 ? 0 : ((completedCount * 100) / totalCount).round();

  return OnboardingWizard(
    steps: steps,
    completedCount: completedCount,
    totalCount: totalCount,
    progressPercent: progressPercent,
    nextActionLabel: next?.title ?? raw.nextActionLabel,
    nextActionRoute: next?.actionRoute ?? raw.nextActionRoute,
    wizardCompleto: raw.wizardCompleto,
    allStepsDone: allDone || raw.allStepsDone,
  );
}
