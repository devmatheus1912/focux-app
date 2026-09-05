import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/config/env.dart';
import 'package:focux_app/features/auth/utils/auth_error_messages.dart';

void main() {
  test('Env não força Web client como clientId iOS por padrão', () {
    expect(Env.googleIosClientIdOrNull, isNull);
    expect(Env.googleWebClientId, contains('.apps.googleusercontent.com'));
  });

  test('mapGoogleSignInError humaniza falha de config iOS', () {
    expect(
      mapGoogleSignInError(
        PlatformException(
          code: 'google_sign_in_config',
          message: 'Missing client id / URL scheme',
        ),
        isAluno: false,
      ),
      contains('não está configurado'),
    );
  });

  test('Info.plist tem GIDClientID + reversed URL scheme (anti-SIGABRT)', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<key>GIDClientID</key>'));
    expect(
      plist,
      contains(
        '868715549357-kjut1ja3ab79j6pp3pquk2nha48atbcs.apps.googleusercontent.com',
      ),
    );
    expect(
      plist,
      contains(
        'com.googleusercontent.apps.868715549357-kjut1ja3ab79j6pp3pquk2nha48atbcs',
      ),
    );
    expect(plist, contains('com.focux.focuxApp'));
  });

  test('login/register usam GoogleSignInService (sem Web clientId no iOS)', () {
    final login =
        File(
          'lib/features/auth/screens/login_screen_actions.part.dart',
        ).readAsStringSync();
    final register =
        File(
          'lib/features/auth/screens/register_screen_actions.part.dart',
        ).readAsStringSync();
    final service =
        File(
          'lib/features/auth/services/google_sign_in_service.dart',
        ).readAsStringSync();

    expect(login, contains('GoogleSignInService().signInForIdToken()'));
    expect(register, contains('GoogleSignInService().signInForIdToken()'));
    expect(service, contains('Env.googleIosClientIdOrNull'));
    expect(service, contains('serverClientId: Env.googleWebClientId'));
    expect(service, isNot(contains('clientId: Env.googleWebClientId')));
    expect(login, isNot(contains('GoogleSignIn(')));
    expect(register, isNot(contains('GoogleSignIn(')));
  });
}
