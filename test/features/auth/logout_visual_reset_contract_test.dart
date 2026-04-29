import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manual logout invalidates router session globally', () {
    final provider =
        File('lib/features/auth/providers/auth_provider.dart').readAsStringSync();

    expect(provider, contains("SessionInvalidator.invalidate(reason: 'logout manual')"));
    expect(provider, contains('state = AuthStatus.unauthenticated'));
  });

  test('app clears branded visual state after logout', () {
    final main = File('lib/main.dart').readAsStringSync();

    expect(main, contains('void _resetCustomTheme()'));
    expect(main, contains('primaryColorProvider.notifier'));
    expect(main, contains('const Color(0xFF0288D1)'));
    expect(main, contains('logoUrlProvider.notifier'));
    expect(main, contains('personalNameProvider.notifier'));
    expect(main, contains('next == AuthStatus.unauthenticated'));
    expect(main, contains('_resetCustomTheme();'));
    expect(main, contains('if (!mounted) return;'));
  });
}
