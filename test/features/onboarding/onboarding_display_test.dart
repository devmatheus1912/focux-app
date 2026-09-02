import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/brand/focux_brand_copy.dart';
import 'package:focux_app/features/onboarding/utils/onboarding_display.dart';

void main() {
  test('valor do CTA primário distingue slide e persona', () {
    expect(
      onboardingPrimaryTileValue(
        isLast: false,
        persona: OnboardingPersona.personal,
      ),
      'Slide',
    );
    expect(
      onboardingPrimaryTileValue(
        isLast: true,
        persona: OnboardingPersona.personal,
      ),
      'Personal',
    );
    expect(
      onboardingPrimaryTileValue(
        isLast: true,
        persona: OnboardingPersona.aluno,
      ),
      'Aluno',
    );
  });

  test('tile de conta existente aponta para login', () {
    expect(onboardingLoginTileValue(), 'Login');
  });
}
