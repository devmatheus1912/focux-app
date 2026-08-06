import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/brand/brand_pulse.dart';
import 'package:focux_app/core/brand/focux_brand_copy.dart';

void main() {
  group('formatBrandSocialProofLine', () {
    test('uses first valid catalog item', () {
      final line = formatBrandSocialProofLine(const [
        BrandSocialProofItem(value: '2.847', label: 'personais ativos'),
        BrandSocialProofItem(value: '4.9★', label: 'App Store'),
      ]);
      expect(line, '2.847 personais ativos');
    });

    test('falls back when empty or invalid', () {
      expect(formatBrandSocialProofLine(const []), FocuxBrandCopy.onboardingSocialProofFallback);
      expect(
        formatBrandSocialProofLine(const [
          BrandSocialProofItem(value: '', label: 'x'),
        ]),
        FocuxBrandCopy.onboardingSocialProofFallback,
      );
    });
  });

  group('onboarding finish copy by persona', () {
    test('personal keeps free CTA', () {
      expect(
        FocuxBrandCopy.onboardingFinishCta(OnboardingPersona.personal),
        FocuxBrandCopy.onboardingCtaFinish,
      );
      expect(
        FocuxBrandCopy.onboardingFinishHint(OnboardingPersona.personal),
        FocuxBrandCopy.onboardingCtaFinishHint,
      );
    });

    test('aluno uses invite CTA', () {
      expect(
        FocuxBrandCopy.onboardingFinishCta(OnboardingPersona.aluno),
        FocuxBrandCopy.onboardingCtaFinishAluno,
      );
      expect(
        FocuxBrandCopy.onboardingFinishHint(OnboardingPersona.aluno),
        FocuxBrandCopy.onboardingCtaFinishHintAluno,
      );
    });
  });

  test('slide 1 has metrics without features; slide 2 inverse', () {
    for (final persona in OnboardingPersona.values) {
      final slides = FocuxBrandCopy.slidesFor(persona);
      expect(slides.length, 2);
      expect(slides[0].metrics, isNotEmpty);
      expect(slides[0].features, isEmpty);
      expect(slides[1].metrics, isEmpty);
      expect(slides[1].features, isNotEmpty);
    }
  });
}
