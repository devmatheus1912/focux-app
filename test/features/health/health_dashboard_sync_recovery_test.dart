import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/health/health_service.dart';
import 'package:focux_app/features/health/data/health_repository.dart';
import 'package:focux_app/features/health/screens/health_dashboard_screen.dart';
import 'package:focux_app/features/health/widgets/recovery_score_ring.dart';
import 'package:focux_app/l10n/app_localizations.dart';

const _localSummary = HealthSummary(
  steps: 12000,
  caloriesBurned: 520,
  avgHeartRate: 58,
  sleepHours: 8,
);

const _serverSnapshot = RecoverySnapshot(
  steps: 9000,
  caloriesBurned: 500,
  avgHeartRate: 60,
  sleepHours: 8,
  recoveryScore: 77,
  recoveryLabel: 'Pronto para treinar',
  recoveryHint: 'Do servidor.',
);

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required HealthDashboardScreen screen,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      home: screen,
    ),
  );
}

void main() {
  test('sync falhou sem snapshot anterior não publica nota local', () {
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
        previousSnapshot: _serverSnapshot,
      ),
      _serverSnapshot,
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
        previousSnapshot: _serverSnapshot,
      ),
      fresh,
    );
  });

  testWidgets(
    'POST falho com resumo local não publica prontidão nem atualiza widget',
    (tester) async {
      var homeWidgetUpdates = 0;

      await _pumpDashboard(
        tester,
        screen: HealthDashboardScreen(
          checkAuthorization: () async => true,
          loadTodaySummary: () async => _localSummary,
          syncToday: (_) => throw Exception('sync falhou'),
          updateHomeWidgetRecovery: ({
            required int recoveryScore,
            required String recoveryLabel,
            required String recoveryHint,
            required int steps,
          }) async {
            homeWidgetUpdates++;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RecoveryScoreRing), findsNothing);
      expect(find.text('--'), findsWidgets);
      expect(find.textContaining('%'), findsNothing);
      expect(find.text('12000'), findsOneWidget);
      expect(find.text('8,0h'), findsOneWidget);
      expect(homeWidgetUpdates, 0);
    },
  );

  testWidgets(
    'POST ok publica score do servidor e atualiza widget da Home',
    (tester) async {
      var homeWidgetUpdates = 0;
      int? syncedScore;

      await _pumpDashboard(
        tester,
        screen: HealthDashboardScreen(
          checkAuthorization: () async => true,
          loadTodaySummary: () async => _localSummary,
          syncToday: (_) async => _serverSnapshot,
          updateHomeWidgetRecovery: ({
            required int recoveryScore,
            required String recoveryLabel,
            required String recoveryHint,
            required int steps,
          }) async {
            homeWidgetUpdates++;
            syncedScore = recoveryScore;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RecoveryScoreRing), findsOneWidget);
      expect(find.text('77%'), findsOneWidget);
      expect(find.text('Pronto para treinar'), findsOneWidget);
      expect(find.text('12000'), findsOneWidget);
      expect(homeWidgetUpdates, 1);
      expect(syncedScore, 77);
    },
  );
}
