import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('Apple aparece pelo aparelho, sem depender do backend', () {
    for (final path in [
      'lib/features/auth/screens/login_screen.dart',
      'lib/features/auth/screens/register_screen.dart',
    ]) {
      final screen = readScreenSourceBundle(path);
      expect(screen, contains('AppleSignInService.isAvailableOnDevice'));
      expect(screen, contains('rawNonce: credential.rawNonce'));
      expect(screen, contains('authorizationCode: credential.authorizationCode'));
    }

    final repo = readScreenSourceBundle(
      'lib/features/auth/data/auth_repository.dart',
    );
    expect(repo, contains("'authorizationCode': authorizationCode"));
    expect(repo, contains("'nonce': rawNonce"));
  });
}
