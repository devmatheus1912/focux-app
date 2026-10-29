import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/auth/screens/esqueci_senha_screen.dart';
import 'package:focux_app/features/auth/utils/esqueci_senha_display.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _app(String local) {
  final router = GoRouter(
    initialLocation: local,
    routes: [
      GoRoute(
        path: '/esqueci-senha',
        builder: (_, _) => const EsqueciSenhaScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('LOGIN')),
      ),
    ],
  );
  return ProviderScope(
    child: MaterialApp.router(
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      routerConfig: router,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('aluno não fica num beco sem saída: passos e mensagem pronta', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    String? copiado;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiado = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(_app('/esqueci-senha?role=aluno'));
    await tester.pump(const Duration(milliseconds: 600));

    for (final passo in esqueciAlunoPassos()) {
      expect(find.text(passo), findsOneWidget);
    }
    expect(find.byType(TextField), findsNothing, reason: 'aluno não digita e-mail');

    await tester.tap(find.text(esqueciAlunoCopiarLabel()));
    await tester.pump();
    expect(copiado, esqueciAlunoMensagem());
  });

  testWidgets('o seletor de papel vem antes da explicação', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app('/esqueci-senha?role=aluno'));
    await tester.pump(const Duration(milliseconds: 600));
    final seletor = tester.getTopLeft(find.text('Personal')).dy;
    final explicacao =
        tester.getTopLeft(find.text(esqueciAlunoPedePersonalBody())).dy;
    expect(seletor, lessThan(explicacao));
  });

  testWidgets('personal continua com e-mail e código', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app('/esqueci-senha?role=personal'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('E-mail cadastrado'), findsOneWidget);
    expect(find.text(esqueciAlunoCopiarLabel()), findsNothing);
  });
}
