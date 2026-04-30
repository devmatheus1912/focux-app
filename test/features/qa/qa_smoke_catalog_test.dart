import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/qa/data/qa_smoke_catalog.dart';

void main() {
  test('QA smoke catalog covers critical public and logged routes', () {
    final ids = qaSmokeRoutes.map((route) => route.id).toSet();

    expect(ids.length, qaSmokeRoutes.length);
    expect(ids, containsAll([
      'public-login',
      'public-login-from-financeiro',
      'public-student-register',
      'public-landing',
      'personal-home',
      'personal-financeiro',
      'personal-chat',
      'personal-copilot',
      'personal-notifications',
      'student-home',
      'student-workouts',
    ]));

    expect(qaPublicRoutes.length, greaterThanOrEqualTo(6));
    expect(qaPrivateRoutes.length, greaterThanOrEqualTo(6));

    for (final route in qaPrivateRoutes) {
      expect(
        route.expectedAnonymousRedirect,
        isNotNull,
        reason: '${route.id} precisa declarar o redirect anonimo esperado.',
      );
      expect(route.expectedAnonymousRedirect, startsWith('/login?from='));
    }
  });

  test('QA smoke catalog routes stay registered in GoRouter', () {
    final router = File('lib/core/router/app_router.dart').readAsStringSync();

    for (final route in qaSmokeRoutes) {
      final cleanPath = route.path.split('?').first;
      final registeredPath = cleanPath.startsWith('/p/')
          ? '/p/:slug'
          : cleanPath;
      expect(
        router,
        contains("path: '$registeredPath'"),
        reason: '${route.id} precisa continuar registrado no router.',
      );
    }

    expect(router, contains('Future<String?> _authRedirect'));
    expect(
      router,
      contains("return from.isEmpty ? '/login' : '/login?from=\$from'"),
    );
  });

  test('QA smoke catalog keeps public and private route boundaries explicit', () {
    final router = File('lib/core/router/app_router.dart').readAsStringSync();

    for (final route in qaPublicRoutes) {
      final cleanPath = route.path.split('?').first;
      if (cleanPath.startsWith('/p/')) {
        expect(router, contains("path.startsWith('/p/')"));
      } else {
        expect(
          router,
          contains("path == '$cleanPath'"),
          reason: '${route.id} precisa permanecer publico para smoke sem token.',
        );
      }
    }

    for (final route in qaPrivateRoutes) {
      expect(
        router,
        isNot(contains("path == '${route.path.split('?').first}'")),
        reason: '${route.id} nao pode entrar na lista publica sem token.',
      );
    }
  });

  test('QA smoke endpoint catalog covers production readiness and protected APIs', () {
    final ids = qaSmokeEndpoints.map((endpoint) => endpoint.id).toSet();

    expect(ids.length, qaSmokeEndpoints.length);
    expect(ids, containsAll([
      'health',
      'auth-capabilities',
      'auth-environment',
      'public-landing',
      'public-landing-event',
      'profile',
      'command-center',
      'notifications',
      'workouts',
      'exercises',
    ]));

    for (final endpoint in qaPublicEndpoints) {
      expect(endpoint.expectedAnonymousStatus, anyOf(200, 404));
    }

    for (final endpoint
        in qaSmokeEndpoints.where((endpoint) => !endpoint.isPublic)) {
      expect(endpoint.expectedAnonymousStatus, 403);
      expect(endpoint.path, startsWith('/api/'));
    }
  });
}
