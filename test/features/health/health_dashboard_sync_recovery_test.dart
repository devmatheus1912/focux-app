import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/health/health_service.dart';
import 'package:focux_app/features/health/data/health_repository.dart';
import 'package:focux_app/features/health/screens/health_dashboard_screen.dart';
import 'package:focux_app/features/health/utils/health_dashboard_display.dart';
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

  test('recoveryScore ausente ou nulo fica nulo, não zero', () {
    final semCampo = RecoverySnapshot.fromJson({
      'recoveryLabel': '',
      'recoveryHint': '',
    });
    final nulo = RecoverySnapshot.fromJson({'recoveryScore': null});
    final comNota = RecoverySnapshot.fromJson({
      'recoveryScore': 64,
      'dataReferencia': '2026-09-27',
    });
    expect(semCampo.recoveryScore, isNull);
    expect(nulo.recoveryScore, isNull);
    expect(comNota.recoveryScore, 64);
    expect(comNota.dataReferencia, DateTime(2026, 9, 27));
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
      expect(
        find.bySemanticsLabel(
          'Prontidão indisponível. Aguardando sincronização com o servidor.',
        ),
        findsOneWidget,
      );
      expect(find.text('--'), findsWidgets);
      expect(find.textContaining('%'), findsNothing);
      expect(find.text('12000'), findsOneWidget);
      expect(find.text('8,0h'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(saudeAtualizarLabel())),
        findsWidgets,
      );
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
      expect(
        find.bySemanticsLabel('Prontidão 77 de 100. Pronto para treinar'),
        findsOneWidget,
      );
      expect(find.text('77/100'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      expect(find.text('Pronto para treinar'), findsOneWidget);
      expect(find.text('12000'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(saudeAtualizarLabel())),
        findsWidgets,
      );
      expect(homeWidgetUpdates, 1);
      expect(syncedScore, 77);
    },
  );

  testWidgets(
    'servidor sem nota: prontidão indisponível e widget da Home limpo',
    (tester) async {
      var homeWidgetUpdates = 0;
      var homeWidgetClears = 0;
      int? clearedSteps;

      await _pumpDashboard(
        tester,
        screen: HealthDashboardScreen(
          checkAuthorization: () async => true,
          loadTodaySummary: () async => _localSummary,
          syncToday: (_) async => RecoverySnapshot.fromJson({'steps': 9000}),
          updateHomeWidgetRecovery: ({
            required int recoveryScore,
            required String recoveryLabel,
            required String recoveryHint,
            required int steps,
          }) async {
            homeWidgetUpdates++;
          },
          clearHomeWidgetRecoveryScore: ({required int? steps}) async {
            homeWidgetClears++;
            clearedSteps = steps;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RecoveryScoreRing), findsNothing);
      expect(
        find.bySemanticsLabel(
          'Prontidão indisponível. Aguardando sincronização com o servidor.',
        ),
        findsOneWidget,
      );
      expect(find.text('0'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(homeWidgetUpdates, 0);
      expect(homeWidgetClears, 1);
      expect(clearedSteps, 9000);
    },
  );

  testWidgets(
    'sync sem rede não apaga a nota do widget da Home',
    (tester) async {
      var homeWidgetClears = 0;

      await _pumpDashboard(
        tester,
        screen: HealthDashboardScreen(
          checkAuthorization: () async => true,
          loadTodaySummary: () async => _localSummary,
          syncToday: (_) => throw const SocketException('sem rede'),
          updateHomeWidgetRecovery: ({
            required int recoveryScore,
            required String recoveryLabel,
            required String recoveryHint,
            required int steps,
          }) async {},
          clearHomeWidgetRecoveryScore: ({required int? steps}) async {
            homeWidgetClears++;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(homeWidgetClears, 0);
      expect(find.text('12000'), findsOneWidget);
    },
  );
}
