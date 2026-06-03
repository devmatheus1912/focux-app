import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/screen_source_bundle.dart';

/// Launch gate for PT-only v1 — ensures every revenue-critical module ships wired.
void main() {
  const launchModules = {
    'auth': '/login',
    'alunos': '/alunos',
    'treinos': '/treinos',
    'checkin': '/checkin/treinos',
    'financeiro': '/financeiro',
    'chat': '/chat/inbox',
    'ia': '/ia/copiloto',
    'leads': '/leads',
    'captura': '/leads-publicos',
    'convites': '/convites',
    'perfil': '/perfil',
    'planos': '/planos',
    'assinatura': '/assinatura',
    'suporte': '/suporte',
    'onboarding': '/onboarding',
    'agenda': '/agenda',
    'notificacoes': '/notificacoes',
  };

  test('launch modules have repository + route registered', () {
    final routes = readRouterSourceBundle();

    for (final entry in launchModules.entries) {
      final moduleDir = Directory('lib/features/${entry.key}');
      expect(
        moduleDir.existsSync(),
        isTrue,
        reason: 'modulo ${entry.key} ausente',
      );

      final hasApiLayer = moduleDir
          .listSync(recursive: true)
          .whereType<File>()
          .any((f) => f.path.contains('_repository.dart'));

      expect(
        hasApiLayer,
        isTrue,
        reason: '${entry.key} precisa de camada data/repository',
      );

      expect(
        routes,
        contains("path: '${entry.value}'"),
        reason: 'rota ${entry.value} nao registrada',
      );
    }

    final perfilRepo =
        File('lib/features/perfil/data/white_label_repository.dart');
    expect(perfilRepo.existsSync(), isTrue);
    expect(routes, contains("path: '/white-label'"));
  });

  test('PT-only launch surfaces exist', () {
    final mainDart = File('lib/main.dart').readAsStringSync();
    final indexHtml = File('web/index.html').readAsStringSync();
    final manifest = File('web/manifest.json').readAsStringSync();

    expect(mainDart, contains("locale: const Locale('pt', 'BR')"));
    expect(indexHtml, contains('Focux Personal'));
    expect(manifest, contains('Focux Personal'));
    expect(File('deploy.bat').existsSync(), isTrue);
    expect(File('scripts/deploy-vercel.ps1').existsSync(), isTrue);
    expect(File('vercel.json').existsSync(), isTrue);
  });
}
