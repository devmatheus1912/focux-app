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
    final config =
        File('lib/core/support/intercom_config.dart').readAsStringSync();

    String? dartConst(String name) {
      final match = RegExp("$name\\s*=\\s*'([^']*)'").firstMatch(config);
      expect(match, isNotNull, reason: name);
      final value = match!.group(1)!;
      return value.isEmpty ? null : value;
    }

    expect(settings, contains('base-application-name'));
    expect(settings, contains('com.focux.focux_app.FocuxApplication'));
    expect(application, contains('Intercom.initialize'));
    final appId = dartConst('appId');
    final androidApiKey = dartConst('androidApiKey');
    if (appId != null) expect(application, contains(appId));
    if (androidApiKey != null) expect(application, contains(androidApiKey));
    expect(plugin, contains('Intercom.client()'));
    expect(
      manifest,
      contains('androidx.glance.appwidget.action.InvisibleActionTrampolineActivity'),
    );
    expect(manifest, contains('tools:node="remove"'));
  });
}
