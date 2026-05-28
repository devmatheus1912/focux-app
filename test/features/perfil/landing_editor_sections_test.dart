import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/perfil/screens/landing_editor_checklist.dart';
import 'package:focux_app/features/perfil/screens/landing_editor_quality.dart';
import 'package:focux_app/features/perfil/screens/landing_editor_sections.dart';

void main() {
  test('normalizeLandingSectionOrder deduplicates legacy keys', () {
    final result = normalizeLandingSectionOrder([
      'prova',
      'metodo',
      'sobre',
      'ofertas',
      'prova',
      'app',
    ]);

    expect(result, contains('depoimentos'));
    expect(result, contains('processo'));
    expect(result, contains('bio'));
    expect(result, contains('pacotes'));
    expect(result.indexOf('depoimentos'), lessThan(result.indexOf('processo')));
  });

  test('landingSectionLabel maps legacy keys to PT-BR', () {
    expect(landingSectionLabel('prova'), 'Depoimentos');
    expect(landingSectionLabel('metodo'), 'Como funciona');
    expect(landingSectionLabel('sobre'), 'Sobre você');
  });

  test('landingChecklistLabel humanizes backend jargon', () {
    expect(landingChecklistLabel('slug', 'Slug público'), 'Link público configurado');
    expect(landingChecklistLabel('cta', 'CTA principal'), 'Texto do botão principal definido');
    expect(landingChecklistLabel('captura', 'Modo Captura'), 'Formulário rápido disponível');
  });

  test('landingTextLooksLikePlaceholder detects test garbage', () {
    expect(landingTextLooksLikePlaceholder('dadsdad'), isTrue);
    expect(landingTextLooksLikePlaceholder('teste123'), isTrue);
    expect(landingTextLooksLikePlaceholder('Treino personalizado online'), isFalse);
  });

  test('landingContentWarnings flags placeholder FAQ', () {
    final warnings = landingContentWarnings(
      faq: [(pergunta: 'dadsdad', resposta: 'ok')],
      primaryCta: 'Agendar avaliação',
      heroTitle: 'Transforme seu corpo',
    );
    expect(warnings, isNotEmpty);
    expect(warnings.first, contains('Pergunta 1'));
  });
}
