import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('splash cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/auth/screens/splash_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('CinematicSplashScene'));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });

  test('cena cinematic sempre resolve lockup mesmo em compact', () {
    final scene = readScreenSourceBundle(
      'lib/features/auth/widgets/cinematic_splash_scene.dart',
    );
    expect(scene, contains('FocuxBrandTagline'));
    expect(scene, contains('FocuxOfficialLogo.full'));
    // Compact não pode forçar icon-only permanente.
    expect(scene, isNot(contains('iconOnlyT = compact ? 1.0')));
    expect(scene, contains('heroTealSurface'));
  });
}
