import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/motion/focux_motion.dart';

import '../../support/screen_source_bundle.dart';

/// Pilar 15 — Motion design: stagger, spring, reduced motion nos hubs.
void main() {
  const hubScreens = [
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
    'lib/features/financeiro/screens/financeiro_screen.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart',
  ];

  test('motion catalog and automated gates exist', () {
    for (final path in FocuxMotion.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    for (final path in FocuxMotion.automatedGates) {
      expect(File(path).existsSync(), isTrue, reason: 'Gate ausente: $path');
    }
    expect(
      File('test/core/motion/focux_motion_test.dart').existsSync(),
      isTrue,
    );
  });

  test('DESIGN_SYSTEM documents motion design', () {
    final doc = File('lib/core/design_system.dart').readAsStringSync();
    expect(doc, contains('Motion design'));
    expect(doc, contains('FocuxMotion'));
    expect(doc, contains('motion_design_pillar_contract_test'));
  });

  test('fx_motion implements catalog widgets with reduced motion', () {
    final source = File('lib/core/widgets/fx_motion.dart').readAsStringSync();
    for (final widget in FocuxMotion.motionWidgets) {
      expect(source, contains(widget));
    }
    expect(source, contains('reduceMotionOf'));
    expect(source, contains('Curves.easeOutCubic'));
  });

  test('hub screens use design-system motion patterns', () {
    const alunosStatePart =
        'lib/features/alunos/screens/alunos_list_screen_state.part.dart';
    const alunosActionsPart =
        'lib/features/alunos/screens/alunos_list_screen_actions.part.dart';
    const dashboardMotion = [
      'lib/features/dashboard/utils/dashboard_entry_motion.dart',
    ];

    for (final path in hubScreens) {
      expect(File(path).existsSync(), isTrue, reason: 'Hub ausente: $path');
      var source = readScreenSourceBundle(path);

      if (path.endsWith('alunos_list_screen.dart')) {
        source += File(alunosStatePart).readAsStringSync();
        source += File(alunosActionsPart).readAsStringSync();
      }
      if (path.endsWith('personal_dashboard_screen.dart')) {
        for (final extra in dashboardMotion) {
          source += File(extra).readAsStringSync();
        }
      }

      final hasMotion = FocuxMotion.hubMotionPatterns
          .any((pattern) => source.contains(pattern));
      expect(
        hasMotion,
        isTrue,
        reason: '$path deve usar widgets/helpers de motion Fx',
      );
    }
  });

  test('hub bundles with AnimationController respect reduced motion', () {
    const hubBundles = [
      'lib/features/dashboard/screens/personal_dashboard_screen.dart',
      'lib/features/alunos/screens/aluno_detail_screen.dart',
      'lib/features/alunos/screens/alunos_list_screen.dart',
      'lib/features/treinos/screens/treinos_list_screen.dart',
      'lib/features/financeiro/screens/financeiro_screen.dart',
      'lib/features/ia/screens/ia_copiloto_screen.dart',
    ];
    const alunosStatePart =
        'lib/features/alunos/screens/alunos_list_screen_state.part.dart';

    final failures = <String>[];
    for (final path in hubBundles) {
      var source = readScreenSourceBundle(path);
      if (path.endsWith('alunos_list_screen.dart')) {
        source += File(alunosStatePart).readAsStringSync();
      }
      if (!source.contains('AnimationController')) continue;

      final respectsMotion = source.contains('motion_preferences.dart') ||
          source.contains('tokens_strip.dart') ||
          source.contains('dashboard_entry_motion.dart') ||
          source.contains('fx_motion.dart') ||
          source.contains('reduceMotionOf') ||
          source.contains('prefersReducedMotion');
      if (!respectsMotion) {
        failures.add(path);
      }
    }

    expect(
      failures,
      isEmpty,
      reason:
          'Hubs com AnimationController devem respeitar reduced motion: ${failures.join(", ")}',
    );
  });

  test('page transitions use fxTransitionPage with motion guard', () {
    final router =
        File('lib/core/router/app_router_chrome_routes.dart').readAsStringSync();
    final transition =
        File('lib/core/router/fx_page_transition.dart').readAsStringSync();
    expect(router, contains('fxTransitionPage'));
    expect(transition, contains('reduceMotionOf'));
    expect(
      transition,
      contains('Duration(milliseconds: ${FocuxMotion.pageTransitionMs})'),
    );
  });
}
