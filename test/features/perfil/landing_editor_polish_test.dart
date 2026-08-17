import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('landing editor usa polish: feedback tipado e qualidade', () {
    final screen = readScreenSourceBundle(
      'lib/features/perfil/screens/landing_editor_screen.dart',
    );

    expect(screen, contains('FeedbackHelper.showSuccess'));
    expect(screen, contains('FeedbackHelper.showError'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('landing_editor_quality.dart'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, isNot(contains('SnackBar(content: Text(')));
  });
}
