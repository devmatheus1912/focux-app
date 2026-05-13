import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('api client invalidates broken sessions after refresh fails', () {
    final apiClient = File('lib/core/api/api_client.dart').readAsStringSync();
    final invalidator =
        File('lib/core/auth/session_invalidator.dart').readAsStringSync();

    expect(apiClient, contains('SessionInvalidator.invalidate'));
    expect(
      apiClient,
      matches(RegExp(r'!_isRefreshing\s*&&\s*_shouldInvalidateSession\(e\)')),
    );
    expect(apiClient, contains("!_isAuthPath(e.requestOptions.path)"));
    expect(apiClient, contains('e.response?.statusCode == 401'));
    expect(apiClient, contains('status == 401'));
    expect(apiClient, contains('status == 403'));
    expect(apiClient, contains('_isLikelySessionAuthFailure'));
    expect(apiClient, isNot(contains('await SecureStorage.clearAll();')));

    expect(invalidator, contains('ValueNotifier<int>'));
    expect(invalidator, contains('SecureStorage.clearAll()'));
    expect(invalidator, contains('_notifier.value++'));
  });

  test('auth provider reacts to session invalidation event', () {
    final provider =
        File(
          'lib/features/auth/providers/auth_provider.dart',
        ).readAsStringSync();

    expect(
      provider,
      contains(
        'SessionInvalidator.listenable.addListener(_handleSessionInvalidated)',
      ),
    );
    expect(
      provider,
      contains(
        'SessionInvalidator.listenable.removeListener(_handleSessionInvalidated)',
      ),
    );
    expect(provider, contains('state = AuthStatus.unauthenticated'));
    expect(provider, contains('_currentRole = null'));
  });
}
