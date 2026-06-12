import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/ux/focux_feedback.dart';

import '../../support/screen_source_bundle.dart';

/// Pilar 10 — UX & feedback: toasts, erros humanizados e estados vazios.
void main() {
  const hubScreens = [
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
    'lib/features/financeiro/screens/financeiro_screen.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart',
  ];

  final rawExceptionInToast = RegExp(
    r'FeedbackHelper\.show(?:Error|Warn)\([^)]*\$(?:e|error)\b',
  );

  test('UX feedback sources and tests exist', () {
    for (final path in FocuxFeedback.uxSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    expect(
      File('test/core/ux/friendly_error_test.dart').existsSync(),
      isTrue,
    );
    expect(
      File('test/core/ux/focux_feedback_test.dart').existsSync(),
      isTrue,
    );
  });

  test('DESIGN_SYSTEM documents UX and feedback', () {
    final doc = File('docs/DESIGN_SYSTEM.md').readAsStringSync();
    expect(doc, contains('UX & feedback'));
    expect(doc, contains('FocuxFeedback'));
    expect(doc, contains('ux_feedback_pillar_contract_test'));
  });

  test('FeedbackHelper exposes toast states', () {
    final helper =
        File('lib/core/widgets/feedback_helper.dart').readAsStringSync();
    for (final method in FocuxFeedback.toastMethods) {
      expect(helper, contains(method));
    }
    expect(helper, contains('FeedbackPlacement'));
  });

  test('hub screens use centralized feedback patterns', () {
    const financeiroTabs = [
      'lib/features/financeiro/screens/financeiro_dashboard_screen.dart',
      'lib/features/financeiro/screens/financeiro_mensalidades_tab.dart',
    ];

    for (final path in hubScreens) {
      expect(File(path).existsSync(), isTrue, reason: 'Hub ausente: $path');
      var source = readScreenSourceBundle(path);
      if (path.endsWith('financeiro_screen.dart')) {
        for (final tab in financeiroTabs) {
          source += File(tab).readAsStringSync();
        }
      }
      final usesFeedback = FocuxFeedback.hubFeedbackPatterns
          .any((pattern) => source.contains(pattern));
      expect(
        usesFeedback,
        isTrue,
        reason: '$path deve usar FeedbackHelper ou erros humanizados',
      );
    }
  });

  test('features avoid raw exceptions in FeedbackHelper toasts', () {
    final failures = <String>[];
    for (final file in Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final path = file.path.replaceAll(r'\', '/');
      final norm = path.substring(path.indexOf('lib/'));
      if (norm.startsWith('lib/features/qa/')) continue;

      final source = file.readAsStringSync();
      for (final match in rawExceptionInToast.allMatches(source)) {
        final line =
            '\n'.allMatches(source.substring(0, match.start)).length + 1;
        failures.add('$norm:$line ${match.group(0)}');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('features avoid raw SnackBar outside FeedbackHelper', () {
    final failures = <String>[];
    for (final file in Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final path = file.path.replaceAll(r'\', '/');
      final norm = path.substring(path.indexOf('lib/'));
      if (norm.startsWith('lib/features/qa/')) continue;
      if (file.readAsStringSync().contains('SnackBar(')) {
        failures.add(norm);
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
