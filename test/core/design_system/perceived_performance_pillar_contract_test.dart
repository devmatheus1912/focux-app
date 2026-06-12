import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/performance/focux_performance.dart';

import '../../support/screen_source_bundle.dart';

/// Pilar 12 — Performance percebida: skeleton, motion e transições nos hubs.
void main() {
  const hubScreens = [
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
    'lib/features/financeiro/screens/financeiro_screen.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart',
  ];

  test('performance catalog and automated gates exist', () {
    for (final path in FocuxPerformance.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    for (final path in FocuxPerformance.hubLoadingWidgets) {
      expect(File(path).existsSync(), isTrue, reason: 'Widget ausente: $path');
    }
    for (final path in FocuxPerformance.automatedGates) {
      expect(File(path).existsSync(), isTrue, reason: 'Gate ausente: $path');
    }
    expect(
      File('test/core/performance/motion_preferences_test.dart').existsSync(),
      isTrue,
    );
    expect(
      File('test/core/performance/focux_performance_test.dart').existsSync(),
      isTrue,
    );
  });

  test('DESIGN_SYSTEM documents perceived performance', () {
    final doc = File('docs/DESIGN_SYSTEM.md').readAsStringSync();
    expect(doc, contains('Performance percebida'));
    expect(doc, contains('FocuxPerformance'));
    expect(doc, contains('perceived_performance_pillar_contract_test'));
  });

  test('router uses fxTransitionPage for shell navigation', () {
    final router =
        File('lib/core/router/app_router_chrome_routes.dart').readAsStringSync();
    expect(router, contains('fx_page_transition.dart'));
    expect(router, contains('fxTransitionPage'));
  });

  test('hub screens use design-system loading UX', () {
    const financeiroTabs = [
      'lib/features/financeiro/screens/financeiro_dashboard_screen.dart',
      'lib/features/financeiro/screens/financeiro_resumo_screen.dart',
      'lib/features/financeiro/screens/financeiro_mensalidades_tab.dart',
    ];
    const alunoDetailWidgets = [
      'lib/features/alunos/widgets/aluno_detail_loading_skeleton.dart',
    ];

    for (final path in hubScreens) {
      expect(File(path).existsSync(), isTrue, reason: 'Hub ausente: $path');
      var source = readScreenSourceBundle(path);

      if (path.endsWith('financeiro_screen.dart')) {
        for (final tab in financeiroTabs) {
          source += File(tab).readAsStringSync();
        }
      }
      if (path.endsWith('aluno_detail_screen.dart')) {
        for (final widget in alunoDetailWidgets) {
          source += File(widget).readAsStringSync();
        }
      }

      final hasLoading = FocuxPerformance.hubLoadingPatterns
          .any((pattern) => source.contains(pattern));
      expect(
        hasLoading,
        isTrue,
        reason: '$path sem loading DS (skeleton/shimmer/FxLoading)',
      );
    }
  });

  test('hub screens respect or delegate reduced motion', () {
    const alunosStatePart =
        'lib/features/alunos/screens/alunos_list_screen_state.part.dart';
    const financeiroTabs = [
      'lib/features/financeiro/screens/financeiro_dashboard_screen.dart',
      'lib/features/financeiro/screens/financeiro_resumo_screen.dart',
    ];
    const iaWidgets = [
      'lib/features/ia/widgets/ia_copilot_insight_widgets.dart',
      'lib/features/ia/widgets/ia_expandable_copy.dart',
    ];

    String bundleFor(String path) {
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
        for (final widget in iaWidgets) {
          source += File(widget).readAsStringSync();
        }
      }
      return source;
    }

    for (final path in hubScreens) {
      final source = bundleFor(path);
      final hasMotion = FocuxPerformance.hubMotionPatterns
          .any((pattern) => source.contains(pattern));
      expect(
        hasMotion,
        isTrue,
        reason: '$path deve usar reduceMotion, FxStaggerItem ou transição',
      );
    }
  });

  test('features avoid raw CircularProgressIndicator', () {
    final failures = <String>[];
    final features = Directory('lib/features');
    for (final entity in features.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (source.contains('CircularProgressIndicator')) {
        failures.add(entity.path.replaceAll('\\', '/'));
      }
    }
    expect(
      failures,
      isEmpty,
      reason:
          'Use FxLoading em vez de CircularProgressIndicator: ${failures.join(", ")}',
    );
  });
}
