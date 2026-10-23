import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/alunos_provider.dart';
import 'package:focux_app/features/alunos/screens/editar_aluno_screen.dart';
import 'package:focux_app/features/alunos/utils/editar_aluno_display.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class _Captura extends Interceptor {
  Map<String, dynamic>? putBody;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() == 'PUT') {
      putBody = Map<String, dynamic>.from(options.data as Map);
    }
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'id': 7,
          'nome': 'Ana Nova',
          'email': 'ana@x.com',
          'status': 'ATIVO',
        },
      ),
    );
  }
}

Widget _app(Widget home) {
  return MaterialApp(
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    locale: const Locale('pt'),
    home: home,
  );
}

Aluno _ana() => Aluno(
  id: 7,
  nome: 'Ana',
  email: 'ana@x.com',
  status: 'ATIVO',
  telefone: '11999990000',
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('o e-mail aparece e não aceita digitação', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: _app(EditarAlunoScreen(aluno: _ana()))),
    );
    await tester.pump();

    expect(find.text('ana@x.com'), findsOneWidget);
    expect(find.text(editarAlunoEmailFrase()), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is EditableText && w.controller.text == 'ana@x.com',
      ),
      findsNothing,
    );
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('reabrir mostra o e-mail que veio do servidor', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: _app(EditarAlunoScreen(aluno: _ana()))),
    );
    await tester.pump();
    expect(find.text('ana@x.com'), findsOneWidget);
    expect(find.text(editarAlunoEmailFrase()), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('salvar nome não manda email', (tester) async {
    final captura = _Captura();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
    dio.interceptors.add(captura);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alunoRepositoryProvider.overrideWithValue(AlunoRepository.dio(dio)),
        ],
        child: _app(EditarAlunoScreen(aluno: _ana())),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).first, 'Ana Nova');
    await tester.pump();
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(editarAlunoConfirmMessage()), findsOneWidget);

    await tester.tap(find.text('Salvar').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(captura.putBody, isNotNull);
    expect(captura.putBody!.containsKey('email'), isFalse);
    expect(captura.putBody!['nome'], 'Ana Nova');
    expect(captura.putBody!['telefone'], '11999990000');
  });
}
