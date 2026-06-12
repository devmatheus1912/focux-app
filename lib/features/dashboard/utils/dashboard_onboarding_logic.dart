/// Decide se o wizard de onboarding deve abrir ao entrar no hub personal.
bool dashboardShouldOpenOnboardingWizard({
  required bool wizardCompleto,
  required int progressPercent,
}) {
  if (wizardCompleto) return false;
  if (progressPercent >= 100) return false;
  return true;
}
