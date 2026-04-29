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
}
