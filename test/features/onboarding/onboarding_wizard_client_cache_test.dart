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

  test('chamadas simultâneas compartilham um único GET', () async {
    var calls = 0;
    Future<OnboardingWizard> fetch() async {
      calls++;
      await Future<void>.delayed(Duration.zero);
      return wizard();
    }

    final results = await Future.wait([
      OnboardingWizardClientCache.load(fetch),
      OnboardingWizardClientCache.load(fetch),
    ]);
    expect(calls, 1);
    expect(identical(results[0], results[1]), isTrue);

    await OnboardingWizardClientCache.load(fetch);
    expect(calls, 1, reason: 'cache fresco evita novo GET');
  });

  test('logout durante o GET não grava wizard do usuário anterior', () async {
    final pending = OnboardingWizardClientCache.load(() async {
      await Future<void>.delayed(Duration.zero);
      return wizard();
    });
    OnboardingWizardClientCache.clear();
    await pending;
    expect(OnboardingWizardClientCache.getIfFresh(), isNull);
  });
}
