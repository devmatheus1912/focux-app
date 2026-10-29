import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('splash cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/auth/screens/splash_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('SplashScene'));
    expect(screen, contains('SplashEstado'));
    expect(screen, contains('_tentativa'));
    expect(screen, isNot(contains('_progressCtrl')));
    expect(screen, isNot(contains('_ambientCtrl')));
    expect(screen, contains('FocuxSystemChrome.dark'));
    expect(screen, contains('AuthShell('));
    expect(screen, isNot(contains('flatBackground: false')));
    expect(screen, isNot(contains('showCornerGlow: true')));
    expect(screen, contains('extendBody: true'));
    expect(screen, contains('PopScope('));
    expect(screen, contains('canPop: false'));
    expect(screen, contains('TokensStrip.prefersReducedMotion'));
    expect(screen, isNot(contains('minVisible')));
    expect(screen, contains('splashGuestTarget'));
    expect(screen, contains('splashAlunoTarget'));
    expect(screen, contains('splashPersonalTarget'));
    expect(screen, isNot(contains('TextField')));
    expect(screen, isNot(contains('safePopOrGo')));
    expect(screen, isNot(contains('context.pop()')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });

  test(
    'chrome de sistema segue a Home (nav transparente, sem faixa branca)',
    () {
      final chrome = readScreenSourceBundle(
        'lib/core/theme/focux_system_chrome.dart',
      );
      expect(chrome, contains('systemNavigationBarColor: Colors.transparent'));
      expect(chrome, contains('systemNavigationBarContrastEnforced: false'));
      expect(chrome, contains('edge-to-edge'));
    },
  );

  test('cena da splash é só o logo parado', () {
    final scene = readScreenSourceBundle(
      'lib/features/auth/widgets/splash_scene.dart',
    );
    expect(scene, contains('FocuxOfficialLogo.full'));
    expect(scene, contains('liveRegion: true'));
    expect(scene, isNot(contains('FocuxBrandTagline')));
  });

  test('launch theme Android é dark como a Home', () {
    final styles =
        File('android/app/src/main/res/values/styles.xml').readAsStringSync();
    final launchBg =
        File(
          'android/app/src/main/res/drawable/launch_background.xml',
        ).readAsStringSync();
    expect(styles, contains('Theme.Black.NoTitleBar'));
    expect(styles, isNot(contains('Theme.Light.NoTitleBar')));
    expect(styles, contains('focux_cinematic_bg'));
    expect(launchBg, contains('@color/focux_cinematic_bg'));
    expect(launchBg, isNot(contains('@drawable/background')));
  });

  test('launch iOS não começa branco', () {
    final storyboard =
        File(
          'ios/Runner/Base.lproj/LaunchScreen.storyboard',
        ).readAsStringSync();
    expect(storyboard, isNot(contains('red="1" green="1" blue="1"')));
    expect(storyboard, contains('red="0.0431372549"'));
  });
}
