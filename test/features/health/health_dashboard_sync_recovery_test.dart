import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/health/health_service.dart';
import 'package:focux_app/features/health/data/health_repository.dart';
import 'package:focux_app/features/health/screens/health_dashboard_screen.dart';
import 'package:focux_app/features/health/utils/health_dashboard_display.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> abrir(
    WidgetTester tester, {
    HealthSummary resumo = _localSummary,
    Future<RecoverySnapshot> Function(HealthSummary)? sync,
    Future<void> Function({required int? steps})? limpar,
    Future<void> Function({
      required int recoveryScore,
      required String recoveryLabel,
      required String recoveryHint,
      required int steps,
    })?
    atualizar,
    bool compartilhando = false,
    Future<bool> Function(bool)? definir,
    List<RecoveryDia> historico = const [],
  }) async {
    SharedPreferences.setMockInitialValues({
      'saude_escolha_compartilhamento_feita': true,
    });
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDashboard(
      tester,
      screen: HealthDashboardScreen(
        checkAuthorization: () async => true,
        loadTodaySummary: () async => resumo,
        syncToday: sync ?? (_) async => _serverSnapshot,
        updateHomeWidgetRecovery:
            atualizar ??
            ({
              required int recoveryScore,
              required String recoveryLabel,
              required String recoveryHint,
              required int steps,
            }) async {},
        clearHomeWidgetRecoveryScore: limpar ?? ({required int? steps}) async {},
        loadHistorico: () async => historico,
        loadCompartilhamento: () async => compartilhando,
        setCompartilhamento: definir ?? (v) async => v,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('com nota: anel, rótulo, dica do treino e botões do card', (
    tester,
  ) async {
    var atualizacoes = 0;
    int? nota;
    await abrir(
      tester,
      atualizar: ({
        required int recoveryScore,
        required String recoveryLabel,
        required String recoveryHint,
        required int steps,
      }) async {
        atualizacoes++;
        nota = recoveryScore;
      },
    );
    expect(find.text('77'), findsOneWidget);
    expect(find.text('Pronto para treinar'), findsOneWidget);
    expect(find.textContaining('Do servidor.'), findsOneWidget);
    expect(find.text('Ver treino de hoje'), findsOneWidget);
    expect(find.text('Por quê?'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.text('12.000'), findsOneWidget);
    expect(find.text('8h'), findsOneWidget);
    expect(atualizacoes, 1);
    expect(nota, 77);
  });

  testWidgets('"Por quê?" mostra o que entrou na nota e que passos não entram', (
    tester,
  ) async {
    await abrir(tester);
    await tester.tap(find.text('Por quê?'));
    await tester.pumpAndSettle();
    expect(find.text('Como chegamos nessa nota'), findsOneWidget);
    expect(
      find.text('Não entram: medem atividade, não recuperação.'),
      findsOneWidget,
    );
  });

  testWidgets('sync falho com sono local: nota indisponível, não "sem sono"', (
    tester,
  ) async {
    var atualizacoes = 0;
    await abrir(
      tester,
      sync: (_) => throw Exception('sync falhou'),
      atualizar: ({
        required int recoveryScore,
        required String recoveryLabel,
        required String recoveryHint,
        required int steps,
      }) async {
        atualizacoes++;
      },
    );
    expect(find.text('Prontidão indisponível'), findsOneWidget);
    expect(find.text('Sem sono registrado'), findsNothing);
    expect(find.textContaining('/100'), findsNothing);
    expect(find.text('12.000'), findsOneWidget);
    expect(find.text('8h'), findsOneWidget);
    expect(find.text('Atualizar'), findsOneWidget); // na faixa compacta da prontidão
    expect(atualizacoes, 0);
  });

  testWidgets('servidor sem nota e sem sono: sem número e com "Como registrar"', (
    tester,
  ) async {
    var limpou = 0;
    int? passos;
    await abrir(
      tester,
      resumo: const HealthSummary(
        steps: 5124,
        caloriesBurned: 24,
        avgHeartRate: 90,
        sleepHours: 0,
      ),
      sync: (_) async => RecoverySnapshot.fromJson({'steps': 5124}),
      limpar: ({required int? steps}) async {
        limpou++;
        passos = steps;
      },
    );
    // O caso do print: 63 "Recuperação parcial" sem nenhum sono.
    expect(find.text('63'), findsNothing);
    expect(find.text('Recuperação parcial'), findsNothing);
    expect(find.text('Sem sono registrado'), findsOneWidget);
    expect(find.text('Como registrar'), findsOneWidget);
    expect(find.text('Registrar sono'), findsNothing);
    expect(find.text('Sem registro'), findsWidgets); // cartão de sono vazio, texto pequeno
    expect(find.text('5.124'), findsOneWidget);
    // calorias implausíveis (24 kcal com 5 mil passos) viram "--"
    expect(find.text('24'), findsNothing);
    expect(find.text('Precisa de um relógio'), findsOneWidget);
    expect(find.text('Inclui treino e caminhada'), findsOneWidget);
    expect(limpou, 1);
    expect(passos, 5124);
  });

  testWidgets('calibrando: sem número e com explicação', (tester) async {
    await abrir(
      tester,
      sync:
          (_) async => RecoverySnapshot.fromJson({
            'steps': 9000,
            'sleepHours': 8,
            'calibrando': true,
            'insumos': ['sono'],
          }),
    );
    expect(find.text('Calibrando sua nota'), findsOneWidget);
    expect(find.text('Ver treino de hoje'), findsNothing);
    expect(find.text('Por quê?'), findsOneWidget);
  });

  testWidgets('iOS: "Como registrar" ensina o caminho nos Ajustes', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await abrir(
      tester,
      resumo: const HealthSummary(
        steps: 4000,
        caloriesBurned: 0,
        avgHeartRate: 0,
        sleepHours: 0,
      ),
      sync: (_) async => RecoverySnapshot.fromJson({'steps': 4000}),
    );
    await tester.tap(find.text('Como registrar'));
    await tester.pumpAndSettle();
    expect(find.text(saudeLiberarIosSubtitulo), findsOneWidget);
    expect(find.text('Abra os Ajustes'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('interruptor de compartilhamento chama o servidor', (
    tester,
  ) async {
    final chamadas = <bool>[];
    await abrir(
      tester,
      compartilhando: false,
      definir: (v) async {
        chamadas.add(v);
        return v;
      },
    );
    expect(find.text('Só você vê seus dados de saúde.'), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(Switch), 200);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(chamadas, [true]);
    expect(
      find.text('Seu personal vê sua nota de prontidão e os dados do dia.'),
      findsOneWidget,
    );
  });

  testWidgets('quem já compartilhava recebe o aviso uma vez', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
        }) async {},
        loadHistorico: () async => const [],
        loadCompartilhamento: () async => true,
        setCompartilhamento: (v) async => v,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Seu personal já vê sua prontidão'), findsOneWidget);
    await tester.tap(find.text('Entendi'));
    await tester.pumpAndSettle();
    expect(find.text('Seu personal já vê sua prontidão'), findsNothing);
  });

  testWidgets('tendência: sem nota a seção some', (
    tester,
  ) async {
    await abrir(tester);
    expect(find.text('Últimos 7 dias'), findsNothing);
    expect(find.textContaining('Sua tendência'), findsNothing);
  });

  testWidgets('tendência: com 1 ou 2 dias de nota, uma linha sem cartão', (tester) async {
    final hoje = DateTime(2026, 10, 29);
    await abrir(
      tester,
      historico: [
        RecoveryDia(data: hoje, score: 62, rotulo: 'Treino moderado', sonoHoras: 7, fcRepouso: 58, passos: 8000),
      ],
    );
    expect(find.text('Últimos 7 dias'), findsNothing);
    expect(find.text('Sua tendência aparece com 3 dias de nota.'), findsOneWidget);
  });

  testWidgets('tendência: com 3 ou mais dias mostra as barras', (tester) async {
    final hoje = DateTime(2026, 10, 29);
    await abrir(
      tester,
      historico: [
        for (var i = 6; i >= 0; i--)
          RecoveryDia(
            data: hoje.subtract(Duration(days: i)),
            score: i < 4 ? 60 + i : null,
            rotulo: i < 4 ? 'Treino moderado' : null,
            sonoHoras: 7,
            fcRepouso: 58,
            passos: 8000,
          ),
      ],
    );
    expect(find.text('Últimos 7 dias'), findsOneWidget);
    expect(
      find.text('Sua tendência aparece depois de 3 dias com nota.'),
      findsNothing,
    );
  });

  testWidgets('meta de passos: abre a folha e salva', (tester) async {
    await abrir(tester);
    await tester.tap(find.textContaining('toque para ajustar'));
    await tester.pumpAndSettle();
    expect(find.text('Meta diária'), findsOneWidget);
    await tester.tap(find.text('Salvar meta'));
    await tester.pumpAndSettle();
    expect(find.text('Meta diária'), findsNothing);
  });

  test('zero do wearable vira --', () {
    expect(saudeValorOuTraco(0, (v) => '$v kcal'), '--');
    expect(saudeValorOuTraco(320, (v) => '$v kcal'), '320 kcal');
  });

  testWidgets(
    'sync sem rede não apaga a nota do widget da Home',
    (tester) async {
      var homeWidgetClears = 0;

      SharedPreferences.setMockInitialValues({});
      await _pumpDashboard(
        tester,
        screen: HealthDashboardScreen(
          loadHistorico: () async => const [],
          loadCompartilhamento: () async => false,
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
      expect(find.text('12.000'), findsOneWidget);
    },
  );
}
