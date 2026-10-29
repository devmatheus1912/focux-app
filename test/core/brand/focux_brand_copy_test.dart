import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/brand/focux_brand_copy.dart';

void main() {
  test('personal tem 3 benefícios e título próprio', () {
    final b = FocuxBrandCopy.onboardingBeneficios(OnboardingPersona.personal);
    expect(b, hasLength(3));
    expect(b.any((x) => x.texto.toLowerCase().contains('check-in')), isTrue);
    expect(b.any((x) => x.texto.contains('PIX')), isTrue);
    expect(
      FocuxBrandCopy.onboardingTitulo(OnboardingPersona.personal),
      'Seus alunos treinam. Você acompanha.',
    );
  });

  test('aluno tem 3 benefícios de treino, evolução e conversa', () {
    final b = FocuxBrandCopy.onboardingBeneficios(OnboardingPersona.aluno);
    expect(b, hasLength(3));
    expect(b.any((x) => x.texto.toLowerCase().contains('evolução')), isTrue);
    expect(b.any((x) => x.texto.toLowerCase().contains('personal')), isTrue);
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
