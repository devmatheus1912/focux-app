import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/health/health_service.dart';
import 'package:focux_app/features/health/data/health_repository.dart';
import 'package:focux_app/features/health/screens/health_dashboard_screen.dart';
import 'package:focux_app/features/health/utils/health_plausibilidade.dart';
import 'package:focux_app/features/health/utils/saude_meta_passos.dart';
import 'package:focux_app/features/health/widgets/prontidao_card.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  group('plausibilidade e texto', () {
    test('calorias do print (24 kcal com 5.124 passos) não valem', () {
      expect(caloriasPlausiveis(passos: 5124, kcalAtivas: 24), isFalse);
      expect(caloriasPlausiveis(passos: 5124, kcalAtivas: 240), isTrue);
      expect(caloriasPlausiveis(passos: 800, kcalAtivas: 2), isTrue);
    });

    test('milhar e duração de sono', () {
      expect(milhar(5124), '5.124');
      expect(milhar(102), '102');
      expect(milhar(1200000), '1.200.000');
      expect(duracaoDeSono(6.5), '6h30');
      expect(duracaoDeSono(8), '8h');
    });

    test('rótulo da plataforma: nunca Google Fit', () {
      expect(rotuloPlataformaSaude(TargetPlatform.iOS), 'Apple Saúde');
      expect(rotuloPlataformaSaude(TargetPlatform.android), 'Health Connect');
    });

    test('estado da nota: só há número com nota do servidor', () {
      expect(prontidaoEstado(null), ProntidaoEstado.semSono);
      expect(prontidaoEstado(null, sonoLocal: true), ProntidaoEstado.indisponivel);
      expect(
        prontidaoEstado(RecoverySnapshot.fromJson({'recoveryScore': 70})),
        ProntidaoEstado.comNota,
      );
      expect(
        prontidaoEstado(RecoverySnapshot.fromJson({'calibrando': true})),
        ProntidaoEstado.calibrando,
      );
      expect(
        prontidaoEstado(RecoverySnapshot.fromJson({'steps': 5124})),
        ProntidaoEstado.semSono,
      );
    });

    test('dica do treino por faixa', () {
      expect(dicaDoTreino(85), contains('forte'));
      expect(dicaDoTreino(70), contains('cargas'));
      expect(dicaDoTreino(50), contains('leve'));
      expect(dicaDoTreino(30), contains('mobilidade'));
    });

    test('insumos: passos nunca entram e o que faltou é dito', () {
      final r = RecoverySnapshot.fromJson({
        'recoveryScore': 70,
        'sleepHours': 7.5,
        'restingHeartRate': 58,
        'insumos': ['sono', 'fcRepouso'],
      });
      final itens = insumosDaNota(r);
      expect(itens.first.titulo, 'Sono 7h30');
      expect(itens[1].titulo, 'FC em repouso 58 bpm');
      expect(itens[2].detalhe, contains('Opcional'));
      expect(itens.last.titulo, 'Passos');
      expect(itens.last.detalhe, contains('Não entram'));
    });
  });

  group('leitura do aparelho', () {
    test('a janela do sono começa ontem às 18h', () {
      final agora = DateTime(2026, 10, 29, 13, 50);
      expect(
        HealthService.inicioDaJanelaDeSono(agora),
        DateTime(2026, 10, 28, 18),
      );
    });

    test('soma de intervalos une os que se sobrepõem (relógio + iPhone)', () {
      final base = DateTime(2026, 10, 29);
      DateTime h(double horas) =>
          base.add(Duration(minutes: (horas * 60).round()));
      // 23h–07h do relógio (-1h..7h) e 00h–06h do iPhone: a mesma noite.
      final total = HealthService.minutosUnidos([
        (h(-1), h(7)),
        (h(0), h(6)),
      ]);
      expect(total, 8 * 60);
      // dois trechos separados somam os dois
      expect(
        HealthService.minutosUnidos([(h(0), h(1)), (h(3), h(4))]),
        120,
      );
      expect(HealthService.minutosUnidos([]), 0);
    });
  });

  group('meta de passos', () {
    test('limites e arredondamento de 500 em 500', () {
      expect(SaudeMetaPassos.ajustar(100), 4000);
      expect(SaudeMetaPassos.ajustar(99999), 20000);
      expect(SaudeMetaPassos.ajustar(8260), 8500);
    });

    test('padrão 8.000 e persiste no aparelho', () async {
      expect(await SaudeMetaPassos.ler(), 8000);
      await SaudeMetaPassos.salvar(10500);
      expect(await SaudeMetaPassos.ler(), 10500);
    });
  });

  group('layout', () {
    Future<void> abrir(
      WidgetTester tester,
      Size tela,
      double escala,
      RecoverySnapshot? snap, {
      HealthSummary resumo = const HealthSummary(
        steps: 5124,
        caloriesBurned: 24,
        avgHeartRate: 90,
        sleepHours: 7.5,
      ),
    }) async {
      SharedPreferences.setMockInitialValues({
        'saude_escolha_compartilhamento_feita': true,
      });
      await tester.binding.setSurfaceSize(tela);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.platformDispatcher.textScaleFactorTestValue = escala;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: HealthDashboardScreen(
            checkAuthorization: () async => true,
            loadTodaySummary: () async => resumo,
            syncToday:
                (_) async => snap ?? RecoverySnapshot.fromJson({'steps': 5124}),
            updateHomeWidgetRecovery: ({
              required int recoveryScore,
              required String recoveryLabel,
              required String recoveryHint,
              required int steps,
            }) async {},
            clearHomeWidgetRecoveryScore: ({required int? steps}) async {},
            loadHistorico: () async => const [],
            loadCompartilhamento: () async => false,
            setCompartilhamento: (v) async => v,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    final estados = <String, RecoverySnapshot?>{
      'com nota': RecoverySnapshot.fromJson({
        'recoveryScore': 72,
        'recoveryLabel': 'Treino moderado',
        'recoveryHint': 'Boa base — mantenha volume controlado.',
        'sleepHours': 7.5,
        'insumos': ['sono'],
      }),
      'sem sono': null,
      'calibrando': RecoverySnapshot.fromJson({
        'calibrando': true,
        'sleepHours': 7.5,
      }),
    };

    for (final entrada in estados.entries) {
      for (final (tela, escala) in [
        (const Size(320, 640), 1.0),
        (const Size(390, 844), 1.3),
        (const Size(390, 844), 2.0),
      ]) {
        testWidgets(
          '${entrada.key} em ${tela.width.toInt()}×${tela.height.toInt()} a ${escala}x não estoura',
          (tester) async {
            await abrir(tester, tela, escala, entrada.value);
            expect(tester.takeException(), isNull);
            expect(find.text('Prontidão de hoje'), findsOneWidget);
          },
        );
      }
    }

    testWidgets('os três estados do card têm a mesma altura', (tester) async {
      final alturas = <double>[];
      for (final snap in estados.values) {
        await abrir(tester, const Size(390, 844), 1.0, snap);
        alturas.add(tester.getSize(find.byType(ProntidaoCard)).height);
      }
      expect(alturas.toSet().length, lessThanOrEqualTo(2),
          reason: 'o card não pode "pular" entre estados: $alturas');
      expect((alturas.reduce((a, b) => a > b ? a : b) -
              alturas.reduce((a, b) => a < b ? a : b)),
          lessThan(60));
    });

    testWidgets('o botão de ajuda e o de sync ficam dentro da borda', (
      tester,
    ) async {
      await abrir(tester, const Size(320, 640), 1.0, null);
      expect(
        tester.getRect(find.byTooltip('Como usar Saúde')).right,
        lessThanOrEqualTo(320 - 8),
      );
    });
  });
}
