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
}
