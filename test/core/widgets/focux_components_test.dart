import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/focux_components.dart';

void main() {
  test('catalog paths exist on disk', () {
    for (final path in FocuxComponents.catalogPaths) {
      expect(File(path).existsSync(), isTrue, reason: 'Componente ausente: $path');
    }
  });

  test('minimum Fx widget count met', () {
    final count = Directory('lib/core/widgets')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.replaceAll(r'\', '/').contains('/fx_'))
        .length;
    expect(count, greaterThanOrEqualTo(FocuxComponents.minimumFxWidgets));
  });

  test('hub patterns catalog is non-empty', () {
    expect(FocuxComponents.hubPatterns, isNotEmpty);
    expect(FocuxComponents.hubPatterns, contains('fxScreenA11yScope'));
    expect(FocuxComponents.hubPatterns, contains('FeedbackHelper'));
  });
}
