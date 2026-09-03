import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('anamnese cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/anamnese/screens/anamnese_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('bottomNavigationBar'));
    expect(screen, isNot(contains('TextButton')));
    expect(screen, isNot(contains('TabBar')));
    expect(screen, isNot(contains('TabBarView')));
    expect(screen, isNot(contains('TabController')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('Slider(')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
