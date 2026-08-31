import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/a11y/focux_a11y.dart';

import '../../support/screen_source_bundle.dart';

/// Pilar 11 — Acessibilidade: escopo root, labels e hubs PT-BR.
void main() {
  const hubScreens = [
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
    'lib/features/financeiro/screens/financeiro_screen.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart',
  ];

  test('a11y catalog and automated gates exist', () {
    for (final path in FocuxA11y.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    for (final path in FocuxA11y.automatedGates) {
      expect(File(path).existsSync(), isTrue, reason: 'Gate ausente: $path');
    }
    expect(
      File('test/core/a11y/a11y_labels_test.dart').existsSync(),
      isTrue,
    );
  });

  test('DESIGN_SYSTEM documents accessibility', () {
    final doc = File('lib/core/design_system.dart').readAsStringSync();
    expect(doc, contains('Acessibilidade'));
    expect(doc, contains('FocuxA11y'));
    expect(doc, contains('accessibility_pillar_contract_test'));
  });

  test('manual trimestral documents TalkBack audit', () {
    final manual = File('lib/core/a11y/focux_a11y.dart').readAsStringSync();
    expect(manual, contains('TalkBack'));
    expect(manual, contains('VoiceOver'));
  });

  test('hub screens expose root a11y scope and labels', () {
    const alunoDetailWidgets = [
      'lib/features/alunos/widgets/aluno360_follow_up_card.dart',
      'lib/features/alunos/widgets/aluno_detail_hero_card.dart',
    ];

    for (final path in hubScreens) {
      expect(File(path).existsSync(), isTrue, reason: 'Hub ausente: $path');
      var source = readScreenSourceBundle(path);
      if (path.endsWith('aluno_detail_screen.dart')) {
        for (final widget in alunoDetailWidgets) {
          source += File(widget).readAsStringSync();
        }
      }

      final hasRootA11y = source.contains('fxScreenA11yScope') ||
          source.contains('Semantics(');
      expect(hasRootA11y, isTrue, reason: '$path sem escopo a11y root');

      final hasLabels = source.contains('Semantics(label:') ||
          source.contains('semanticsLabel:') ||
          source.contains('tooltip:') ||
          source.contains('dashboard_a11y') ||
          source.contains('aluno360_a11y') ||
          source.contains('label:');
      expect(hasLabels, isTrue, reason: '$path sem labels de controles');
    }
  });

  test('personal dashboard uses dashboard_a11y helpers', () {
    final source = readScreenSourceBundle(
      'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    );
    expect(source, contains('fxScreenA11yScope'));

    // Helpers de a11y vivem nos widgets extraídos da Home.
    const dashboardWidgets = [
      'lib/features/dashboard/widgets/dashboard_tool_shortcut_group.dart',
      'lib/features/dashboard/widgets/dashboard_attention_rail.dart',
    ];
    for (final path in dashboardWidgets) {
      expect(
        File(path).readAsStringSync(),
        contains('dashboard_a11y'),
        reason: '$path deve usar dashboard_a11y helpers',
      );
    }
  });

  test('aluno 360 module exposes dedicated a11y labels', () {
    expect(
      File('lib/features/alunos/utils/aluno360_a11y.dart').existsSync(),
      isTrue,
    );
    final widgets = [
      'lib/features/alunos/widgets/aluno360_follow_up_card.dart',
    ];
    for (final path in widgets) {
      final source = File(path).readAsStringSync();
      expect(source, contains('aluno360_a11y'));
    }
  });

  test('a11y announce helper exists for screen reader updates', () {
    final source = File('lib/core/utils/a11y_announce.dart').readAsStringSync();
    expect(source, contains('fxAnnounce'));
    expect(source, contains('SemanticsService.sendAnnouncement'));
  });
}
