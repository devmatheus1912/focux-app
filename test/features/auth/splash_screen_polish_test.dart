import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('splash cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/auth/screens/splash_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('CinematicSplashScene'));
    expect(screen, contains('FocuxSystemChrome.dark'));
    expect(screen, contains('AuthShell('));
    expect(screen, contains('animateGridIn: false'));
    expect(screen, isNot(contains('flatBackground: false')));
    expect(screen, isNot(contains('showCornerGlow: true')));
    expect(screen, contains('extendBody: true'));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });

  test('chrome de sistema segue a Home (nav transparente, sem faixa branca)', () {
    final chrome = readScreenSourceBundle('lib/core/theme/focux_system_chrome.dart');
    expect(chrome, contains('systemNavigationBarColor: Colors.transparent'));
    expect(chrome, contains('systemNavigationBarContrastEnforced: false'));
    expect(chrome, contains('edge-to-edge'));
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

  test('launch theme Android é dark como a Home', () {
    final styles = File('android/app/src/main/res/values/styles.xml').readAsStringSync();
    expect(styles, contains('Theme.Black.NoTitleBar'));
    expect(styles, isNot(contains('Theme.Light.NoTitleBar')));
    expect(styles, contains('focux_cinematic_bg'));
    expect(styles, contains('navigationBarColor'));
  });
}
