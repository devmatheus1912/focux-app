import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/platform/focux_platform.dart';

import '../../support/screen_source_bundle.dart';

/// Pilar 16 — Adaptação de plataforma: safe area, breakpoints e shell nos hubs.
void main() {
  const hubScreens = [
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
    'lib/features/financeiro/screens/financeiro_screen.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart',
  ];

  test('platform catalog and automated gates exist', () {
    for (final path in FocuxPlatform.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    for (final path in FocuxPlatform.automatedGates) {
      expect(File(path).existsSync(), isTrue, reason: 'Gate ausente: $path');
    }
    expect(
      File('test/core/platform/focux_platform_test.dart').existsSync(),
      isTrue,
    );
  });

  test('DESIGN_SYSTEM documents platform adaptation', () {
    final doc = File('lib/core/design_system.dart').readAsStringSync();
    expect(doc, contains('Adaptação de plataforma'));
    expect(doc, contains('FocuxPlatform'));
    expect(doc, contains('platform_adaptation_pillar_contract_test'));
  });

  test('hub screens adapt to safe area and shell chrome', () {
    const alunosStatePart =
        'lib/features/alunos/screens/alunos_list_screen_state.part.dart';
    const financeiroTabs = [
      'lib/features/financeiro/screens/financeiro_dashboard_screen.dart',
      'lib/features/financeiro/screens/financeiro_mensalidades_tab.dart',
      'lib/features/financeiro/screens/financeiro_mensalidades_tab_actions.part.dart',
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

      final adapts = FocuxPlatform.hubPlatformPatterns
          .any((pattern) => source.contains(pattern));
      expect(
        adapts,
        isTrue,
        reason: '$path deve usar ShellChrome, MediaQuery ou layout de módulo',
      );

      expect(
        source.contains('MediaQuery'),
        isTrue,
        reason: '$path deve considerar insets/viewport',
      );
    }
  });

  test('desktop hubs constrain content width', () {
    final dashboard = readScreenSourceBundle(
      'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    );
    expect(dashboard, contains('FxContentWidthLimiter'));

    final financeiro = readScreenSourceBundle(
      'lib/features/financeiro/screens/financeiro_screen.dart',
    );
    expect(financeiro, contains('FxContentWidthLimiter'));

    final limiter =
        File('lib/core/widgets/fx_content_width_limiter.dart').readAsStringSync();
    expect(limiter, contains('FocuxPlatform.desktopMaxContent'));
  });

  test('module layouts align max width with FocuxPlatform', () {
    final dashboard =
        File('lib/features/dashboard/constants/dashboard_layout.dart')
            .readAsStringSync();
    expect(dashboard, contains('FocuxPlatform.desktopMaxContent'));

    final aluno360 =
        File('lib/features/alunos/constants/aluno_360_layout.dart')
            .readAsStringSync();
    expect(aluno360, contains('TokensStrip'));
  });

  test('personal and aluno shells use shared compact breakpoint', () {
    for (final path in [
      'lib/core/screens/main_shell.dart',
      'lib/core/screens/aluno_shell.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('FocuxPlatform.isCompact'));
      expect(source, contains('FocuxPlatform.safeBottomInset'));
    }
  });
}
