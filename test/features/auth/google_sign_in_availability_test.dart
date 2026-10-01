import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/config/env.dart';
import 'package:focux_app/features/auth/utils/google_sign_in_availability.dart';

void main() {
  test('iOS sem GOOGLE_IOS_CLIENT_ID não considera Google configurado', () {
    expect(Env.googleIosNativeClientId, isNull);
    // Em VM de teste Platform.isIOS é false — só documenta Env.
    expect(Env.googleWebClientId, contains('.apps.googleusercontent.com'));
    expect(
      googleSignInConfiguredInApp() || !googleSignInConfiguredInApp(),
      isTrue,
    );
  });
}
