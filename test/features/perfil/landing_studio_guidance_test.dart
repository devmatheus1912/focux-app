import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/perfil/utils/landing_studio_guidance.dart';

void main() {
  test('CREF sozinho não conta como prova', () {
    expect(LandingStudioGuidance.isCrefOnly('CREF 01561-G'), isTrue);
    expect(
      LandingStudioGuidance.isCrefOnly(
        'Acompanhamento contínuo com alunos de hipertrofia há 6 anos',
      ),
      isFalse,
    );
  });

  test('readiness exige hero, preço e prova', () {
    expect(
      LandingStudioGuidance.isProfessionalReady(
        heroImageUrl: null,
        ofertaPreco: 'R\$ 297',
        needsProof: false,
        provaTexto: 'ok',
        bioImageUrl: null,
        heroTitle: 'T',
        primaryCta: 'C',
        whatsapp: '11999999999',
      ),
      isFalse,
    );
    expect(
      LandingStudioGuidance.isProfessionalReady(
        heroImageUrl: 'https://x/y.jpg',
        ofertaPreco: 'R\$ 297',
        needsProof: true,
        provaTexto: 'CREF 01561-G',
        bioImageUrl: null,
        heroTitle: 'T',
        primaryCta: 'C',
        whatsapp: '11999999999',
      ),
      isFalse,
    );
    expect(
      LandingStudioGuidance.isProfessionalReady(
        heroImageUrl: 'https://x/y.jpg',
        ofertaPreco: 'R\$ 297',
        needsProof: true,
        provaTexto:
            'Acompanhamento contínuo com alunos de hipertrofia há 6 anos',
        bioImageUrl: null,
        heroTitle: 'T',
        primaryCta: 'C',
        whatsapp: '11999999999',
      ),
      isTrue,
    );
  });

  test('publish help lista o que falta', () {
    final missing = LandingStudioGuidance.missingForPublish(
      heroImageUrl: null,
      ofertaPreco: '',
      needsProof: true,
      provaTexto: 'CREF 1',
      bioImageUrl: null,
      heroTitle: 'T',
      primaryCta: 'C',
      whatsapp: '1',
      podePublicar: true,
    );
    expect(missing, contains('Falta foto de capa (hero).'));
    expect(missing, contains('Falta preço na oferta.'));
    expect(
      LandingStudioGuidance.publishHelpBody(
        missing: const [],
        podePublicar: true,
      ),
      'Tudo certo pra publicar.',
    );
  });
}
