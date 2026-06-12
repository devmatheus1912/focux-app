import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pilar 1 — Produtividade: gates, polish tests e CI devem estar completos.
void main() {
  const designGates = [
    'test/core/design_system/features_color_tokens_contract_test.dart',
    'test/core/design_system/screen_tier_s_plus_contract_test.dart',
    'test/core/design_system/screen_a11y_contract_test.dart',
    'test/core/design_system/a11y_controls_contract_test.dart',
    'test/core/design_system/eagle_design_contract_test.dart',
    'test/core/design_system/design_system_pillar_contract_test.dart',
    'test/core/design_system/typography_pillar_contract_test.dart',
    'test/core/design_system/spacing_layout_pillar_contract_test.dart',
    'test/core/design_system/colors_contrast_pillar_contract_test.dart',
    'test/core/design_system/visual_hierarchy_pillar_contract_test.dart',
    'test/core/design_system/productivity_gates_contract_test.dart',
    'test/core/router/routes_pillar_contract_test.dart',
    'test/core/business_logic/business_logic_contract_test.dart',
  ];

  const excludedScreens = {
    'lib/features/qa/screens/qa_smoke_screen.dart',
    'lib/features/qa/screens/tokens_strip_showcase_screen.dart',
  };

  const requiredWorkflowSnippets = [
    'flutter test',
    'dart analyze',
    'find_orphan_dart',
  ];

  test('design system gate files exist', () {
    for (final path in designGates) {
      expect(File(path).existsSync(), isTrue, reason: 'Gate ausente: $path');
    }
  });

  test('every production screen has polish test', () {
    final screens = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_screen.dart'))
        .map((f) {
          final p = f.path.replaceAll(r'\', '/');
          return p.substring(p.indexOf('lib/'));
        })
        .where((p) => !excludedScreens.contains(p))
        .toList();

    final missing = <String>[];
    for (final screen in screens) {
      final stem = screen.split('/').last.replaceAll('_screen.dart', '');
      final module = screen.split('/')[2];
      final polish = 'test/features/$module/${stem}_screen_polish_test.dart';
      if (!File(polish).existsSync()) {
        missing.add('$screen → esperado $polish');
      }
    }

    expect(
      missing,
      isEmpty,
      reason: 'Telas sem polish test:\n${missing.join('\n')}',
    );
  });

  test('CI workflow analyze.yml runs full verification', () {
    final workflow = File('.github/workflows/analyze.yml');
    expect(workflow.existsSync(), isTrue);
    final content = workflow.readAsStringSync();
    for (final snippet in requiredWorkflowSnippets) {
      expect(content, contains(snippet), reason: 'analyze.yml sem: $snippet');
    }
  });

  test('security and semgrep workflows exist', () {
    expect(File('.github/workflows/security.yml').existsSync(), isTrue);
    expect(File('.github/workflows/semgrep.yml').existsSync(), isTrue);
  });

  test('verify script exists in repo', () {
    expect(File('tool/verify.ps1').existsSync(), isTrue);
  });

  test('AUDIT.md documents productivity gates', () {
    final audit = File('AUDIT.md').readAsStringSync();
    expect(audit, contains('flutter test'));
    expect(audit, contains('Tier S+'));
  });
}
