import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/a11y/focux_a11y.dart';

void main() {
  test('core and module a11y sources exist', () {
    for (final path in [
      ...FocuxA11y.coreSources,
      ...FocuxA11y.moduleSources,
    ]) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
  });

  test('fxScreenA11yScope is defined', () {
    final source =
        File('lib/core/widgets/fx_screen_a11y.dart').readAsStringSync();
    expect(source, contains('fxScreenA11yScope'));
    expect(source, contains('explicitChildNodes'));
  });

  test('automated gate files are registered', () {
    for (final path in FocuxA11y.automatedGates) {
      expect(File(path).existsSync(), isTrue, reason: 'Gate ausente: $path');
    }
  });
}
