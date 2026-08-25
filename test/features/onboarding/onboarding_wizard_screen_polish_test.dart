import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/onboarding/data/onboarding_repository.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('onboarding wizard cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/onboarding/screens/onboarding_wizard_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(
      screen,
      anyOf(
        contains('FxContentWidthLimiter'),
        isNot(contains('constrainWidth: false')),
      ),
    );
    expect(
      screen,
      anyOf(
        contains('friendlyError'),
        contains('DashboardErrorState'),
        contains('FxEmptyState'),
        contains('_erro'),
        contains('_TrainingEmptyState'),
        contains('ref.invalidate'),
      ),
    );
    expect(
      screen,
      anyOf(
        contains('FxLoading'),
        contains('SkeletonLoader'),
        contains('SkeletonList'),
        contains('DashboardShimmer'),
        contains('Shimmer'),
        contains('IaCopilotInsightsLoading'),
        contains('_loading'),
      ),
    );
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('SetupWizardCta'));
    expect(screen, contains('FxHubFreshness'));
    expect(screen, contains('ProductEvents.setupWizardViewed'));
    expect(screen, contains('ProductEvents.setupWizardContinue'));
    expect(screen, contains('ProductEvents.setupWizardCompleted'));
    expect(screen, contains('DashboardHomeClientCache.clear'));
    expect(screen, contains('OnboardingWizardClientCache'));
    expect(screen, contains('_load(silent: true)'));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
  });

  test('wizard fold segue pele do Perfil', () {
    final widgets = readScreenSourceBundle(
      'lib/features/onboarding/widgets/setup_step_widgets.dart',
    );
    expect(widgets, contains('DashboardHomeActionChip'));
    expect(widgets, contains('FxSettingsLayout.iconSize'));
    expect(widgets, contains('FocuxHubTypography'));
    expect(widgets, contains('minHeight: 4'));
    expect(widgets, contains('maxLines: 1'));
    expect(widgets, isNot(contains('maxLines: 2')));
    expect(widgets, isNot(contains('Próximo:')));
    expect(widgets, isNot(contains('setupStepUsesMaterialIcon')));
    expect(widgets, isNot(contains('SetupStepEntrance')));
    expect(widgets, isNot(contains('AGORA')));
    expect(widgets, isNot(contains('_SetupStepIconBadge')));
    expect(widgets, isNot(contains('SetupCompletedStepsCollapse')));
    expect(widgets, isNot(contains('DashboardHeroGridPainter')));
    expect(widgets, isNot(contains('FxLiquidPrimaryButton')));
  });

  test('wizard lista usa inset compacto e tempo restante', () {
    final screen = readScreenSourceBundle(
      'lib/features/onboarding/screens/onboarding_wizard_screen.dart',
    );
    expect(screen, contains('FxSettingsLayout.headerToGroup'));
    expect(screen, contains('remainingMinutes'));
    expect(screen, isNot(contains('SetupStepEntrance')));
    expect(screen, isNot(contains('nextActionLabel:')));
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
