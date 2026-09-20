import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:focux_app/features/perfil/data/landing_studio_repository.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('ROI flow routes are registered in app router', () {
    final router = readRouterSourceBundle();

    expect(router, contains("path: '/dunning'"));
    expect(router, contains("path: '/winback'"));
    expect(router, contains("path: '/perfil/landing-editor'"));
    expect(router, contains("path: '/white-label'"));
  });

  test('White-label repository declares expected API paths', () {
    final whiteLabel =
        File('lib/features/perfil/data/white_label_repository.dart')
            .readAsStringSync();
    expect(whiteLabel, contains('/api/personal/white-label'));
    expect(whiteLabel, contains('/verificar-dominio'));
  });

  test('Landing studio repository declares v2 API paths', () {
    final landing =
        File('lib/features/perfil/data/landing_studio_repository.dart')
            .readAsStringSync();
    expect(landing, contains('/api/personal/landing'));
    expect(landing, contains('/api/personal/landing/entrevista'));
    expect(landing, contains('/api/personal/landing/gerar'));
    expect(landing, contains('/api/personal/landing/midia'));
    expect(landing, contains('/api/personal/landing/publicar'));
    expect(landing, contains('/api/personal/landing/preview'));
  });

  test('Landing studio models round-trip entrevista JSON', () {
    final entrevista = LandingEntrevista.fromJson({
      'nomeMarca': 'Marina Costa',
      'nicho': 'Hipertrofia online',
      'promessa': 'Método claro em 12 semanas',
      'ofertaNome': 'Programa 12 semanas',
      'cta': 'Quero minha avaliação',
      'duvidas': ['Serve para iniciante?', '', 'Como funciona?'],
      'whatsapp': '11999999999',
    });
    expect(entrevista.isReadyToGenerate, isTrue);
    expect(entrevista.duvidas, ['Serve para iniciante?', 'Como funciona?']);
    expect(entrevista.toJson()['nomeMarca'], 'Marina Costa');
  });

  test('Env uses dynamic public URLs not hardcoded focux.app in screens', () {
    final landingEditor = readScreenSourceBundle(
      'lib/features/perfil/screens/landing_editor_screen.dart',
    );
    final pacotes =
        File('lib/features/pacotes/screens/pacotes_screen.dart').readAsStringSync();
    expect(landingEditor, contains('Env.landingPageUrl'));
    expect(pacotes, isNot(contains('https://focux.app/p/')));
  });

  test('ROI repositories declare expected API paths', () {
    final winback =
        File('lib/features/winback/data/winback_repository.dart')
            .readAsStringSync();
    final dunning =
        File('lib/features/dunning/data/dunning_repository.dart')
            .readAsStringSync();

    expect(winback, contains('/api/winback/log'));
    expect(dunning, contains('/api/dunning/home'));
  });
}
