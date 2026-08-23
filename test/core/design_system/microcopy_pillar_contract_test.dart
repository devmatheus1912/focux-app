import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/brand/focux_microcopy.dart';

import '../../support/screen_source_bundle.dart';

/// Pilar 13 — Microcopy / UX writing: PT-BR centralizado nos hubs.
void main() {
  const hubScreens = [
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
    'lib/features/financeiro/screens/financeiro_screen.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart',
  ];

  final englishUx = RegExp(
    r'''['"](Loading|Error|Retry|Save|Cancel|Submit|Delete|Try again)['"]''',
  );

  test('microcopy catalog and tests exist', () {
    for (final path in FocuxMicrocopy.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    for (final path in FocuxMicrocopy.automatedGates) {
      expect(File(path).existsSync(), isTrue, reason: 'Gate ausente: $path');
    }
    expect(
      File('test/core/ux/focux_microcopy_test.dart').existsSync(),
      isTrue,
    );
  });

  test('DESIGN_SYSTEM documents microcopy', () {
    final doc = File('docs/DESIGN_SYSTEM.md').readAsStringSync();
    expect(doc, contains('Microcopy'));
    expect(doc, contains('FocuxMicrocopy'));
    expect(doc, contains('microcopy_pillar_contract_test'));
  });

  test('hub screens use centralized copy and friendly errors', () {
    const financeiroTabs = [
      'lib/features/financeiro/screens/financeiro_dashboard_screen.dart',
      'lib/features/financeiro/screens/financeiro_resumo_screen.dart',
    ];
    const alunosStatePart =
        'lib/features/alunos/screens/alunos_list_screen_state.part.dart';
    const alunosActionsPart =
        'lib/features/alunos/screens/alunos_list_screen_actions.part.dart';
    const iaParts = [
      'lib/features/ia/screens/ia_copiloto_screen_actions.part.dart',
    ];
    const dashboardWidgets = [
      'lib/features/dashboard/widgets/dashboard_error_state.dart',
      'lib/features/dashboard/utils/dashboard_microcopy.dart',
    ];

    for (final path in hubScreens) {
      expect(File(path).existsSync(), isTrue, reason: 'Hub ausente: $path');
      var source = readScreenSourceBundle(path);

      if (path.endsWith('financeiro_screen.dart')) {
        for (final tab in financeiroTabs) {
          source += File(tab).readAsStringSync();
        }
      }
      if (path.endsWith('alunos_list_screen.dart')) {
        source += File(alunosStatePart).readAsStringSync();
        source += File(alunosActionsPart).readAsStringSync();
        source += File(
          'lib/features/alunos/widgets/alunos_error_scaffold.dart',
        ).readAsStringSync();
      }
      if (path.endsWith('ia_copiloto_screen.dart')) {
        for (final part in iaParts) {
          source += File(part).readAsStringSync();
        }
      }
      if (path.endsWith('personal_dashboard_screen.dart')) {
        for (final widget in dashboardWidgets) {
          source += File(widget).readAsStringSync();
        }
      }

      final usesCopy = FocuxMicrocopy.hubCopyPatterns
          .any((pattern) => source.contains(pattern));
      expect(
        usesCopy,
        isTrue,
        reason: '$path deve usar FocuxMicrocopy ou utils de módulo',
      );

      expect(
        source.contains('friendlyError'),
        isTrue,
        reason: '$path deve humanizar erros com friendlyError',
      );

      // Retry canônico: label direto ou delegação ao FxErrorState (que usa
      // FocuxMicrocopy.tentarNovamente internamente — coberto no teste abaixo).
      expect(
        source.contains('FocuxMicrocopy.tentarNovamente') ||
            source.contains('FxErrorState('),
        isTrue,
        reason: '$path deve usar FocuxMicrocopy.tentarNovamente ou FxErrorState',
      );
    }
  });

  test('hub screens avoid English UX literals', () {
    const bundles = [
      ...hubScreens,
      'lib/features/dashboard/widgets/dashboard_error_state.dart',
    ];

    final failures = <String>[];
    for (final path in bundles) {
      if (!File(path).existsSync()) continue;
      final source = readScreenSourceBundle(path);
      if (englishUx.hasMatch(source)) {
        failures.add(path);
      }
    }

    expect(
      failures,
      isEmpty,
      reason: 'Microcopy deve ser PT-BR nos hubs: ${failures.join(", ")}',
    );
  });

  test('error states use FocuxMicrocopy retry label', () {
    // Fonte da verdade do retry — o widget canônico usa o label central.
    final fxErrorState = File(
      'lib/core/widgets/fx_error_state.dart',
    ).readAsStringSync();
    expect(fxErrorState, contains('FocuxMicrocopy.tentarNovamente'));

    const errorWidgets = [
      'lib/features/dashboard/widgets/dashboard_error_state.dart',
    ];

    for (final path in errorWidgets) {
      final source = File(path).readAsStringSync();
      expect(
        source.contains('FocuxMicrocopy.tentarNovamente') ||
            source.contains('FxErrorState('),
        isTrue,
        reason: '$path deve usar label central ou delegar ao FxErrorState',
      );
    }
  });
}
