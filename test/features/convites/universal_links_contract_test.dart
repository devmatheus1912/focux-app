import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android App Links cobrem convite, landing e login', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:autoVerify="true"'));
    expect(manifest, contains('android:host="focuxpersonal.com"'));
    expect(manifest, contains('android:pathPrefix="/convite"'));
    expect(manifest, contains('android:pathPrefix="/p"'));
    expect(manifest, contains('android:pathPrefix="/login"'));
    expect(manifest, contains('android:scheme="focux"'));
    expect(manifest, contains('flutter_deeplinking_enabled'));
    expect(
      File('android/app/build.gradle.kts').readAsStringSync(),
      contains('applicationId = "com.focux.focux_app"'),
    );
  });

  test('iOS Associated Domains e FlutterDeepLinkingEnabled', () {
    final entitlements =
        File('ios/Runner/Runner.entitlements').readAsStringSync();
    expect(entitlements, contains('applinks:focuxpersonal.com'));
    expect(entitlements, contains('applinks:www.focuxpersonal.com'));

    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<string>focux</string>'));
    expect(plist, contains('FlutterDeepLinkingEnabled'));

    final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(pbx, contains('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements'));
    expect(pbx, contains('PRODUCT_BUNDLE_IDENTIFIER = com.focux.focuxApp'));
  });

  test('router registra /convite/:token com deep link screen', () {
    final routes =
        File('lib/core/router/app_router_auth_routes.dart').readAsStringSync();
    expect(routes, contains("path: '/convite/:token'"));
    expect(routes, contains('ConviteDeepLinkScreen'));
    expect(routes, contains("path: '/p/:slug'"));
    expect(
      File('lib/core/router/app_router_redirect.dart').readAsStringSync(),
      contains("path.startsWith('/convite/')"),
    );
  });
}
