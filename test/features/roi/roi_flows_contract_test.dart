import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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

  test('Landing growth repository declares expected API paths', () {
    final landing =
        File('lib/features/perfil/data/landing_growth_repository.dart')
            .readAsStringSync();
    expect(landing, contains('/api/personal/landing/presets'));
    expect(landing, contains('/api/personal/landing/gerar-hero'));
    expect(landing, contains('/api/personal/landing/checklist'));
  });

  test('Env uses dynamic public URLs not hardcoded focux.app in screens', () {
    final landingEditor =
        File('lib/features/perfil/screens/landing_editor_screen.dart')
            .readAsStringSync();
    final pacotes =
        File('lib/features/pacotes/screens/pacotes_screen.dart').readAsStringSync();
    expect(landingEditor, contains('Env.landingPageUrl'));
    expect(landingEditor, contains('Env.capturaPageUrl'));
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
    expect(dunning, contains('/api/dunning/me'));
    expect(dunning, contains('/api/dunning/falhas'));
  });
}
