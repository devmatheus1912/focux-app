import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('landing studio usa polish Focux S5', () {
    final screen = readScreenSourceBundle(
      'lib/features/perfil/screens/landing_editor_screen.dart',
    );

    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('FeatureGate'));
    expect(screen, contains('landingCompleta'));
    expect(screen, contains('FeedbackHelper'));
    expect(screen, isNot(contains('showSnackBar(')));
    expect(screen, contains('viewInsets'));
    expect(screen, contains('unfocus'));
    expect(screen, contains('landingStudioRepositoryProvider'));
    expect(screen, contains('Gerar landing'));
    expect(screen, contains('Publicar'));
    expect(screen, isNot(contains('sectionOrder')));
    expect(screen, isNot(contains('landing/presets')));
    expect(screen, isNot(contains('gerar-hero')));
  });
}
