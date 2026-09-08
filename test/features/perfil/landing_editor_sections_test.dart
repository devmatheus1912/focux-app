import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/perfil/data/landing_studio_repository.dart';

void main() {
  test('LandingGerado.fromJson mapeia metodo servicos faq', () {
    final gerado = LandingGerado.fromJson({
      'heroTitle': 'Título',
      'heroSubtitle': 'Sub',
      'primaryCta': 'Quero',
      'bio': 'Bio',
      'metodo': [
        {'titulo': '1', 'descricao': 'a'},
        {'titulo': '2', 'descricao': 'b'},
      ],
      'servicos': [
        {'titulo': 'Online', 'descricao': 'App'},
      ],
      'faq': [
        {'pergunta': 'Serve?', 'resposta': 'Sim'},
      ],
      'fechamento': 'Bora',
      'needsProof': true,
    });

    expect(gerado.hasPublishableCopy, isTrue);
    expect(gerado.needsProof, isTrue);
    expect(gerado.metodo, hasLength(2));
    expect(gerado.servicos.single.titulo, 'Online');
    expect(gerado.faq.single.pergunta, 'Serve?');
  });

  test('LandingStudioState.fromJson aceita nested maps', () {
    final state = LandingStudioState.fromJson({
      'entrevista': {
        'nomeMarca': 'Ana',
        'nicho': 'Emagrecimento',
        'promessa': 'P',
        'cta': 'C',
      },
      'gerado': {'heroTitle': 'H', 'primaryCta': 'CTA', 'needsProof': true},
      'midia': {'heroImageUrl': 'https://x/y.jpg'},
      'slug': 'ana',
      'publicUrl': 'https://focuxpersonal.com/p/ana',
      'publicado': true,
      'podePublicar': true,
      'needsProof': true,
    });

    expect(state.publicado, isTrue);
    expect(state.slug, 'ana');
    expect(state.publicUrl, 'https://focuxpersonal.com/p/ana');
    expect(state.podePublicar, isTrue);
    expect(state.needsProof, isTrue);
    expect(state.entrevista.nomeMarca, 'Ana');
    expect(state.gerado.heroTitle, 'H');
    expect(state.midia.heroImageUrl, 'https://x/y.jpg');
  });
}
