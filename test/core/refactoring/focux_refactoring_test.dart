import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/refactoring/focux_refactoring.dart';

void main() {
  test('FocuxRefactoring catalog defines decomposition threshold', () {
    expect(FocuxRefactoring.monolithicPartThreshold, 900);
    expect(FocuxRefactoring.requiresDecomposition(901), isTrue);
    expect(FocuxRefactoring.requiresDecomposition(900), isFalse);
  });

  test('refactoring sources and orphan scanner exist', () {
    for (final path in FocuxRefactoring.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }

    final orphan = File('tools/find_orphan_dart.dart').readAsStringSync();
    expect(orphan, contains('find_orphan_dart'));
  });

  test('hub logic module map covers six hubs', () {
    expect(FocuxRefactoring.hubDecompositionMarkers, hasLength(6));
  });
}
