import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/onboarding/data/onboarding_repository.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('onboarding wizard cumpre contrato S9', () {
    final screen = readScreenSourceBundle(
      'lib/features/onboarding/screens/onboarding_wizard_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxWizardStickyBar'));
    expect(screen, contains('FxWizardPopGuard'));
    expect(screen, contains('bottomNavigationBar'));
    expect(screen, contains('wizardEtapaLabel'));
    expect(screen, contains('wizardFazerDepoisLabel'));
    expect(screen, contains('foregroundColor: chrome.mute'));
    expect(screen, contains('TokensStrip.s6'));
    expect(screen, contains('TokensStrip.fontBodySm'));
    expect(screen, contains('FocuxHubTypography.sectionTitle'));
    expect(screen, contains('ProductEvents.setupWizardViewed'));
    expect(screen, contains('ProductEvents.setupWizardContinue'));
    expect(screen, contains('ProductEvents.setupWizardCompleted'));
    expect(screen, contains('DashboardHomeClientCache.clear'));
    expect(screen, contains('OnboardingWizardClientCache'));
    expect(screen, contains('_load(silent: true)'));
    expect(screen, contains('dismissForSession'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('wizardStickyLabel'));
    expect(screen, contains('_pedirConcluir'));
    expect(screen, isNot(contains('DashboardPrioritiesOverlay')));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('SetupStepCard')));
    expect(screen, isNot(contains('SetupProgressHeroCard')));
    expect(screen, isNot(contains("icon: 'x'")));
    expect(screen, isNot(contains('DashboardSectionHeader')));
  });

  test('remainingMinutes soma só os passos pendentes', () {
    OnboardingStep step({required bool done, required int minutes}) {
      return OnboardingStep(
        id: 'x',
        title: 't',
        description: 'd',
        icon: 'person',
        completed: done,
        actionRoute: '/',
        estimatedMinutes: minutes,
      );
    }

    final wizard = OnboardingWizard(
      steps: [
        step(done: true, minutes: 2),
        step(done: false, minutes: 2),
        step(done: false, minutes: 3),
      ],
      completedCount: 1,
      totalCount: 3,
      progressPercent: 33,
      nextActionLabel: 't',
      nextActionRoute: '/',
      wizardCompleto: false,
      allStepsDone: false,
    );
    expect(wizard.remainingMinutes, 5);
  });
}
