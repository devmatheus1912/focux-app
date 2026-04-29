import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared states use active theme primary instead of fixed Focux blue', () {
    final states = File('lib/core/widgets/fx_states.dart').readAsStringSync();

    expect(states, contains('Theme.of(context).colorScheme.primary'));
    expect(states, isNot(contains('EagleTokens.brand')));
    expect(states, isNot(contains('Color(0xFF0288D1)')));
  });

  test('premium chat has no fixed brand token after white-label sweep', () {
    final chat = File(
      'lib/features/chat/screens/conversation_screen.dart',
    ).readAsStringSync();

    expect(chat, contains('Theme.of(context).colorScheme.primary'));
    expect(chat, contains('accentColor: primary'));
    expect(chat, isNot(contains('EagleTokens.brand')));
    expect(chat, isNot(contains('Color(0xFF2563EB)')));
  });

  test('command center low severity follows active primary color', () {
    final commandCenter = File(
      'lib/features/dashboard/screens/command_center_widget.dart',
    ).readAsStringSync();

    expect(commandCenter, contains('_severityColor(action.severidade, primary)'));
    expect(commandCenter, contains('return fallback;'));
    expect(commandCenter, isNot(contains('return const Color(0xFF2563EB);')));
  });

  test('commercial screens do not use fixed Focux brand tokens', () {
    final files = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) {
      final path = file.path.replaceAll('\\', '/');
      return path.contains('/financeiro/') ||
          path.contains('/leads/') ||
          path.contains('/feed/') ||
          path.contains('/analytics/') ||
          path.contains('/assinatura/') ||
          path.contains('/subscription/') ||
          path.contains('/exercicios/') ||
          path.contains('/admin/') ||
          path.contains('/perfil/') ||
          path.contains('/growth/') ||
          path.contains('/landing/') ||
          path.contains('/depoimentos/') ||
          path.contains('/planos/') ||
          path.contains('/onboarding/');
    }).where((file) => file.path.endsWith('.dart'));

    for (final file in files) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('EagleTokens.brand')), reason: file.path);
      expect(source, isNot(contains('Color(0xFF2563EB)')), reason: file.path);
    }
  });
}
