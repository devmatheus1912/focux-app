import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

/// Pilar 2 — Rotas: catálogo documentado existe no router e deep links críticos.
void main() {
  const shellTabs = [
    '/dashboard/personal',
    '/alunos',
    '/treinos',
    '/agenda',
    '/ia/copiloto',
  ];

  const personalDeepLinks = [
    '/alunos/novo',
    '/alunos/acoes-massa',
    '/alunos/:id/equipamentos',
    '/alunos/:id/editar',
    '/alunos/:id/chat',
    '/treinos/novo',
    '/financeiro',
    '/chat/inbox',
    '/alertas',
    '/paywall',
    '/assinatura',
  ];

  const alunoDeepLinks = [
    '/dashboard/aluno',
    '/checkin/treinos',
    '/checkin/executar',
    '/feed/aluno',
    '/financeiro/aluno',
  ];

  const publicRoutes = [
    '/login',
    '/register',
    '/register/aluno',
    '/onboarding',
    '/esqueci-senha',
    '/resetar-senha',
  ];

  test('shell tabs registered in router', () {
    final routes = readRouterSourceBundle();
    for (final path in shellTabs) {
      expect(routes, contains("path: '$path'"), reason: 'Tab ausente: $path');
    }
  });

  test('personal deep links registered', () {
    final routes = readRouterSourceBundle();
    for (final path in personalDeepLinks) {
      expect(routes, contains("path: '$path'"), reason: 'Rota ausente: $path');
    }
  });

  test('aluno deep links registered', () {
    final routes = readRouterSourceBundle();
    for (final path in alunoDeepLinks) {
      expect(routes, contains("path: '$path'"), reason: 'Rota aluno ausente: $path');
    }
  });

  test('public routes whitelisted in redirect', () {
    final redirect =
        File('lib/core/router/app_router_redirect.dart').readAsStringSync();
    for (final path in publicRoutes) {
      expect(redirect, contains("path == '$path'"));
    }
  });

  test('checkin deep link supports treinoId query param', () {
    final routes = readRouterSourceBundle();
    expect(routes, contains("path: '/checkin/executar'"));
    expect(routes, contains("state.uri.queryParameters['treinoId']"));
  });

  test('README route catalog file exists', () {
    expect(File('README.md').existsSync(), isTrue);
    final readme = File('README.md').readAsStringSync();
    expect(readme, contains('/alunos/:id/equipamentos'));
    expect(readme, contains('/ia/copiloto'));
  });
}
