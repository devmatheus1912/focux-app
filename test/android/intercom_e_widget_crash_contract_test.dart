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
    final plugin = File(
      'packages/intercom_flutter/android/src/main/kotlin/io/maido/intercom/IntercomFlutterPlugin.kt',
    ).readAsStringSync();
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

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
    expect(plugin, contains('Intercom.client()'));
    expect(
      manifest,
      contains('androidx.glance.appwidget.action.InvisibleActionTrampolineActivity'),
    );
    expect(manifest, contains('tools:node="remove"'));
  });
}
