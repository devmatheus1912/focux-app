import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('white label usa polish 10/10: cards, feedback e a11y', () {
    final screen = File(
      'lib/features/perfil/screens/white_label_settings_screen.dart',
    ).readAsStringSync();

    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('fxListCardDecoration'));
    expect(screen, contains('FeedbackHelper.showSuccess'));
    expect(screen, contains('FeedbackHelper.showError'));
    expect(screen, contains('Semantics('));
    expect(screen, isNot(contains('SnackBar(content: Text(')));
  });
}
