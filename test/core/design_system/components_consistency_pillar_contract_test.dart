import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/focux_components.dart';

import '../../support/screen_source_bundle.dart';

/// Pilar 9 — Componentes & consistência: catálogo Fx e hubs alinhados.
void main() {
  const hubScreens = [
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
    'lib/features/financeiro/screens/financeiro_screen.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart',
  ];

  test('component catalog and anti-pattern gates exist', () {
    expect(
      File('lib/core/widgets/focux_components.dart').existsSync(),
      isTrue,
    );
    expect(
      File('test/core/widgets/focux_components_test.dart').existsSync(),
      isTrue,
    );
    expect(
      File('test/core/design_system/eagle_design_contract_test.dart').existsSync(),
      isTrue,
    );
    for (final path in FocuxComponents.catalogPaths) {
      expect(File(path).existsSync(), isTrue, reason: 'Fx ausente: $path');
    }
  });

  test('DESIGN_SYSTEM documents components and consistency', () {
    final doc = File('lib/core/design_system.dart').readAsStringSync();
    expect(doc, contains('Componentes & consistência'));
    expect(doc, contains('FocuxComponents'));
    expect(doc, contains('components_consistency_pillar_contract_test'));
  });

  test('minimum Fx core widget catalog', () {
    final fxWidgets = Directory('lib/core/widgets')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.replaceAll(r'\', '/').contains('/fx_'))
        .length;
    expect(fxWidgets, greaterThanOrEqualTo(FocuxComponents.minimumFxWidgets));
  });

  test('showcase documents Fx components', () {
    final showcase = File(
      'lib/features/qa/screens/tokens_strip_showcase_screen.dart',
    ).readAsStringSync();
    expect(showcase, contains('FxShellScaffold'));
    expect(showcase, contains('FxLoading'));
  });

  test('hub screens use a11y scope and Fx catalog components', () {
    for (final path in hubScreens) {
      expect(File(path).existsSync(), isTrue, reason: 'Hub ausente: $path');
      final source = readScreenSourceBundle(path);

      final hasA11yRoot = source.contains('fxScreenA11yScope') ||
          source.contains('Semantics(');
      expect(hasA11yRoot, isTrue, reason: '$path sem root a11y');

      final usesFxComponent = FocuxComponents.hubPatterns
          .any((pattern) => source.contains(pattern));
      expect(
        usesFxComponent,
        isTrue,
        reason: '$path deve usar componentes do catálogo Fx',
      );
    }
  });

  test('features avoid raw ScaffoldMessenger for feedback', () {
    final failures = <String>[];
    for (final file in Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final path = file.path.replaceAll(r'\', '/');
      final norm = path.substring(path.indexOf('lib/'));
      if (norm.startsWith('lib/features/qa/')) continue;

      if (file.readAsStringSync().contains('ScaffoldMessenger.of')) {
        failures.add(norm);
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
