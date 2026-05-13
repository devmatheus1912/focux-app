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
  });
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
