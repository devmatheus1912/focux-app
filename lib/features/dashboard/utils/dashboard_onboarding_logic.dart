/// Decide se o wizard de onboarding deve abrir ao entrar no hub personal.
bool dashboardShouldOpenOnboardingWizard({
  required bool wizardCompleto,
  required int progressPercent,
}) {
  if (wizardCompleto) return false;
  if (progressPercent >= 100) return false;
  if (DashboardOnboardingWizardGate.dismissedThisSession) return false;
  return true;
}

/// Fecha o wizard nesta sessão sem marcar ativação completa.
abstract final class DashboardOnboardingWizardGate {
  static bool _dismissedThisSession = false;

  static bool get dismissedThisSession => _dismissedThisSession;

  static void dismissForSession() => _dismissedThisSession = true;

  static void resetForTests() => _dismissedThisSession = false;
}
