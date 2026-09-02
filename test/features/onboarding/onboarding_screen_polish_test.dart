import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('onboarding cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/onboarding/screens/onboarding_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
  });

  test('onboarding chrome soft alinhado à Home', () {
    final widgets = readScreenSourceBundle(
      'lib/features/onboarding/screens/onboarding_screen_widgets.part.dart',
    );
    final screen = readScreenSourceBundle(
      'lib/features/onboarding/screens/onboarding_screen.dart',
    );
    expect(widgets, contains('glassPanel'));
    expect(screen, contains('< 760'));
    // Hero budget: metric chips removidos do slide 1.
    expect(widgets, isNot(contains('class _MetricChipWidget')));
    expect(widgets, contains('_OnboardingHook'));
    expect(widgets, contains('FxSettingsTile'));
    expect(widgets, contains('onboardingPrimaryTileValue'));
    expect(widgets, contains('onboardingLoginTileValue'));
    expect(widgets, contains('onboardingCtaNext'));
    expect(widgets, contains('onboardingExistingAccountCta'));
    expect(
      widgets.indexOf('onboardingFinishCta'),
      lessThan(widgets.indexOf('onboardingExistingAccountCta')),
    );
    expect(widgets, isNot(contains('FxLiquidPrimaryButton')));
    expect(widgets, isNot(contains('FxLiquidSecondaryButton')));
    expect(screen, contains('AuthRoleToggle'));
    expect(screen, contains('AuthShell'));
    expect(screen, contains('PageView'));
  });
}
