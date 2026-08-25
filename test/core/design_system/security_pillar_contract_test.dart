import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/security/focux_security.dart';

import '../../support/screen_source_bundle.dart';

/// Pilar 21 — Segurança: tokens, erros seguros e disclaimers nos hubs.
void main() {
  const hubScreens = [
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
    'lib/features/financeiro/screens/financeiro_screen.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart',
  ];

  test('security catalog and automated gates exist', () {
    for (final path in FocuxSecurity.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    for (final path in FocuxSecurity.automatedGates) {
      if (path.startsWith('.')) {
        expect(File(path).existsSync(), isTrue, reason: 'Gate ausente: $path');
      } else {
        expect(File(path).existsSync(), isTrue, reason: 'Gate ausente: $path');
      }
    }
    expect(
      File('test/core/security/focux_security_test.dart').existsSync(),
      isTrue,
    );
    expect(
      File('test/core/security/platform_hardening_test.dart').existsSync(),
      isTrue,
    );
    for (final path in FocuxSecurity.androidHardeningSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Artefato ausente: $path');
    }
  });

  test('security reference documents FocuxSecurity catalog', () {
    const candidates = [
      'lib/core/design_system.dart',
      'lib/core/security/focux_security.dart',
      '../docs/PERFIL_DESIGN_REFERENCE.md',
    ];
    File? docFile;
    for (final path in candidates) {
      final file = File(path);
      if (file.existsSync()) {
        docFile = file;
        break;
      }
    }
    if (docFile == null) {
      // Checkout isolado de focux-app — coberto no monorepo via platform_hardening_test.
      return;
    }
    final doc = docFile.readAsStringSync();
    expect(doc, contains('FocuxSecurity'));
    expect(doc, contains('security_pillar_contract_test'));
    expect(doc, contains('Hardening mobile & web'));
  });

  test('hub screens handle errors safely and expose async guards', () {
    const alunosStatePart =
        'lib/features/alunos/screens/alunos_list_screen_state.part.dart';
    const financeiroTabs = [
      'lib/features/financeiro/screens/financeiro_dashboard_screen.dart',
      'lib/features/financeiro/screens/financeiro_mensalidades_tab.dart',
      'lib/features/financeiro/screens/financeiro_mensalidades_tab_actions.part.dart',
    ];
    const iaParts = [
      'lib/features/ia/screens/ia_copiloto_screen_actions.part.dart',
      'lib/features/ia/widgets/ia_copilot_insight_widgets.dart',
    ];

    for (final path in hubScreens) {
      expect(File(path).existsSync(), isTrue, reason: 'Hub ausente: $path');
      var source = readScreenSourceBundle(path);

      if (path.endsWith('alunos_list_screen.dart')) {
        source += File(alunosStatePart).readAsStringSync();
      }
      if (path.endsWith('financeiro_screen.dart')) {
        for (final tab in financeiroTabs) {
          source += File(tab).readAsStringSync();
        }
      }
      if (path.endsWith('ia_copiloto_screen.dart')) {
        for (final part in iaParts) {
          source += File(part).readAsStringSync();
        }
        source += File('lib/core/widgets/ia_safety_disclaimer.dart')
            .readAsStringSync();
      }

      final secured = FocuxSecurity.hubSecurityPatterns
          .any((pattern) => source.contains(pattern));
      expect(
        secured,
        isTrue,
        reason: '$path deve usar friendlyError, FeedbackHelper ou .when',
      );

      for (final forbidden in FocuxSecurity.forbiddenHubPatterns) {
        expect(
          source.contains(forbidden),
          isFalse,
          reason: '$path não deve conter padrão inseguro: $forbidden',
        );
      }
    }
  });

  test('auth redirect uses SecureStorage not shared prefs in router', () {
    final redirect =
        File('lib/core/router/app_router_redirect.dart').readAsStringSync();
    expect(redirect, contains('SecureStorage.getToken'));
    expect(redirect, contains('SecureStorage.getRole'));
  });

  test('api client attaches bearer token and supports refresh invalidation', () {
    final api = File('lib/core/api/api_client.dart').readAsStringSync();
    expect(api, contains("headers['Authorization'] = 'Bearer"));
    expect(api, contains('SessionInvalidator'));

    final invalidator =
        File('lib/core/auth/session_invalidator.dart').readAsStringSync();
    expect(invalidator, contains('SecureStorage.clearAll'));
  });

  test('ia screens include safety disclaimer widget', () {
    final disclaimer =
        File('lib/core/widgets/ia_safety_disclaimer.dart').readAsStringSync();
    expect(disclaimer, contains('IaSafetyDisclaimer'));
    expect(disclaimer, contains('profissional'));
  });
}
