import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('coach cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/coach/screens/coach_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains("safePopOrGo(context, '/dashboard/personal')"));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxStripCard'));
    expect(screen, contains('emphasize: true'));
    expect(screen, contains('FxEmptyAction'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('coachHomeProvider'));
    expect(screen, contains('Abrir aluno'));
    expect(screen, contains('homeCoachDismissed'));
    expect(screen, contains('Como calculamos'));
    expect(screen, contains('ShellChrome.forDark'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
  });
}
