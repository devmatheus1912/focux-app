import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/widgets/fx_shell_inset_owner.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/chat/screens/conversation_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class _Adapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body =
        options.path.endsWith('/historico/page')
            ? {'items': <Object>[], 'hasMore': false}
            : {'ok': true};
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

/// [comShell] imita o `AlunoShell`/`MainShell`: Scaffold externo com
/// `extendBody`, SafeArea e `removePadding` em volta da conversa.
Widget _app(Widget conversa, {required bool comShell}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = _Adapter();
  final home =
      comShell
          ? Scaffold(
            extendBody: true,
            backgroundColor: Colors.transparent,
            body: Stack(
              fit: StackFit.expand,
              children: [
                SafeArea(
                  bottom: false,
                  child: MediaQuery.removePadding(
                    context: _RaizContext.contexto,
                    removeBottom: false,
                    child: FxShellInsetOwner(child: conversa),
                  ),
                ),
              ],
            ),
          )
          : conversa;
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => home)],
  );
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(_FakeApiClient(dio))],
    child: MaterialApp.router(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
        useMaterial3: true,
      ),
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      routerConfig: router,
    ),
  );
}

/// `MediaQuery.removePadding` pede um contexto; no teste basta o do app.
class _RaizContext {
  static late BuildContext contexto;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  const telaAltura = 2400.0;
  const tecladoPx = 900.0; // teclado de 450 dp a 2x

  Future<void> abrir(
    WidgetTester tester,
    Widget conversa, {
    required bool comShell,
  }) async {
    tester.view.physicalSize = const Size(1200, telaAltura);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          _RaizContext.contexto = context;
          return _app(conversa, comShell: comShell);
        },
      ),
    );
    await _settle(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: tecladoPx);
    await _settle(tester);
  }

  void campoColadoNoTeclado(WidgetTester tester) {
    final campo = tester.getRect(find.byType(TextField));
    final topoDoTeclado = (telaAltura - tecladoPx) / 2; // em dp
    expect(
      campo.bottom,
      lessThanOrEqualTo(topoDoTeclado + 0.5),
      reason: 'o campo não pode ficar atrás do teclado',
    );
    expect(
      topoDoTeclado - campo.bottom,
      lessThan(40),
      reason: 'o campo tem que ficar colado no teclado, sem vazio',
    );
  }

  testWidgets('aluno: com o teclado aberto o campo fica colado nele', (
    tester,
  ) async {
    await abrir(tester, const ConversationScreen.aluno(), comShell: false);
    campoColadoNoTeclado(tester);
  });

  testWidgets('aluno dentro do shell: campo colado no teclado', (tester) async {
    await abrir(tester, const ConversationScreen.aluno(), comShell: true);
    campoColadoNoTeclado(tester);
  });

  testWidgets('personal: com o teclado aberto o campo fica colado nele', (
    tester,
  ) async {
    await abrir(
      tester,
      const ConversationScreen.personal(alunoId: 7, alunoNome: 'Hugo'),
      comShell: false,
    );
    campoColadoNoTeclado(tester);
  });

  testWidgets('personal dentro do shell: campo colado no teclado', (
    tester,
  ) async {
    await abrir(
      tester,
      const ConversationScreen.personal(alunoId: 7, alunoNome: 'Hugo'),
      comShell: true,
    );
    campoColadoNoTeclado(tester);
  });

  testWidgets('os dois shells usam o dono único do inset do teclado', (
    tester,
  ) async {
    for (final f in [
      'lib/core/screens/aluno_shell.dart',
      'lib/core/screens/main_shell.dart',
    ]) {
      expect(File(f).readAsStringSync(), contains('FxShellInsetOwner('), reason: f);
    }
  });
}
