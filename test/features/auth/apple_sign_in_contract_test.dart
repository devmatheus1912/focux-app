import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('Apple Sign-In: serviço, API e entitlement', () {
    final service = readScreenSourceBundle(
      'lib/features/auth/services/apple_sign_in_service.dart',
    );
    expect(service, contains('getAppleIDCredential'));
    expect(service, contains('AppleIDAuthorizationScopes.email'));
    expect(service, contains('AppleIDAuthorizationScopes.fullName'));
    expect(service, contains('identityToken'));
    expect(service, contains('givenName'));
    expect(service, contains('familyName'));
    expect(service, contains('Platform.isIOS'));

    final repo = readScreenSourceBundle(
      'lib/features/auth/data/auth_repository.dart',
    );
    expect(repo, contains("'/api/auth/apple'"));
    expect(repo, contains('loginApple'));
    expect(repo, contains('appleSignInEnabled'));
    expect(
      repo,
      contains("json['appleSignInEnabled'] as bool? ?? false"),
    );
    expect(repo, contains("'fullName'"));
    expect(repo, contains("'personalSlug'"));
    expect(repo, contains('_persistAuthResponse'));

    final entitlements = readScreenSourceBundle(
      'ios/Runner/Runner.entitlements',
    );
    expect(entitlements, contains('com.apple.developer.applesignin'));
    expect(entitlements, contains('Default'));

    final pubspec = readScreenSourceBundle('pubspec.yaml');
    expect(pubspec, contains('sign_in_with_apple:'));
  });
}
