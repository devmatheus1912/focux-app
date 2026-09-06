import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('cancel save cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/monetizacao/screens/cancel_save_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains("fallbackLocation: '/assinatura'"));
    expect(screen, contains('FxKeyboardPopScope'));
    expect(screen, contains('onTapOutside'));
    expect(screen, contains('FxConversionTextLink'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, isNot(contains('context.pop()')));
    expect(
      screen,
      anyOf(
        contains('FxContentWidthLimiter'),
        isNot(contains('constrainWidth: false')),
      ),
    );
  });

  test('cancel save motivos usam superfície escura no dark mode', () {
    final screen = readScreenSourceBundle(
      'lib/features/monetizacao/screens/cancel_save_screen.dart',
    );
    expect(screen, contains('ShellChrome.forDark(isDark)'));
    expect(screen, contains('palette.sheetFill'));
    expect(screen, isNot(contains('color: TokensStrip.cardBg,')));
    expect(screen, contains('palette.line'));
  });
}
