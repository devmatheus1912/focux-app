import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('suporte usa polish: feedback e a11y no chat', () {
    final screen = readScreenSourceBundle(
      'lib/features/suporte/screens/suporte_screen.dart',
    );

    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('FeedbackHelper.showSuccess'));
    expect(screen, contains('Ticket #'));
    expect(screen, contains('Semantics('));
    expect(screen, contains('Suporte:'));
    expect(screen, isNot(contains('SnackBar(')));
  });
}
