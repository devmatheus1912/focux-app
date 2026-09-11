import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('conversation cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/chat/screens/conversation_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('showFxHomeSheet'));
    expect(screen, contains('FxKeyboardDismissScope'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('/dashboard/aluno'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('ScrollViewKeyboardDismissBehavior.onDrag'));
    expect(screen, isNot(contains('showModalBottomSheet')));
    expect(screen, isNot(contains('showDialog')));
    expect(screen, contains('_showImageViewer'));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
