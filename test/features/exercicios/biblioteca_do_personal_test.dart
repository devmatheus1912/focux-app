import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/theme/fx_icons.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/exercicios/screens/exercicios_list_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

/// Responde `/api/exercicios/v2` conforme a aba pedida (MEUS / FOCUX /
/// favoritos) e o detalhe `/api/exercicios/{id}` com [fichas].
class _Adapter implements HttpClientAdapter {
  _Adapter({required this.meus, required this.focux, this.fichas = 0});

  final List<Map<String, Object?>> meus;
  final List<Map<String, Object?>> focux;
  final int fichas;
  final List<String> abas = [];
  final List<String> chamadas = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    chamadas.add('${options.method} ${options.path}');
    if (options.method == 'DELETE') {
      return ResponseBody.fromString('', 204);
    }
    Object corpo;
    final detalhe = RegExp(r'^/api/exercicios/(\d+)$').firstMatch(options.path);
    if (detalhe != null) {
      final id = int.parse(detalhe.group(1)!);
      corpo = {
        ...[...meus, ...focux].firstWhere((e) => e['id'] == id),
        'usadoEmFichas': fichas,
      };
    } else {
      final aba = options.queryParameters['aba'] as String?;
      final size = options.queryParameters['size'];
      final favoritos = '${options.queryParameters['favoritos']}' == 'true';
      // A contagem do topo pede uma linha só: não entra na lista de abas.
      if ('$size' != '1' && options.path == '/api/exercicios/v2') {
        abas.add(favoritos ? 'FAVORITOS' : aba ?? '');
      }
      final lista =
          favoritos
              ? [
                ...meus,
                ...focux,
              ].where((e) => e['favoritado'] == true).toList()
              : aba == 'MEUS'
              ? meus
              : focux;
      corpo = {
        'content': lista,
        'page': 0,
        'size': 40,
        'totalElements': lista.length,
        'totalPages': 1,
        'hasNext': false,
      };
    }
    return ResponseBody.fromString(
      jsonEncode(corpo),
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

Map<String, Object?> _meu(
  int id,
  String nome, {
  String? video,
  bool favoritado = false,
}) => {
  'id': id,
  'nome': nome,
  'favoritado': favoritado,
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

Future<void> _assentar(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<_Adapter> _abrir(
  WidgetTester tester, {
  required List<Map<String, Object?>> meus,
  List<Map<String, Object?>>? focux,
  bool embedded = false,
  int fichas = 0,
  ValueChanged<String?>? onResumo,
}) async {
  tester.view.physicalSize = const Size(1170, 2600);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final adapter = _Adapter(
    meus: meus,
    focux: focux ?? [_focux(9, 'Supino reto')],
    fichas: fichas,
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
        home: Scaffold(
          body: ExerciciosListScreen(
            embedded: embedded,
            onResumoTopo: onResumo,
          ),
        ),
      ),
    ),
  );
  await _assentar(tester);
  return adapter;
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('abre em "Meus" com a escolha Meus · Biblioteca · Favoritos', (
    tester,
  ) async {
    final adapter = await _abrir(
      tester,
      meus: [
        _meu(1, 'Crucifixo inverso (meu)', video: 'https://cdn.test/meu.mp4'),
        _meu(2, 'Elevação lateral (meu)', favoritado: true),
      ],
    );
    expect(adapter.abas.first, 'MEUS');
    expect(find.text('Meus'), findsOneWidget);
    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.text('Favoritos'), findsOneWidget);
    expect(find.text('Filtros'), findsNothing);
    // Mesma linha da biblioteca: "Seu" pequeno no texto, sem chip de vídeo.
    expect(find.textContaining('Seu · '), findsNWidgets(2));
    expect(find.text('Seu vídeo'), findsNothing);
    expect(find.byIcon(FxIcons.estrelaAtiva), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
  });

  testWidgets('Meus vazio: "Crie exercícios com o seu vídeo" e uma ação só', (
    tester,
  ) async {
    final adapter = await _abrir(tester, meus: const []);
    expect(adapter.abas, ['MEUS']);
    expect(find.text('Crie exercícios com o seu vídeo'), findsOneWidget);
    expect(find.text('Novo exercício'), findsOneWidget);
  });

  testWidgets('Biblioteca e Favoritos pedem a lista certa ao servidor', (
    tester,
  ) async {
    final adapter = await _abrir(
      tester,
      meus: [_meu(1, 'Meu exercício', favoritado: true)],
    );
    await tester.tap(find.text('Biblioteca'));
    await _assentar(tester);
    expect(adapter.abas.last, 'FOCUX');
    expect(find.text('Supino reto'), findsOneWidget);
    await tester.tap(find.text('Favoritos'));
    await _assentar(tester);
    expect(adapter.abas.last, 'FAVORITOS');
    expect(find.text('Meu exercício'), findsOneWidget);
  });

  testWidgets('embutido em Treinos: o topo conta exercícios, não modelos', (
    tester,
  ) async {
    String? resumo;
    await _abrir(
      tester,
      meus: [_meu(1, 'Meu exercício'), _meu(2, 'Outro meu')],
      embedded: true,
      onResumo: (r) => resumo = r,
    );
    expect(resumo, '2 seus · 1 da biblioteca');
    expect(find.text('Meus'), findsOneWidget);
  });

  testWidgets(
    '"⋯" abre a folha do kit; Excluir usado em ficha avisa a contagem',
    (tester) async {
      final adapter = await _abrir(
        tester,
        meus: [_meu(1, 'Meu exercício')],
        fichas: 2,
      );
      await tester.tap(find.byTooltip('Ações de Meu exercício'));
      await _assentar(tester);
      expect(find.text('Enviar vídeo'), findsOneWidget);
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Duplicar'), findsOneWidget);
      await tester.tap(find.text('Excluir'));
      await _assentar(tester);
      expect(find.text('Este exercício está em uso'), findsOneWidget);
      expect(
        find.text('Está em 2 fichas. Tire das fichas antes de excluir.'),
        findsOneWidget,
      );
      expect(adapter.chamadas.where((c) => c.startsWith('DELETE')), isEmpty);
    },
  );

  testWidgets('Excluir sem ficha confirma dizendo o efeito e exclui', (
    tester,
  ) async {
    final adapter = await _abrir(tester, meus: [_meu(1, 'Meu exercício')]);
    await tester.tap(find.byTooltip('Ações de Meu exercício'));
    await _assentar(tester);
    await tester.tap(find.text('Excluir'));
    await _assentar(tester);
    expect(
      find.text('Sai da sua lista. Nenhuma ficha usa este exercício.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Excluir').last);
    await _assentar(tester);
    expect(adapter.chamadas, contains('DELETE /api/exercicios/1'));
  });

  test('a aba Treinos tem o seletor com Exercícios', () {
    final fonte =
        File(
          'lib/features/treinos/screens/modelos_de_treino_view.dart',
        ).readAsStringSync();
    expect(fonte, contains('modelosAbaExercicios'));
    expect(fonte, contains('ExerciciosAbaTreinos('));
  });
}
