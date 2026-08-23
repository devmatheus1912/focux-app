import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'shared states use active theme primary instead of fixed Focux blue',
    () {
      final states =
          File('lib/core/widgets/fx_empty_state.dart').readAsStringSync();

      expect(states, contains('colorScheme.primary'));
      expect(_hasFixedBrandToken(states), isFalse);
      expect(states, isNot(contains('Color(0xFF0288D1)')));
    },
  );

  test('premium chat has no fixed brand token after white-label sweep', () {
    final chat =
        File(
          'lib/features/chat/screens/conversation_screen.dart',
        ).readAsStringSync();

    expect(chat, contains('Theme.of(context).colorScheme.primary'));
    expect(chat, contains('accentColor: primary'));
    expect(_hasFixedBrandToken(chat), isFalse);
    expect(chat, isNot(contains('Color(0xFF2563EB)')));
  });

  test('command center low severity follows active primary color', () {
    // Mapeamento de tom → accent extraído para o tile compartilhado.
    final actionTile =
        File(
          'lib/features/dashboard/widgets/command_action_tile.dart',
        ).readAsStringSync();

    expect(actionTile, contains('CommandActionTone.primary => primary'));
    expect(actionTile, isNot(contains('return const Color(0xFF2563EB);')));
  });

  test('feature screens do not use fixed Focux brand tokens', () {
    final files = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in files) {
      final source = file.readAsStringSync();
      expect(_hasFixedBrandToken(source), isFalse, reason: file.path);
      expect(source, isNot(contains('Color(0xFF2563EB)')), reason: file.path);
      expect(source, isNot(contains('Color(0xFF0288D1)')), reason: file.path);
    }
  });

  test('lib only keeps Focux brand reset in central theme entrypoints', () {
    const allowedBrandTokenFiles = {
      'lib/core/theme/theme_provider.dart',
      'lib/core/theme/tokens_strip.dart',
      'lib/core/theme/design_tokens.dart',
      'lib/main.dart',
    };

    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in files) {
      final normalizedPath = file.path.replaceAll(r'\', '/');
      final source = file.readAsStringSync();

      if (!allowedBrandTokenFiles.contains(normalizedPath)) {
        expect(_hasFixedBrandToken(source), isFalse, reason: normalizedPath);
      }

      expect(
        source,
        isNot(contains('Color(0xFF2563EB)')),
        reason: normalizedPath,
      );
      expect(
        source,
        isNot(contains('Color(0xFF0288D1)')),
        reason: normalizedPath,
      );
    }
  });
}

bool _hasFixedBrandToken(String source) {
  return RegExp(r'\bEagleTokens\.brand\b').hasMatch(source);
}
