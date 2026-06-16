import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/refactoring/focux_refactoring.dart';

import '../../support/screen_source_bundle.dart';

/// Gate global — telas de produção respeitam limiar de monolito (900 LOC).
void main() {
  const excluded = {
    'lib/features/qa/screens/qa_smoke_screen.dart',
    'lib/features/qa/screens/tokens_strip_showcase_screen.dart',
  };

  test('production screens entry stays at or below monolith threshold', () {
    final offenders = <String>[];
    for (final file in Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_screen.dart'))) {
      final path = file.path.replaceAll(r'\', '/');
      final rel = path.substring(path.indexOf('lib/'));
      if (excluded.contains(rel)) continue;
      final lines = file.readAsLinesSync().length;
      if (lines > FocuxRefactoring.monolithicPartThreshold) {
        offenders.add('$rel ($lines LOC entry)');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('large production screens use part decomposition', () {
    final offenders = <String>[];
    for (final file in Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_screen.dart'))) {
      final path = file.path.replaceAll(r'\', '/');
      final rel = path.substring(path.indexOf('lib/'));
      if (excluded.contains(rel)) continue;
      final bundle = readScreenSourceBundle(rel);
      final lineCount = bundle.split('\n').length;
      if (lineCount <= FocuxRefactoring.monolithicPartThreshold) continue;
      final main = File(rel).readAsStringSync();
      final decomposed = main.contains("part '");
      if (!decomposed) {
        offenders.add('$rel ($lineCount LOC bundle, sem parts)');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
