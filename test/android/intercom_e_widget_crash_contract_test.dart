import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Intercom inicializa na Application e o trampoline do Glance sai', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final settings = File('android/settings.gradle.kts').readAsStringSync();
    final application = File(
      'android/app/src/main/kotlin/com/focux/focux_app/FocuxApplication.kt',
    ).readAsStringSync();
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final service =
        File('lib/core/support/intercom_service.dart').readAsStringSync();

    expect(settings, contains('base-application-name'));
    expect(settings, contains('com.focux.focux_app.FocuxApplication'));
    expect(application, contains('Intercom.initialize'));
    // As chaves vêm do build (env ou local.properties), nunca do código-fonte.
    expect(application, contains('BuildConfig.INTERCOM_APP_ID'));
    expect(application, contains('BuildConfig.INTERCOM_ANDROID_API_KEY'));
    expect(application, isNot(contains('android_sdk-')));
    expect(gradle, contains('INTERCOM_APP_ID'));
    expect(gradle, contains('INTERCOM_ANDROID_API_KEY'));
    expect(gradle, contains('buildConfig = true'));
    // Plugin oficial (9.x, com setUserJwt); o fork local 3.0.0 não existe mais no build.
    expect(pubspec, isNot(contains('path: packages/intercom_flutter')));
    expect(pubspec, matches(RegExp(r'intercom_flutter:\s*\^9\.')));
    expect(service, contains('setUserJwt'));
    expect(service, contains('setUserJwtProvider'));
    expect(
      manifest,
      contains('io.intercom.android.sdk.fcm.IntercomFcmMessengerService'),
    );
    expect(
      manifest,
      contains('androidx.glance.appwidget.action.InvisibleActionTrampolineActivity'),
    );
    expect(manifest, contains('tools:node="remove"'));
  });
}
