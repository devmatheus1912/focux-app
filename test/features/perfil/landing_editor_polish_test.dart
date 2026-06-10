import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('landing editor usa polish 10/10: feedback tipado e qualidade', () {
    final screen = File(
      'lib/features/perfil/screens/landing_editor_screen.dart',
    ).readAsStringSync();

    expect(screen, contains('FeedbackHelper.showSuccess'));
    expect(screen, contains('FeedbackHelper.showError'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('landing_editor_quality.dart'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, isNot(contains('SnackBar(content: Text(')));
  });
}
