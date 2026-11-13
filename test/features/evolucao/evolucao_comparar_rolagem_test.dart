import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/providers/evolucao_home_provider.dart';
import 'package:focux_app/features/evolucao/screens/evolucao_screen.dart';
import 'package:focux_app/features/evolucao/widgets/evolucao_hero.dart';
import 'package:focux_app/features/evolucao/utils/evolucao_display.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bug de 10/11/2026: no Comparar, a tela não arrastava. Desde 13/11 o topo
/// do personal é sempre a faixa recolhida.
class _Adapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object? body = <String, Object?>{};
    if (options.path.endsWith('/avaliacoes/comparativo')) {
      Map<String, Object?> snap(double peso, String em) => {
        'pesoKg': peso,
        'circCintura': 90,
        'circQuadril': 100,
        'circBraco': 35,
        'avaliadoEm': em,
      };
      body = {
        'primeira': snap(90, '2026-09-01'),
        'atual': snap(84, '2026-11-01'),
      };
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeApiClient implements ApiClient {
  _FakeApiClient(this.dio);

  @override
  final Dio dio;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  for (final altura in [520.0, 560.0, 600.0, 640.0, 680.0, 720.0, 844.0]) {
    testWidgets('Comparar rola e recolhe o topo $altura', (tester) async {
      tester.view.physicalSize = Size(390, altura);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(
              _FakeApiClient(Dio()..httpClientAdapter = _Adapter()),
            ),
            evolucaoHomeProvider(7).overrideWith(
              (ref) async =>
                  const EvolucaoHomeBundle(medidas: [], recordes: []),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('pt'),
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: const EvolucaoScreen(
              alunoId: 7,
              alunoNome: 'Julio Cesar',
              abaInicial: EvolucaoHubView.comparativo,
            ),
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final lista = find.descendant(
        of: find.byType(EvolucaoScreen),
        matching: find.byType(Scrollable),
      );
      expect(lista, findsWidgets);

      // Coube tudo na tela: não há o que rolar nem recolher.
      final rolaveis = tester.stateList<ScrollableState>(lista);
      if (rolaveis.every((s) => s.position.maxScrollExtent <= 0)) return;

      // Arrasta o conteúdo do Comparar para cima.
      final alvo = find.textContaining('Peso').first;
      await tester.drag(alvo, const Offset(0, -300));
      await tester.pumpAndSettle();

      // 13/11: no personal o topo é sempre a faixa de 3 colunas; a tela
      // rola e a faixa não reabre ao puxar para baixo.
      var hero = tester.widget<EvolucaoHero>(find.byType(EvolucaoHero));
      expect(hero.recolhido, isTrue);
      expect(
        tester.stateList<ScrollableState>(lista).any((s) => s.position.pixels > 0),
        isTrue,
        reason: 'a tela não arrastou',
      );

      final meio = tester.getCenter(find.byType(EvolucaoScreen));
      await tester.dragFrom(meio, const Offset(0, 300));
      await tester.pumpAndSettle();
      hero = tester.widget<EvolucaoHero>(find.byType(EvolucaoHero));
      expect(hero.recolhido, isTrue);
    });
  }
}
