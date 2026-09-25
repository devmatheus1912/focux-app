import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('api client invalidates broken sessions after refresh fails', () {
    final apiClient = File('lib/core/api/api_client.dart').readAsStringSync();
    final invalidator =
        File('lib/core/auth/session_invalidator.dart').readAsStringSync();
    final coordinator = File(
      'lib/core/auth/session_refresh_coordinator.dart',
    ).readAsStringSync();
    final payment =
        File('lib/core/api/payment_api_client.dart').readAsStringSync();
    final mainSrc = File('lib/main.dart').readAsStringSync();

    expect(apiClient, contains('SessionInvalidator.invalidate'));
    expect(apiClient, contains('SessionRefreshCoordinator.ensureFreshAccess'));
    expect(apiClient, contains('fxAuthRetried'));
    expect(apiClient, contains('if (queued)'));
    expect(apiClient, contains('OfflineSyncService.isSensitivePath'));
    expect(apiClient, contains("!_isAuthPath(e.requestOptions.path)"));
    expect(apiClient, contains('newDetachedAuthDio'));
    expect(apiClient, contains('kHttpPoolResumeRecycleMinAway'));
    expect(apiClient, contains('resetAfterAppResume(['));
    expect(apiClient, contains('warmSession'));
    expect(apiClient, contains('ApiTransportCircuit'));
    expect(apiClient, contains('e.response?.statusCode == 401'));
    expect(apiClient, contains('_isLikelySessionAuthFailure'));
    expect(apiClient, isNot(contains('await SecureStorage.clearAll();')));

    expect(coordinator, contains('Single-flight'));
    expect(coordinator, contains('failedRetryable'));
    expect(coordinator, contains('failedFatal'));
    expect(coordinator, contains("'/api/auth/refresh'"));

    expect(payment, contains('SessionRefreshCoordinator.ensureFreshAccess'));
    expect(payment, contains('fxAuthRetried'));

    expect(mainSrc, contains('warmSession'));
    expect(mainSrc, contains('_warmSessionThenSoftReload'));

    expect(invalidator, contains('ValueNotifier<int>'));
    expect(invalidator, contains('SecureStorage.clearAll()'));
    expect(invalidator, contains('AlunosHomeClientCache.clear()'));
    expect(invalidator, contains('Aluno360ClientCache.clear()'));
    expect(invalidator, contains('DashboardHomeClientCache.clear()'));
    expect(invalidator, contains('AlunoDashboardHomeClientCache.clear()'));
    expect(invalidator, contains('ApiEtagStore.clear()'));
    expect(invalidator, contains('PlanoFeaturesBffCache.clear()'));
    expect(invalidator, contains('MigracaoMagicaDraftCache.clear()'));
    expect(invalidator, contains('AlunoFollowUpStore.clearAll()'));
    expect(invalidator, contains('EvolucaoHomeClientCache.clear()'));
    expect(invalidator, contains('AgendaWeekClientCache.clear()'));
    expect(invalidator, contains('OnboardingWizardClientCache.clear()'));
    expect(invalidator, contains('BibliotecaWizardDraftCache.clear()'));
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
      matches(
        RegExp(
          r'ref\.onDispose\(\s*\(\) => SessionInvalidator\.listenable'
          r'\.removeListener\(\s*_handleSessionInvalidated,?\s*\)',
        ),
      ),
    );
    expect(provider, contains('state = AuthStatus.unauthenticated'));
    expect(provider, contains('_currentRole = null'));
  });
}
