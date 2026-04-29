import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('router keeps logged route aliases and fallback registered', () {
    final router = File('lib/core/router/app_router.dart').readAsStringSync();

    for (final path in [
      '/',
      '/home',
      '/dashboard',
      '/dashboard/home',
      '/dashboard/personal',
      '/dashboard/aluno',
      '/aluno',
      '/personal',
      '/ia',
      '/ia/copiloto',
    ]) {
      expect(router, contains("path: '$path'"));
    }

    expect(
      router,
      contains('errorBuilder: (context, state) => const HomeRedirectScreen()'),
    );
  });

  test('router protects direct opens that miss required extra payloads', () {
    final router = File('lib/core/router/app_router.dart').readAsStringSync();

    expect(router, contains("path: '/alunos/:id/editar'"));
    expect(router, contains("state.extra is Aluno"));
    expect(router, contains("path: '/perfil/editar'"));
    expect(router, contains("state.extra is PerfilPersonal"));
    expect(router, contains("path: '/checkin/executar'"));
    expect(router, contains("_treinoIdFromState(state) == null"));
    expect(router, contains("state.uri.queryParameters['treinoId']"));
    expect(router, contains("_stringExtra(state)"));

    expect(router, isNot(contains('state.extra as int')));
    expect(router, isNot(contains('state.extra as String?')));
  });
}
