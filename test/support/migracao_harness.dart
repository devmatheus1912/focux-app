import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/core/widgets/mesh_scope.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/growth/screens/migracao_magica_screen.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/planos/providers/plano_features_provider.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'riverpod_seeds.dart';

/// Servidor de mentira: devolve, por caminho, o que o backend real devolveria.
class ServidorMigracao implements HttpClientAdapter {
  ServidorMigracao({required this.texto, required this.preview, required this.confirmar});

  final Map<String, dynamic> texto;
  final Map<String, dynamic> preview;
  final Map<String, dynamic> confirmar;
  final chamadas = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    chamadas.add(options.path);
    final corpo = switch (options.path) {
      '/api/v1/migracao/texto' => {'resultadoEstruturado': texto},
      '/api/v1/migracao/preview' => preview,
      '/api/v1/migracao/confirmar' => confirmar,
      _ => <String, dynamic>{},
    };
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

class PlanosOfflineMigracao implements PlanosRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<Never>.error(StateError('offline'));
}

Map<String, dynamic> linhaMigracao(String nome, {String? email, String? telefone, String status = 'VALIDO'}) => {
  'nome': nome,
  'email': email,
  'telefone': telefone,
  'status': status,
};

Map<String, dynamic> detalheMigracao(
  String nome, {
  String? email,
  String? telefone,
  bool emailEnviado = false,
  bool emailReal = false,
  int id = 1,
}) => {
  'nome': nome,
  'status': 'IMPORTADO',
  'alunoId': id,
  'email': email,
  'telefone': telefone,
  'linkAtivacao': 'https://focuxpersonal.com/aluno/ativar/t$id',
  'emailEnviado': emailEnviado,
  'emailReal': emailReal,
};

Future<ServidorMigracao> abrirMigracao(
  WidgetTester tester, {
  required List<Map<String, dynamic>> alunos,
  int ignorados = 0,
  List<String> amostras = const [],
  required List<Map<String, dynamic>> detalhes,
  bool escuro = false,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  FlutterSecureStorage.setMockInitialValues({});
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(const Size(430, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final servidor = ServidorMigracao(
    texto: {
      'alunos': alunos,
      'ignorados': {'total': ignorados, 'amostras': amostras},
    },
    preview: {
      'alunos': [
        for (final a in alunos)
          {...a, 'duplicado': false, 'possivelDuplicado': false},
      ],
    },
    confirmar: {
      'importados': detalhes.length,
      'duplicados': 0,
      'erros': 0,
      'mensagem': 'ok',
      'detalhes': detalhes,
    },
  );
  final api = ApiClient()..dio.httpClientAdapter = servidor;
  const features = PlanoFeatures(
    plano: SubscriptionPlan.ENTERPRISE,
    financeiro: true,
    agenda: true,
    relatorios: true,
    whiteLabel: false,
    iaCopiloto: true,
    migracaoFoto: true,
  );
  final router = GoRouter(
    initialLocation: '/migracao',
    routes: [
      GoRoute(
        path: '/migracao',
        builder: (_, __) => const MeshScope(active: true, child: MigracaoMagicaScreen()),
      ),
      GoRoute(path: '/alunos', builder: (_, __) => const Scaffold(body: Text('lista'))),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        seededPlanoFeatures(features),
        planosRepositoryProvider.overrideWithValue(PlanosOfflineMigracao()),
      ],
      child: RepaintBoundary(
        key: const ValueKey('tela'),
        child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: escuro ? Brightness.dark : Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: EagleTokens.brandAccent,
            brightness: escuro ? Brightness.dark : Brightness.light,
          ),
          useMaterial3: true,
        ),
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        routerConfig: router,
        ),
      ),
    ),
  );
  await assentarMigracao(tester);
  return servidor;
}

Future<void> assentarMigracao(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

/// Cola o texto e chega na revisão (etapa 2).
Future<void> ateRevisaoMigracao(WidgetTester tester) async {
  await tester.tap(find.text('Colar texto').first);
  await assentarMigracao(tester);
  await tester.enterText(find.byType(TextField).first, 'Ana Souza ana@x.com');
  await tester.pump();
  await tester.tap(find.widgetWithText(FxLiquidPrimaryButton, 'Analisar texto').first);
  await assentarMigracao(tester);
  // folha de confirmação
  await tester.tap(find.text('Analisar texto').last);
  await assentarMigracao(tester);
  // O aviso "N aluno(s) identificado(s)" some sozinho: espera passar.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

/// Confirma a importação e chega no resultado (etapa 3).
Future<void> ateResultadoMigracao(WidgetTester tester, String rotulo) async {
  await tester.tap(find.text(rotulo).first);
  await assentarMigracao(tester);
  await tester.tap(find.text(rotulo).last);
  await assentarMigracao(tester);
  // Avisos de sucesso e a atualização do plano têm timer: deixa terminar.
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

