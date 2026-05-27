import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ROI flow routes are registered in app router', () {
    final router = File('lib/core/router/app_router.dart').readAsStringSync();

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
