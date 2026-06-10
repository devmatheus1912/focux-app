import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Eagle design system anti-regression gates', () {
    test(
      'blocks raw loading/input/feedback/brand anti-patterns outside core wrappers',
      () {
        final rules = [
          _EagleGateRule(
            label: 'CircularProgressIndicator()',
            pattern: RegExp(r'\bCircularProgressIndicator\s*\('),
            allowedFiles: {'lib/core/widgets/fx_loading.dart'},
          ),
          _EagleGateRule(
            label: 'OutlineInputBorder()',
            pattern: RegExp(r'\bOutlineInputBorder\s*\('),
            allowedFiles: {
              'lib/core/widgets/fx_input_deco.dart',
              'lib/core/theme/app_theme.dart',
            },
          ),
          _EagleGateRule(
            label: 'ScaffoldMessenger.of()',
            pattern: RegExp(r'\bScaffoldMessenger\.of\s*\('),
            allowedFiles: {'lib/core/widgets/feedback_helper.dart'},
          ),
          _EagleGateRule(
            label: 'FontWeight.bold',
            pattern: RegExp(r'\bFontWeight\.bold\b'),
            allowedFiles: const {},
            ignoredPrefixes: const ['pw.'],
          ),
          _EagleGateRule(
            label: 'EagleTokens.brand exact',
            pattern: RegExp(r'\bEagleTokens\.brand\b'),
            allowedFiles: {
              'lib/main.dart',
              'lib/core/theme/theme_provider.dart',
            },
          ),
          _EagleGateRule(
            label: "debugPrint('[Focux] Error",
            pattern: RegExp(r"debugPrint\s*\(\s*'\[Focux\] Error"),
            allowedFiles: const {},
          ),
          _EagleGateRule(
            label: 'SnackBar(content: Text(',
            pattern: RegExp(r'SnackBar\s*\(\s*content:\s*Text\s*\('),
            allowedFiles: {'lib/core/widgets/feedback_helper.dart'},
          ),
        ];

        final failures = <String>[];
        final files = Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'));

        for (final file in files) {
          final path = file.path.replaceAll(r'\', '/');
          final normalizedPath = path.substring(path.indexOf('lib/'));
          final source = file.readAsStringSync();

          for (final rule in rules) {
            if (rule.allowedFiles.contains(normalizedPath)) continue;

            for (final match in rule.pattern.allMatches(source)) {
              final prefixStart = match.start - 3;
              final prefix =
                  prefixStart >= 0
                      ? source.substring(prefixStart, match.start)
                      : '';
              if (rule.ignoredPrefixes.contains(prefix)) continue;

              final line =
                  '\n'.allMatches(source.substring(0, match.start)).length + 1;
              failures.add('${rule.label}: $normalizedPath:$line');
            }
          }
        }

        expect(
          failures,
          isEmpty,
          reason: 'Raw Eagle anti-patterns found:\n${failures.join('\n')}',
        );
      },
    );

    test(
      'blocks Card+ListTile and bare ListTile without fxListTileCardShell',
      () {
        const allowedListTileShellBypassFiles = {
          'lib/core/widgets/fx_shell_scaffold.dart',
          'lib/features/qa/screens/qa_smoke_screen.dart',
        };

        final failures = <String>[];
        final files = Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'));

        for (final file in files) {
          final path = file.path.replaceAll(r'\', '/');
          final normalizedPath = path.substring(path.indexOf('lib/'));
          final source = file.readAsStringSync();

          if (!allowedListTileShellBypassFiles.contains(normalizedPath)) {
            failures.addAll(
              _findCardWrappedListTiles(source, normalizedPath),
            );
          }

          if (allowedListTileShellBypassFiles.contains(normalizedPath)) continue;
          failures.addAll(
            _findBareListTilesWithoutShell(source, normalizedPath),
          );
        }

        expect(
          failures,
          isEmpty,
          reason:
              'ListTile must use fxListTileCardShell or FxSatelliteListTile:\n'
              '${failures.join('\n')}',
        );
      },
    );
  });
}

List<String> _findCardWrappedListTiles(String source, String path) {
  final failures = <String>[];
  final cardPattern = RegExp(r'\bCard\s*\(');

  for (final cardMatch in cardPattern.allMatches(source)) {
    final sliceEnd = (cardMatch.start + 1200).clamp(0, source.length);
    final slice = source.substring(cardMatch.start, sliceEnd);
    final listTileMatch = RegExp(r'child:\s*ListTile\s*\(').firstMatch(slice);
    if (listTileMatch == null) continue;

    final beforeListTile = slice.substring(0, listTileMatch.start);
    if (beforeListTile.contains('fxListTileCardShell') ||
        beforeListTile.contains('FxSatelliteListTile')) {
      continue;
    }

    final line =
        '\n'.allMatches(source.substring(0, cardMatch.start + listTileMatch.start)).length +
        1;
    failures.add('Card+ListTile: $path:$line');
  }

  return failures;
}

List<String> _findBareListTilesWithoutShell(String source, String path) {
  final failures = <String>[];
  final listTilePattern = RegExp(r'(?:return|child)\s*:\s*ListTile\s*\(');

  for (final match in listTilePattern.allMatches(source)) {
    final windowStart = (match.start - 600).clamp(0, source.length);
    final before = source.substring(windowStart, match.start);
    if (before.contains('fxListTileCardShell') ||
        before.contains('FxSatelliteListTile')) {
      continue;
    }

    final line =
        '\n'.allMatches(source.substring(0, match.start)).length + 1;
    failures.add('bare ListTile: $path:$line');
  }

  return failures;
}

class _EagleGateRule {
  final String label;
  final RegExp pattern;
  final Set<String> allowedFiles;
  final List<String> ignoredPrefixes;

  const _EagleGateRule({
    required this.label,
    required this.pattern,
    required this.allowedFiles,
    this.ignoredPrefixes = const [],
  });
}
