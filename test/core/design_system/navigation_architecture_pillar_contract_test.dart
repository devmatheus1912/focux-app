import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/navigation/focux_navigation.dart';

import '../../support/screen_source_bundle.dart' show readRouterSourceBundle, readScreenSourceBundle;

/// Pilar 14 — Navegação & arquitetura: GoRouter, safe_navigation e providers nos hubs.
void main() {
  const hubScreens = [
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
    'lib/features/financeiro/screens/financeiro_screen.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart',
  ];

  test('navigation catalog and automated gates exist', () {
    for (final path in FocuxNavigation.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    for (final path in FocuxNavigation.automatedGates) {
      expect(File(path).existsSync(), isTrue, reason: 'Gate ausente: $path');
    }
    expect(
      File('test/core/navigation/safe_navigation_test.dart').existsSync(),
      isTrue,
    );
    expect(
      File('test/core/navigation/focux_navigation_test.dart').existsSync(),
      isTrue,
    );
  });

  test('DESIGN_SYSTEM documents navigation architecture', () {
    final doc = File('docs/DESIGN_SYSTEM.md').readAsStringSync();
    expect(doc, contains('Navegação & arquitetura'));
    expect(doc, contains('FocuxNavigation'));
    expect(doc, contains('navigation_architecture_pillar_contract_test'));
  });

  test('hub screens use safe navigation and GoRouter', () {
    const alunosStatePart =
        'lib/features/alunos/screens/alunos_list_screen_state.part.dart';
    const alunosActionsPart =
        'lib/features/alunos/screens/alunos_list_screen_actions.part.dart';
    const iaParts = [
      'lib/features/ia/screens/ia_copiloto_screen_actions.part.dart',
    ];

    for (final path in hubScreens) {
      expect(File(path).existsSync(), isTrue, reason: 'Hub ausente: $path');
      var source = readScreenSourceBundle(path);

      if (path.endsWith('alunos_list_screen.dart')) {
        source += File(alunosStatePart).readAsStringSync();
        source += File(alunosActionsPart).readAsStringSync();
      }
      if (path.endsWith('ia_copiloto_screen.dart')) {
        for (final part in iaParts) {
          source += File(part).readAsStringSync();
        }
      }

      final hasNavigation = FocuxNavigation.hubNavigationPatterns
          .any((pattern) => source.contains(pattern));
      expect(
        hasNavigation,
        isTrue,
        reason: '$path deve usar safe_navigation ou GoRouter',
      );
    }
  });

  test('hub screens load data via providers', () {
    const alunosStatePart =
        'lib/features/alunos/screens/alunos_list_screen_state.part.dart';

    for (final path in hubScreens) {
      var source = readScreenSourceBundle(path);
      if (path.endsWith('alunos_list_screen.dart')) {
        source += File(alunosStatePart).readAsStringSync();
      }

      final usesProviders = FocuxNavigation.hubArchitecturePatterns
          .any((pattern) => source.contains(pattern));
      expect(
        usesProviders,
        isTrue,
        reason: '$path deve delegar estado a providers',
      );
    }
  });

  test('personal dashboard switches shell tabs via goPersonalShellTab', () {
    // Slivers extraídos carregam a navegação de tab da Home.
    final source =
        readScreenSourceBundle(
          'lib/features/dashboard/screens/personal_dashboard_screen.dart',
        ) +
        File(
          'lib/features/dashboard/widgets/dashboard_home_primary_slivers.dart',
        ).readAsStringSync();
    expect(source, contains('goPersonalShellTab'));
    expect(source, contains("'/alunos"));
    expect(source, contains("'/agenda'"));
  });

  test('hub screens avoid imperative Navigator.push routes', () {
    final failures = <String>[];

    for (final path in hubScreens) {
      final source = readScreenSourceBundle(path);
      if (source.contains('Navigator.push(') ||
          source.contains('MaterialPageRoute')) {
        failures.add(path);
      }
    }

    expect(
      failures,
      isEmpty,
      reason:
          'Hubs devem usar GoRouter (context.push/go): ${failures.join(", ")}',
    );
  });

  test('router registers shell tabs from FocuxNavigation catalog', () {
    final routes = readRouterSourceBundle();
    for (final tab in FocuxNavigation.shellTabPaths) {
      expect(routes, contains("path: '$tab'"), reason: 'Tab ausente: $tab');
    }
  });
}
