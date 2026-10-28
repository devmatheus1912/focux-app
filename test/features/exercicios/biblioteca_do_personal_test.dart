import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/exercicios/screens/exercicios_list_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

/// Responde `/api/exercicios/v2` conforme a aba pedida (MEUS / FOCUX).
class _Adapter implements HttpClientAdapter {
  _Adapter({required this.meus, required this.focux});

  final List<Map<String, Object?>> meus;
  final List<Map<String, Object?>> focux;
  final List<String> abas = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final aba = options.queryParameters['aba'] as String? ?? '';
    abas.add(aba);
    final lista = aba == 'MEUS' ? meus : focux;
    return ResponseBody.fromString(
      jsonEncode({
        'content': lista,
        'page': 0,
        'size': 40,
        'totalElements': lista.length,
        'totalPages': 1,
        'hasNext': false,
      }),
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

Map<String, Object?> _meu(int id, String nome, {String? video}) => {
  'id': id,
  'nome': nome,
  'grupoMuscularPrimario': 'OMBRO_LATERAL',
  'videoSource': video == null ? null : 'PERSONAL_UPLOAD',
  'licenseStatus': video == null ? null : 'PERSONAL_OWNED',
  'videoUrl': video,
};

Map<String, Object?> _focux(int id, String nome) => {
  'id': id,
  'nome': nome,
  'curado': true,
  'videoSource': 'FOCUX_LIBRARY',
  'videoUrl': 'https://cdn.test/$id.mp4',
  'grupoMuscularPrimario': 'PEITO',
};

Future<_Adapter> _abrir(
  WidgetTester tester, {
  required List<Map<String, Object?>> meus,
  List<Map<String, Object?>>? focux,
  bool embedded = false,
}) async {
  tester.view.physicalSize = const Size(1170, 2600);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final adapter = _Adapter(
    meus: meus,
    focux: focux ?? [_focux(9, 'Supino reto')],
  );
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(_FakeApiClient(dio))],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
          useMaterial3: true,
        ),
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: Scaffold(body: ExerciciosListScreen(embedded: embedded)),
      ),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return adapter;
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('abre em "Meus" e mostra o estado do vídeo de cada um', (
    tester,
  ) async {
    final adapter = await _abrir(
      tester,
      meus: [
        _meu(1, 'Crucifixo inverso (meu)', video: 'https://cdn.test/meu.mp4'),
        _meu(2, 'Elevação lateral (meu)'),
      ],
    );
    expect(adapter.abas.first, 'MEUS');
    expect(find.text('Meus'), findsOneWidget);
    expect(find.text('Focux'), findsOneWidget);
    expect(find.text('Seu vídeo'), findsOneWidget);
    expect(find.text('Sem vídeo'), findsOneWidget);
    // a ação rápida só aparece em quem está sem vídeo
    expect(find.text('Adicionar vídeo'), findsOneWidget);
  });

  testWidgets('sem nenhum exercício seu, abre a Focux uma vez só', (
    tester,
  ) async {
    final adapter = await _abrir(tester, meus: const []);
    expect(adapter.abas, ['MEUS', 'FOCUX']);
    expect(find.text('Supino reto'), findsOneWidget);
    expect(find.text('Vídeo da Focux'), findsOneWidget);
    // exercício da Focux nunca oferece "Adicionar vídeo"
    expect(find.text('Adicionar vídeo'), findsNothing);
  });

  testWidgets('Meus vazio na tela cheia tem uma única ação de criar', (
    tester,
  ) async {
    await _abrir(tester, meus: const []);
    await tester.tap(find.text('Meus'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Criar exercício'), findsOneWidget);
    expect(find.text('Novo exercício'), findsNothing);
  });

  testWidgets('trocar para Focux e voltar não refaz a escolha automática', (
    tester,
  ) async {
    final adapter = await _abrir(tester, meus: [_meu(1, 'Meu exercício')]);
    await tester.tap(find.text('Focux'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(adapter.abas.last, 'FOCUX');
    expect(find.text('Supino reto'), findsOneWidget);
    await tester.tap(find.text('Meus'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(adapter.abas.last, 'MEUS');
  });

  testWidgets('dentro de Treinos só mostra os do personal, sem Focux', (
    tester,
  ) async {
    final adapter = await _abrir(
      tester,
      meus: [_meu(1, 'Meu exercício')],
      embedded: true,
    );
    expect(adapter.abas, ['MEUS']);
    expect(find.text('Meu exercício'), findsOneWidget);
    expect(find.text('Meus'), findsNothing);
    expect(find.text('Biblioteca Focux'), findsNothing);
  });

  testWidgets(
    'dentro de Treinos, sem exercício seu, não abre a Focux sozinho',
    (tester) async {
      final adapter = await _abrir(tester, meus: const [], embedded: true);
      expect(adapter.abas, ['MEUS']);
      expect(find.text('Carregar biblioteca'), findsNothing);
      expect(find.text('Novo exercício'), findsOneWidget);
    },
  );

  test('a aba Treinos tem o seletor com Exercícios, só fora do aluno', () {
    final fonte =
        File(
          'lib/features/treinos/screens/treinos_list_screen_state.part.dart',
        ).readAsStringSync();
    expect(fonte, contains('modelosAbaExercicios'));
    expect(fonte, contains('widget.alunoId == null'));
    expect(fonte, contains('ExerciciosListScreen(embedded: true)'));
  });
}
