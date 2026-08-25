import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_client_cache.dart';
import 'package:focux_app/features/onboarding/data/onboarding_repository.dart';
import 'package:focux_app/features/onboarding/data/onboarding_wizard_client_cache.dart';

void main() {
  setUp(OnboardingWizardClientCache.clear);
  tearDown(OnboardingWizardClientCache.clear);

  OnboardingWizard wizard() => OnboardingWizard(
    steps: const [],
    completedCount: 1,
    totalCount: 7,
    progressPercent: 14,
    nextActionLabel: 'Complete seu perfil',
    nextActionRoute: '/perfil/editar',
    wizardCompleto: false,
    allStepsDone: false,
  );

  test('TTL 90s alinhado ao cache da Home', () {
    expect(
      OnboardingWizardClientCache.ttl,
      DashboardHomeClientCache.ttl,
    );
    final t0 = DateTime(2026, 8, 25, 20);
    OnboardingWizardClientCache.put(wizard(), now: t0);
    expect(
      OnboardingWizardClientCache.getIfFresh(
        now: t0.add(const Duration(seconds: 89)),
      ),
      isNotNull,
    );
    expect(
      OnboardingWizardClientCache.getIfFresh(
        now: t0.add(const Duration(seconds: 91)),
      ),
      isNull,
    );
  });
}
