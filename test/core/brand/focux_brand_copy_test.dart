import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/brand/focux_brand_copy.dart';

void main() {
  test('slides personal refletem produto real', () {
    final slides = FocuxBrandCopy.slidesFor(OnboardingPersona.personal);
    expect(slides, hasLength(2));
    expect(slides[1].features.any((f) => f.contains('Copiloto')), isTrue);
    expect(
      slides[0].subtitle.toLowerCase().contains('check-in'),
      isTrue,
    );
  });

  test('slides aluno cobrem treino e ecossistema completo', () {
    final slides = FocuxBrandCopy.slidesFor(OnboardingPersona.aluno);
    expect(slides, hasLength(2));
    expect(slides[0].titleHighlight, 'Na palma da mão.');
    expect(slides[1].title, 'IA, form check e mensalidade. ');
    expect(
      slides[1].features.any((f) => f.toLowerCase().contains('assistente')),
      isTrue,
    );
  });

  test('tagline unificada com hook de marca', () {
    expect(FocuxBrandCopy.tagline, FocuxBrandCopy.onboardingHook);
    expect(
      FocuxBrandCopy.onboardingHook.endsWith(
        FocuxBrandCopy.onboardingHookHighlight,
      ),
      isTrue,
    );
  });

  test('prova social fallback é neutra sem número inventado', () {
    expect(FocuxBrandCopy.onboardingSocialProofFallback, isNot(contains('+200')));
    expect(
      FocuxBrandCopy.onboardingSocialProofFallback.toLowerCase(),
      contains('personais'),
    );
  });
}
