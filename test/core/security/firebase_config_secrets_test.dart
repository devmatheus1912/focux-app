import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garante que configs Firebase reais (Google API keys `AIza…`) não voltem ao git.
/// Remediação do secret scanning alert #1 (google-services.json).
void main() {
  final googleApiKey = RegExp(r'AIza[0-9A-Za-z_-]{35}');

  const ignoredFirebaseConfigs = [
    'android/app/google-services.json',
    'ios/Runner/GoogleService-Info.plist',
  ];

  const exampleFirebaseConfigs = [
    'android/app/google-services.json.example',
    'ios/Runner/GoogleService-Info.plist.example',
  ];

  test('gitignore blocks real Firebase client configs', () {
    final gitignore = File('.gitignore').readAsStringSync();
    for (final path in ignoredFirebaseConfigs) {
      expect(
        gitignore,
        contains(path),
        reason: '$path deve permanecer no .gitignore',
      );
    }
  });

  test('real Firebase configs are not tracked by git', () {
    final tracked = Process.runSync('git', ['ls-files', '--', ...ignoredFirebaseConfigs]);
    expect(tracked.exitCode, 0, reason: tracked.stderr);
    final lines = (tracked.stdout as String)
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    expect(
      lines,
      isEmpty,
      reason: 'Configs reais não devem estar no índice git: $lines',
    );
  });

  test('example Firebase configs use placeholders, not live Google API keys', () {
    for (final path in exampleFirebaseConfigs) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'Template ausente: $path');
      final body = file.readAsStringSync();
      expect(
        googleApiKey.hasMatch(body),
        isFalse,
        reason: '$path não pode conter Google API key real (AIza…)',
      );
      expect(
        body,
        anyOf(contains('YOUR_FIREBASE'), contains('YOUR_')),
        reason: '$path deve usar placeholders YOUR_*',
      );
    }
  });

  test('no tracked source tree file embeds a live Google API key', () {
    final listed = Process.runSync('git', [
      'ls-files',
      '--',
      '*.dart',
      '*.json',
      '*.plist',
      '*.xml',
      '*.properties',
      '*.env*',
      '*.md',
      '*.gradle*',
      '*.kts',
      '*.yml',
      '*.yaml',
      '*.example',
    ]);
    expect(listed.exitCode, 0, reason: listed.stderr);

    final offenders = <String>[];
    for (final path in (listed.stdout as String).split('\n')) {
      final trimmed = path.trim();
      if (trimmed.isEmpty) continue;
      final file = File(trimmed);
      if (!file.existsSync()) continue;
      final body = file.readAsStringSync();
      if (googleApiKey.hasMatch(body)) {
        offenders.add(trimmed);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Remova ou rode a key; arquivos com AIza…: $offenders',
    );
  });
}
