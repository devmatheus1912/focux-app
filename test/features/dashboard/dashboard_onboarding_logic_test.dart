import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_onboarding_logic.dart';

void main() {
  setUp(DashboardOnboardingWizardGate.resetForTests);
  tearDown(DashboardOnboardingWizardGate.resetForTests);

  test('abre wizard quando ativação está pendente', () {
    expect(
      dashboardShouldOpenOnboardingWizard(
        wizardCompleto: false,
        progressPercent: 14,
      ),
      isTrue,
    );
  });

  test('não reabre depois de fechar nesta sessão', () {
    DashboardOnboardingWizardGate.dismissForSession();
    expect(
      dashboardShouldOpenOnboardingWizard(
        wizardCompleto: false,
        progressPercent: 14,
      ),
      isFalse,
    );
  });

  test('não abre quando já concluído', () {
    expect(
      dashboardShouldOpenOnboardingWizard(
        wizardCompleto: true,
        progressPercent: 80,
      ),
      isFalse,
    );
  });
}
