import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('Apple offered: une capabilities + environment-status', () {
    final repo = readScreenSourceBundle(
      'lib/features/auth/data/auth_repository.dart',
    );
    expect(repo, contains('bool resolveAppleSignInOffered'));
    expect(repo, contains('appleSignInOffered'));
    expect(repo, contains('appleSignInReady'));
    expect(repo, contains('appleClientIdsConfigured'));
    expect(
      repo,
      contains('appleSignInEnabled || appleSignInReady || appleClientIdsConfigured'),
    );

    final login = readScreenSourceBundle(
      'lib/features/auth/screens/login_screen.dart',
    );
    expect(login, contains('resolveAppleSignInOffered'));
    expect(login, contains('environmentStatus'));

    final register = readScreenSourceBundle(
      'lib/features/auth/screens/register_screen.dart',
    );
    expect(register, contains('resolveAppleSignInOffered'));
    expect(register, contains('environmentStatus'));
  });
}
