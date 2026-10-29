import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/auth/screens/register_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _app({String? indicacao}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => RegisterScreen(referralCodigo: indicacao),
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

Future<void> _abrir(WidgetTester tester, {String? indicacao}) async {
  tester.view.physicalSize = const Size(1200, 3200);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(indicacao: indicacao));
  await tester.pump(const Duration(milliseconds: 800));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('o campo do código só aparece depois de enviar o código', (
    tester,
  ) async {
    await _abrir(tester);
    expect(find.text('Enviar código'), findsOneWidget);
    expect(find.text('Código do e-mail'), findsNothing);
    expect(
      find.text('Toque em Enviar para receber o código no e-mail.'),
      findsNothing,
    );
  });

  testWidgets('WhatsApp e indicação ficam recolhidos até pedir', (tester) async {
    await _abrir(tester);
    expect(find.text('Adicionar WhatsApp (opcional)'), findsOneWidget);
    expect(find.text('Tenho um código de indicação'), findsOneWidget);
    expect(find.text('Telefone / WhatsApp (opcional)'), findsNothing);

    await tester.ensureVisible(find.text('Adicionar WhatsApp (opcional)'));
    await tester.tap(find.text('Adicionar WhatsApp (opcional)'));
    await tester.pump();
    expect(find.text('Telefone / WhatsApp (opcional)'), findsOneWidget);
    expect(find.text('Adicionar WhatsApp (opcional)'), findsNothing);
  });

  testWidgets('indicação que veio no link já aparece preenchida', (
    tester,
  ) async {
    await _abrir(tester, indicacao: 'AMIGO-123');
    expect(find.text('Tenho um código de indicação'), findsNothing);
    expect(find.text('AMIGO-123'), findsOneWidget);
  });

  testWidgets('a senha mostra o requisito como dica fixa', (tester) async {
    await _abrir(tester);
    expect(find.text('Mínimo de 8 caracteres.'), findsOneWidget);
  });

  testWidgets('o texto legal completo está na criação da conta', (tester) async {
    await _abrir(tester);
    expect(
      find.textContaining('Conteúdo ofensivo ou abusivo não é tolerado',
          findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('o botão principal fica fixo no rodapé e não rola com o formulário', (
    tester,
  ) async {
    await _abrir(tester);
    final botao = find.text('Criar minha conta');
    expect(botao, findsOneWidget);
    final antes = tester.getTopLeft(botao).dy;
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
    await tester.pump();
    expect(tester.getTopLeft(botao).dy, antes, reason: 'não acompanha a rolagem');
    // e está fora da área rolável
    expect(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: botao,
      ),
      findsNothing,
    );
  });

  testWidgets('com o teclado aberto, o botão continua visível acima dele', (
    tester,
  ) async {
    await _abrir(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump(const Duration(milliseconds: 300));
    final botao = tester.getRect(find.text('Criar minha conta'));
    expect(botao.bottom, lessThanOrEqualTo((3200 - 800) / 2));
  });
}
