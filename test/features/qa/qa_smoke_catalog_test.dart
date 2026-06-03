import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/qa/data/qa_smoke_catalog.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('QA smoke catalog covers critical public and logged routes', () {
    final ids = qaSmokeRoutes.map((route) => route.id).toSet();

    expect(ids.length, qaSmokeRoutes.length);
    expect(ids, containsAll([
      'public-login',
      'public-login-from-financeiro',
      'public-student-register',
      'personal-home',
      'personal-financeiro',
      'personal-chat',
      'personal-copilot',
      'personal-notifications',
      'student-home',
      'student-workouts',
    ]));

    // Fase 1: expanded coverage
    expect(qaSmokeRoutes.length, greaterThanOrEqualTo(30),
        reason: 'Catalog must cover at least 30 routes');
    expect(qaPublicRoutes.length, greaterThanOrEqualTo(6));
    expect(qaPrivateRoutes.length, greaterThanOrEqualTo(20));

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
    final routes = readRouterSourceBundle();

    final redirect =
        File('lib/core/router/app_router_redirect.dart').readAsStringSync();

    for (final route in qaSmokeRoutes) {
      final cleanPath = route.path.split('?').first;
      expect(
        routes,
        contains("path: '$cleanPath'"),
        reason: '${route.id} precisa continuar registrado no router.',
      );
    }

    expect(redirect, contains('Future<String?> authRedirect'));
    expect(
      redirect,
      contains("return from.isEmpty ? '/login' : '/login?from=\$from'"),
    );
  });

  test('QA smoke catalog keeps public and private route boundaries explicit', () {
    final redirect =
        File('lib/core/router/app_router_redirect.dart').readAsStringSync();

    for (final route in qaPublicRoutes) {
      final cleanPath = route.path.split('?').first;
      expect(
        redirect,
        contains("path == '$cleanPath'"),
        reason: '${route.id} precisa permanecer publico para smoke sem token.',
      );
    }

    for (final route in qaPrivateRoutes) {
      expect(
        redirect,
        isNot(contains("path == '${route.path.split('?').first}'")),
        reason: '${route.id} nao pode entrar na lista publica sem token.',
      );
    }
  });

  test('QA smoke endpoint catalog covers production readiness and protected APIs', () {
    final ids = qaSmokeEndpoints.map((endpoint) => endpoint.id).toSet();

    expect(ids.length, qaSmokeEndpoints.length);
    // Fase 1: expanded endpoint coverage
    expect(qaSmokeEndpoints.length, greaterThanOrEqualTo(25),
        reason: 'Must cover at least 25 API endpoints');
    expect(ids, containsAll([
      'health',
      'auth-capabilities',
      'auth-environment',
      'profile',
      'dashboard-home',
      'notifications',
      'workouts',
      'exercises',
      // Fase 1 new routes
      'chat-inbox',
      'chat-inbox-search',
      'feed-list',
      'planos-me',
      'qualidade',
      'onboarding-status',
      'backup-create',
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

  test('Fase 1: QA catalog has no duplicate IDs', () {
    final routeIds = qaSmokeRoutes.map((r) => r.id).toList();
    expect(routeIds.toSet().length, routeIds.length,
        reason: 'Route IDs must be unique');

    final endpointIds = qaSmokeEndpoints.map((e) => e.id).toList();
    expect(endpointIds.toSet().length, endpointIds.length,
        reason: 'Endpoint IDs must be unique');
  });

  test('Fase 1: Every module area has at least one route or endpoint', () {
    final areas = <String>{};
    for (final r in qaSmokeRoutes) {
      areas.add(r.area);
    }
    for (final e in qaSmokeEndpoints) {
      areas.add(e.area);
    }

    expect(areas, containsAll([
      'auth', 'personal', 'alunos', 'treinos', 'financeiro',
      'chat', 'ia', 'feed', 'growth', 'notificacoes',
    ]));
  });
}
