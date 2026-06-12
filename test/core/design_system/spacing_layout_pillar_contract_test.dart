import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

/// Pilar 6 — Espaçamento & layout: grade 8pt, limiter e tokens por hub.
void main() {
  const spacingSources = [
    'lib/core/theme/focux_spacing.dart',
    'lib/core/theme/tokens_strip.dart',
    'lib/core/theme/design_tokens.dart',
    'lib/core/widgets/fx_content_width_limiter.dart',
  ];

  const moduleLayouts = [
    'lib/features/alunos/constants/aluno_360_layout.dart',
    'lib/features/dashboard/constants/dashboard_layout.dart',
  ];

  const hubScreens = [
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
    'lib/features/financeiro/screens/financeiro_screen.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart',
  ];

  final scaleSteps = {4.0, 8.0, 12.0, 16.0, 24.0, 32.0, 48.0, 64.0, 80.0};

  final magicSizedBox = RegExp(
    r'SizedBox\(\s*(?:height|width):\s*(\d+(?:\.\d+)?)\s*\)',
  );

  test('spacing and layout source files exist', () {
    for (final path in spacingSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    for (final path in moduleLayouts) {
      expect(File(path).existsSync(), isTrue, reason: 'Layout ausente: $path');
    }
  });

  test('TokensStrip 8pt grid and Eagle radius scale defined', () {
    final strip = File('lib/core/theme/tokens_strip.dart').readAsStringSync();
    for (final step in ['s1', 's2', 's3', 's4', 's5', 's6', 's7', 's8', 's9']) {
      expect(strip, contains(step), reason: 'TokensStrip.$step ausente');
    }
    for (final r in ['rInput', 'rCard', 'rButton']) {
      expect(strip, contains(r), reason: 'TokensStrip.$r ausente');
    }
    final eagle = File('lib/core/theme/design_tokens.dart').readAsStringSync();
    for (final r in ['radiusXs', 'radiusSm', 'radiusMd', 'radiusLg']) {
      expect(eagle, contains(r), reason: 'EagleTokens.$r ausente');
    }
  });

  test('module layout constants use TokensStrip scale', () {
    for (final path in moduleLayouts) {
      final source = File(path).readAsStringSync();
      expect(source, contains('TokensStrip.s'));
    }
  });

  test('hub screens use centralized spacing or layout tokens', () {
    for (final path in hubScreens) {
      expect(File(path).existsSync(), isTrue, reason: 'Hub ausente: $path');
      final source = readScreenSourceBundle(path);
      final usesSpacing = source.contains('TokensStrip.s') ||
          source.contains('FocuxSpacing') ||
          source.contains('Aluno360Layout') ||
          source.contains('DashboardLayout') ||
          source.contains('FxContentWidthLimiter');
      expect(usesSpacing, isTrue, reason: '$path deve usar tokens de espaçamento');
    }
  });

  test('personal dashboard uses FxContentWidthLimiter and DashboardLayout', () {
    final screen = readScreenSourceBundle(
      'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    );
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('dashboard_layout.dart'));
    expect(screen, contains('DashboardLayout'));
  });

  test('personal dashboard avoids magic SizedBox off 8pt grid', () {
    const path =
        'lib/features/dashboard/screens/personal_dashboard_screen.dart';
    final failures = <String>[];
    final source = readScreenSourceBundle(path);
    for (final match in magicSizedBox.allMatches(source)) {
      final value = double.tryParse(match.group(1)!);
      if (value == null || scaleSteps.contains(value)) continue;
      final line =
          '\n'.allMatches(source.substring(0, match.start)).length + 1;
      failures.add('$path:$line SizedBox ${match.group(1)}');
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('DESIGN_SYSTEM documents spacing and layout', () {
    final doc = File('docs/DESIGN_SYSTEM.md').readAsStringSync();
    expect(doc, contains('Espaçamento'));
    expect(doc, contains('FocuxSpacing'));
    expect(doc, contains('FxContentWidthLimiter'));
  });
}
