import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/health/recovery_score.dart';
import 'package:focux_app/features/health/data/health_repository.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  const serverSnapshot = RecoverySnapshot(
    steps: 9000,
    caloriesBurned: 500,
    avgHeartRate: 60,
    sleepHours: 8,
    recoveryScore: 77,
    recoveryLabel: 'Pronto para treinar',
    recoveryHint: 'Do servidor.',
  );

  test('sync falhou sem snapshot anterior não publica nota local', () {
    final local = RecoveryScoreView.compute(
      steps: 12000,
      sleepHours: 8,
      avgHeartRate: 58,
    );
    expect(local.score, greaterThan(0));

    expect(
      recoveryAfterSyncAttempt(
        syncedFromServer: null,
        previousSnapshot: null,
      ),
      isNull,
    );
  });

  test('sync falhou com snapshot anterior mantém valor do servidor', () {
    expect(
      recoveryAfterSyncAttempt(
        syncedFromServer: null,
        previousSnapshot: serverSnapshot,
      ),
      serverSnapshot,
    );
  });

  test('sync ok substitui pelo snapshot do servidor', () {
    const fresh = RecoverySnapshot(
      steps: 10000,
      caloriesBurned: 520,
      avgHeartRate: 59,
      sleepHours: 7.8,
      recoveryScore: 82,
      recoveryLabel: 'Recuperado',
      recoveryHint: 'Novo sync.',
    );
    expect(
      recoveryAfterSyncAttempt(
        syncedFromServer: fresh,
        previousSnapshot: serverSnapshot,
      ),
      fresh,
    );
  });

  test('dashboard não calcula prontidão local nem atualiza widget no catch', () {
    final screen = readScreenSourceBundle(
      'lib/features/health/screens/health_dashboard_screen.dart',
    );
    final repo = readScreenSourceBundle(
      'lib/features/health/data/health_repository.dart',
    );
    expect(screen, isNot(contains('fromSummary')));
    expect(repo, isNot(contains('fromSummary')));
    expect(screen, contains('recoveryAfterSyncAttempt'));
    expect(screen, contains("'--'"));
  });
}
