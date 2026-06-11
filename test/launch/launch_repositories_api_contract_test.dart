import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Launch modules must wire repositories to backend paths.
void main() {
  const launchModules = [
    'auth',
    'alunos',
    'treinos',
    'checkin',
    'financeiro',
    'chat',
    'ia',
    'leads',
    'captura',
    'convites',
    'perfil',
    'planos',
    'assinatura',
    'suporte',
    'onboarding',
    'agenda',
    'notificacoes',
  ];

  test('launch modules repositories call /api/', () {
    final failures = <String>[];

    for (final module in launchModules) {
      final dir = Directory('lib/features/$module');
      if (!dir.existsSync()) {
        failures.add('$module: diretorio ausente');
        continue;
      }

      final repos = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('_repository.dart'))
          .toList();

      if (repos.isEmpty) {
        failures.add('$module: sem repository');
        continue;
      }

      final anyHasApi = repos.any(
        (f) => f.readAsStringSync().contains('/api/'),
      );
      if (!anyHasApi) {
        failures.add('$module: nenhum repository com /api/');
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
